import '../models/models.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class ReminderSyncService {
  static Future<void> syncAll() async {
    await NotificationService.init();

    final protocols = await StorageService.loadProtocols();
    final applications = await StorageService.loadApplications();

    final activeProtocols = protocols.where((p) => p.active).toList();
    final activeProtocolIds = activeProtocols.map((p) => p.id).toSet();

    // 1. Cancelar lembretes órfãos (aplicações removidas ou de protocolos desativados)
    for (final app in applications) {
      if (app.notificationId == null) continue;

      final shouldCancel = _shouldCancelReminder(app, activeProtocolIds);
      if (shouldCancel) {
        await NotificationService.cancel(app.notificationId!);
        app.notificationId = null;
      }
    }

    // 2. Agendar lembretes para aplicações futuras sem notificação
    for (final app in applications) {
      if (app.notificationId != null) continue;
      if (app.status != ApplicationStatus.scheduled) continue;
      if (!app.scheduledAt.isAfter(DateTime.now())) continue;
      if (!activeProtocolIds.contains(app.protocolId)) continue;

      final protocol = activeProtocols.firstWhere(
        (p) => p.id == app.protocolId,
        orElse: () => activeProtocols.first,
      );

      final offset = protocol.defaultReminderOffsetMinutes;
      final notifId = _generateNotificationId(app);

      await NotificationService.scheduleReminder(
        id: notifId,
        title: 'Hora de aplicar',
        body: '${protocol.displayName} - ${app.doseValue} ${app.doseUnit}',
        scheduledAt: app.scheduledAt,
        offsetMinutes: offset,
      );

      app.notificationId = notifId;
    }

    await StorageService.saveApplications(applications);
  }

  static bool _shouldCancelReminder(ApplicationRecord app, Set<String> activeProtocolIds) {
    if (app.manuallyCreated) return false;
    if (app.status != ApplicationStatus.scheduled) return true;
    if (!app.scheduledAt.isAfter(DateTime.now())) return true;
    if (!activeProtocolIds.contains(app.protocolId)) return true;
    return false;
  }

  static int _generateNotificationId(ApplicationRecord app) {
    final hash = app.id.hashCode;
    return (hash & 0x7fffffff) % 2000000000;
  }
}