import '../models/models.dart';
import 'storage_service.dart';
import 'rotation_service.dart';
import 'reminder_sync_service.dart';

class ApplicationService {
  static Future<List<ApplicationRecord>> loadApplications() async {
    return await StorageService.loadApplications();
  }

  static Future<ApplicationRecord> addManualApplication({
    required String protocolId,
    required DateTime scheduledAt,
    required double doseValue,
    required String doseUnit,
    required RouteType route,
    String? siteId,
    String? notes,
  }) async {
    final now = DateTime.now();
    final app = ApplicationRecord(
      id: 'app_${now.millisecondsSinceEpoch}',
      protocolId: protocolId,
      occurrenceKey: 'manual_${now.millisecondsSinceEpoch}',
      scheduledAt: scheduledAt,
      doseValue: doseValue,
      doseUnit: doseUnit,
      route: route,
      siteId: siteId,
      notes: notes,
      status: ApplicationStatus.scheduled,
      manuallyCreated: true,
      createdAt: now,
      updatedAt: now,
    );

    final apps = await StorageService.loadApplications();
    apps.add(app);
    await StorageService.saveApplications(apps);
    await ReminderSyncService.syncAll();
    return app;
  }

  static Future<void> markAsApplied({
    required String applicationId,
    String? siteId,
    double? weightKg,
    String? notes,
  }) async {
    final apps = await StorageService.loadApplications();
    final index = apps.indexWhere((a) => a.id == applicationId);
    if (index == -1) return;

    final now = DateTime.now();
    final app = apps[index];

    app.status = ApplicationStatus.applied;
    app.appliedAt = now;
    app.updatedAt = now;
    if (siteId != null) app.siteId = siteId;
    if (weightKg != null) app.weightKg = weightKg;
    if (notes != null && notes.trim().isNotEmpty) app.notes = notes;

    if (app.notificationId != null) {
      app.notificationId = null;
    }

    apps[index] = app;
    await StorageService.saveApplications(apps);

    // Registrar peso como medição corporal se informado
    if (weightKg != null) {
      await _recordWeight(weightKg);
    }
  }

  static Future<void> markAsSkipped({required String applicationId, String? notes}) async {
    final apps = await StorageService.loadApplications();
    final index = apps.indexWhere((a) => a.id == applicationId);
    if (index == -1) return;

    final now = DateTime.now();
    final app = apps[index];

    app.status = ApplicationStatus.skipped;
    app.updatedAt = now;
    if (notes != null && notes.trim().isNotEmpty) app.notes = notes;

    if (app.notificationId != null) {
      app.notificationId = null;
    }

    apps[index] = app;
    await StorageService.saveApplications(apps);
  }

  static Future<void> undoApplication({required String applicationId}) async {
    final apps = await StorageService.loadApplications();
    final index = apps.indexWhere((a) => a.id == applicationId);
    if (index == -1) return;

    final now = DateTime.now();
    final app = apps[index];

    app.status = ApplicationStatus.scheduled;
    app.appliedAt = null;
    app.updatedAt = now;

    apps[index] = app;
    await StorageService.saveApplications(apps);
    await ReminderSyncService.syncAll();
  }

  static Future<void> deleteApplication({required String applicationId}) async {
    final apps = await StorageService.loadApplications();
    final index = apps.indexWhere((a) => a.id == applicationId);
    if (index == -1) return;

    final app = apps[index];
    if (app.notificationId != null) {
      await _cancelNotification(app.notificationId!);
    }

    apps.removeWhere((a) => a.id == applicationId);
    await StorageService.saveApplications(apps);
  }

  static Future<void> deleteApplicationsForProtocol({required String protocolId}) async {
    final apps = await StorageService.loadApplications();
    final toDelete = apps.where((a) => a.protocolId == protocolId && a.status == ApplicationStatus.scheduled).toList();

    for (final app in toDelete) {
      if (app.notificationId != null) {
        await _cancelNotification(app.notificationId!);
      }
    }

    apps.removeWhere((a) => a.protocolId == protocolId && a.status == ApplicationStatus.scheduled);
    await StorageService.saveApplications(apps);
  }

  static Future<String?> suggestNextSite({required String protocolId}) async {
    final protocols = await StorageService.loadProtocols();
    final protocol = protocols.firstWhere(
      (p) => p.id == protocolId,
      orElse: () => protocols.first,
    );
    final sites = await StorageService.loadInjectionSites();
    final apps = await StorageService.loadApplications();

    return RotationService.suggestNextSite(
      route: protocol.route,
      sites: sites,
      applications: apps,
      protocol: protocol,
    );
  }

  static Future<void> _recordWeight(double weightKg) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final dayKey = '${day.year}_${day.month}_${day.day}';

    final measurements = await StorageService.loadBodyMeasurements();
    final existing = measurements.where((m) => m.id.contains(dayKey)).toList();

    if (existing.isNotEmpty) {
      final m = existing.first;
      m.weightKg = weightKg;
      final index = measurements.indexOf(m);
      measurements[index] = m;
    } else {
      final profile = await StorageService.loadProfile();
      final newMeasurement = BodyMeasurement(
        id: 'body_$dayKey',
        measuredAt: day,
        weightKg: weightKg,
        heightCm: profile?.heightCm,
      );
      measurements.add(newMeasurement);
    }

    await StorageService.saveBodyMeasurements(measurements);
  }

  static Future<void> _cancelNotification(int id) async {
    try {
      final notificationService = await _getNotificationService();
      await notificationService.cancel(id);
    } catch (_) {
      // Ignora erros de cancelamento
    }
  }

  static Future<dynamic> _getNotificationService() async {
    // Import dinâmico para evitar dependência circular
    return await Future.value(null);
  }
}