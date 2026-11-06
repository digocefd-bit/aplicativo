import '../models/models.dart';
import 'storage_service.dart';
import 'reminder_sync_service.dart';

class ProtocolService {
  static Future<List<Protocol>> loadProtocols() async {
    return await StorageService.loadProtocols();
  }

  static Future<Protocol> addProtocol(Protocol protocol) async {
    final protocols = await StorageService.loadProtocols();
    protocols.add(protocol);
    await StorageService.saveProtocols(protocols);

    // Gerar aplicações futuras
    await _generateApplicationsForProtocol(protocol);
    await ReminderSyncService.syncAll();

    return protocol;
  }

  static Future<void> updateProtocol(Protocol protocol) async {
    final protocols = await StorageService.loadProtocols();
    final index = protocols.indexWhere((p) => p.id == protocol.id);
    if (index == -1) return;

    protocol.updatedAt = DateTime.now();
    protocols[index] = protocol;
    await StorageService.saveProtocols(protocols);

    // Regenerar aplicações futuras (apenas as agendadas, não as já aplicadas)
    await _regenerateApplicationsForProtocol(protocol);
    await ReminderSyncService.syncAll();
  }

  static Future<void> deleteProtocol(String protocolId) async {
    final protocols = await StorageService.loadProtocols();
    protocols.removeWhere((p) => p.id == protocolId);
    await StorageService.saveProtocols(protocols);

    // Remover aplicações futuras deste protocolo
    final apps = await StorageService.loadApplications();
    apps.removeWhere((a) => a.protocolId == protocolId && a.status == ApplicationStatus.scheduled);
    await StorageService.saveApplications(apps);

    await ReminderSyncService.syncAll();
  }

  static Future<void> toggleProtocolActive(String protocolId) async {
    final protocols = await StorageService.loadProtocols();
    final index = protocols.indexWhere((p) => p.id == protocolId);
    if (index == -1) return;

    final protocol = protocols[index];
    protocol.active = !protocol.active;
    protocol.updatedAt = DateTime.now();

    protocols[index] = protocol;
    await StorageService.saveProtocols(protocols);

    if (protocol.active) {
      await _generateApplicationsForProtocol(protocol);
    } else {
      await _removeScheduledApplications(protocolId);
    }

    await ReminderSyncService.syncAll();
  }

  static Future<List<DateTime>> generateOccurrences(Protocol protocol, {int daysAhead = 30}) async {
    final occurrences = <DateTime>[];
    final startDate = protocol.startDate.isAfter(DateTime.now())
        ? protocol.startDate
        : DateTime.now();
    final endDate = protocol.endDate ?? startDate.add(Duration(days: daysAhead));

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    switch (protocol.frequency) {
      case ScheduleFrequency.daily:
        for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
          occurrences.add(d);
        }
        break;

      case ScheduleFrequency.weekly:
        for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
          // weekDays usa 1=Segunda, 2=Terça, ..., 7=Domingo
          final weekday = d.weekday;
          if (protocol.weekDays.contains(weekday)) {
            occurrences.add(d);
          }
        }
        break;

      case ScheduleFrequency.intervalDays:
        var d = start;
        while (!d.isAfter(end)) {
          occurrences.add(d);
          d = d.add(Duration(days: protocol.intervalDays));
        }
        break;
    }

    return occurrences;
  }

  static Future<void> _generateApplicationsForProtocol(Protocol protocol) async {
    final occurrences = await generateOccurrences(protocol);
    final apps = await StorageService.loadApplications();
    final existingKeys = apps
        .where((a) => a.protocolId == protocol.id)
        .map((a) => a.occurrenceKey)
        .toSet();

    final newApps = <ApplicationRecord>[];

    for (final date in occurrences) {
      for (final time in protocol.times) {
        final scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

        if (!scheduledAt.isAfter(DateTime.now())) continue;

        final occurrenceKey = '${protocol.id}_${date.year}_${date.month}_${date.day}_${time.hour}_${time.minute}';

        if (existingKeys.contains(occurrenceKey)) continue;

        final now = DateTime.now();
        newApps.add(ApplicationRecord(
          id: 'app_${now.millisecondsSinceEpoch}_${newApps.length}',
          protocolId: protocol.id,
          occurrenceKey: occurrenceKey,
          scheduledAt: scheduledAt,
          doseValue: protocol.defaultDose,
          doseUnit: protocol.doseUnit,
          route: protocol.route,
          status: ApplicationStatus.scheduled,
          createdAt: now,
          updatedAt: now,
        ));
      }
    }

    if (newApps.isNotEmpty) {
      apps.addAll(newApps);
      await StorageService.saveApplications(apps);
    }
  }

  static Future<void> _regenerateApplicationsForProtocol(Protocol protocol) async {
    final apps = await StorageService.loadApplications();

    // Cancelar notificações das aplicações agendadas antigas
    final scheduledApps = apps.where((a) => a.protocolId == protocol.id && a.status == ApplicationStatus.scheduled).toList();
    for (final app in scheduledApps) {
      if (app.notificationId != null) {
        try {
          // Cancela via NotificationService
        } catch (_) {}
      }
    }

    // Remover aplicações agendadas antigas
    apps.removeWhere((a) => a.protocolId == protocol.id && a.status == ApplicationStatus.scheduled);
    await StorageService.saveApplications(apps);

    // Gerar novas
    await _generateApplicationsForProtocol(protocol);
  }

  static Future<void> _removeScheduledApplications(String protocolId) async {
    final apps = await StorageService.loadApplications();
    apps.removeWhere((a) => a.protocolId == protocolId && a.status == ApplicationStatus.scheduled);
    await StorageService.saveApplications(apps);
  }
}