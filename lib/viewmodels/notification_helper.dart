import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;


class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Make sure this icon exists

    final InitializationSettings settings = InitializationSettings(
      android: androidInitSettings,
    );

    await _plugin.initialize(settings);
  }

  static Future<void> showOverBudgetNotification(String category, double amountOver) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_channel_id',
      'Budget Alerts',
      channelDescription: 'Alerts when you go over budget',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Budget Exceeded!',
      'Over budget in $category by €${amountOver.toStringAsFixed(2)}',
      notificationDetails,
    );
  }


static tz.TZDateTime _nextInstanceOfWeekdayTime({
  required int weekday,
  required int hour,
  required int minute,
}) {
  final now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

  while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  return scheduledDate;
}


  static Future<void> scheduleSpendingSummary({
  required String summaryText,
  required int id,
  required int weekday, // 1 = Monday, 7 = Sunday
  required int hour,
  required int minute,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'summary_channel_id',
    'Spending Summaries',
    channelDescription: 'spending summary',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

  final tz.TZDateTime scheduledDate = _nextInstanceOfWeekdayTime(
    weekday: weekday,
    hour: hour,
    minute: minute,
  );

  await _plugin.zonedSchedule(
    id,
    'Spending Summary',
    summaryText,
    scheduledDate,
    notificationDetails,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

// In your NotificationHelper class

static Future<void> scheduleNextMinuteSpendingSummary({
  required String summaryText,
  required int id,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'summary_channel_id',
    'Spending Summaries',
    channelDescription: 'Weekly spending summary (testing)',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

  // Schedule for one minute from now for testing
  final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));

  await _plugin.zonedSchedule(
    id,
    'Test Spending Summary (Next Minute)',
    summaryText,
    scheduledDate,
    notificationDetails,
    // Remove matchDateTimeComponents for one-off scheduling at a specific future time
    // matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // <--- REMOVE OR COMMENT OUT FOR THIS TEST
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
  print('Scheduled notification ID $id for: $scheduledDate');
}
}
