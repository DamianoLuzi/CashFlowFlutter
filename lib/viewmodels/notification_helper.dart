import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutterapp/models/notification_preferences.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/repository/transaction_service.dart';
import 'package:flutterapp/repository/user_service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';


class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidInitSettings,
    );

    await _plugin.initialize(settings);
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'budget_channel_id',
          'Budget Alerts',
          description: 'Alerts when you go over budget',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'summary_channel_id',
          'Spending Summaries',
          description: 'Weekly spending summary',
          importance: Importance.defaultImportance, 
        ),
      );
    }
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
  required int weekday,
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
    scheduledDate ,
    notificationDetails,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
  print('Successfully called zonedSchedule for ID $id for: $scheduledDate');
}

static Future<void> showWeeklySummaryNotification(String summaryText) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'summary_channel_id',
      'Spending Summaries',
      channelDescription: 'Weekly spending summary',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(''), // Enable long text display
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      1002, // Unique ID for spending summary notification (matches Kotlin example)
      'Spending Summary',
      summaryText,
      notificationDetails,
    );
    print('Displayed Spending Summary Notification.');
  }

 static Future<void> requestNotificationPermission() async {
  final prefs = await SharedPreferences.getInstance();
  final askedBefore = prefs.getBool('notification_permission_asked') ?? false;

  if (!askedBefore) {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();

      if (status.isGranted) {
        print('Notification permission granted');
      } else if (status.isDenied) {
        print('Notification permission denied');
      } else if (status.isPermanentlyDenied) {
        print('Notification permission permanently denied. Please enable it in settings.');
      }
    }
    await prefs.setBool('notification_permission_asked', true);
  } else {
    print('Notification permission already requested before, skipping.');
  }
}
}

const String SPENDING_SUMMARY_TASK = "spendingSummaryTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case SPENDING_SUMMARY_TASK:
        print("Executing Spending Summary Task in background!");
        await Firebase.initializeApp();
        await NotificationHelper.initialize();

        final FirebaseAuth auth = FirebaseAuth.instance;
        final UserRepository userRepository = UserRepository();
        final TransactionService transactionService = TransactionService();

        final userId = auth.currentUser?.uid;
        if (userId == null) {
          print("SpendingSummaryTask: No user logged in. Skipping summary.");
          return Future.value(true);
        }
        final userPreferences = await userRepository.getUserNotificationPreferences(userId) ?? NotificationPreferences();

        if (!userPreferences.spendingSummaries) {
          print("SpendingSummaryTask: Spending summaries are disabled by user preferences.");
          return Future.value(true); 
        }
        final now = DateTime.now();
        DateTime endOfLastWeek = now.subtract(Duration(days: now.weekday));
        endOfLastWeek = DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day, 23, 59, 59); 
        DateTime startOfLastWeek = endOfLastWeek.subtract(const Duration(days: 6)); 
        startOfLastWeek = DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day, 0, 0, 0);

        print("SpendingSummaryTask: Fetching transactions for last week: $startOfLastWeek to $endOfLastWeek");
        final startDateTimestamp = Timestamp.fromDate(startOfLastWeek);
        final endDateTimestamp = Timestamp.fromDate(endOfLastWeek);

        List<Transaction> spendingTransactions = [];
        try {
          spendingTransactions = await transactionService.getTransactionsByDateRange(userId, startDateTimestamp, endDateTimestamp);
        } catch (e) {
          print("SpendingSummaryTask: Error fetching transactions: $e");
          return Future.value(false);
        }


        final totalIncome = spendingTransactions
            .where((it) => it.type == TransactionType.INCOME)
            .fold(0.0, (sum, txn) => sum + txn.amount);

        final totalExpenses = spendingTransactions
            .where((it) => it.type == TransactionType.EXPENSE)
            .fold(0.0, (sum, txn) => sum + txn.amount);

        final netBalance = totalIncome - totalExpenses;

        final formatter = NumberFormat("0.00", "en_US"); 
        final summaryText = """
          Spending Summary (${DateFormat.MMMd().format(startOfLastWeek)} - ${DateFormat.MMMd().format(endOfLastWeek)}):
          Total Income: €${formatter.format(totalIncome)}
          Total Expenses: €${formatter.format(totalExpenses)}
          Net Balance: €${formatter.format(netBalance)}
        """;

        print("SpendingSummaryTask: Generated summary: $summaryText");
        await NotificationHelper.showWeeklySummaryNotification(summaryText);
        return Future.value(true);
      default:
        print("Unknown task: $task");
        return Future.value(false);
    }
  });
}