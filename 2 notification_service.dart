import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {
      // Mantém timezone padrão se falhar
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    await _createChannels();
    await _requestPermissions();

    _initialized = true;
  }

  static Future<void> _createChannels() async {
    const reminderChannel = AndroidNotificationChannel(
      'reminders',
      'Lembretes de Aplicacao',
      description: 'Lembretes para aplicar seus protocolos',
      importance: Importance.high,
      playSound: true,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(reminderChannel);
  }

  static Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    int offsetMinutes = 0,
  }) async {
    await init();

    final notificationTime = scheduledAt.subtract(Duration(minutes: offsetMinutes));

    if (!notificationTime.isAfter(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Lembretes de Aplicacao',
      channelDescription: 'Lembretes para aplicar seus protocolos',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}