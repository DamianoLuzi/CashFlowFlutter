import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/models/budget.dart';
import 'package:flutterapp/models/notification_preferences.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/repository/transaction_service.dart';
import 'package:flutterapp/repository/user_service.dart';
import 'package:flutterapp/viewmodels/notification_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:workmanager/workmanager.dart'; 

class TransactionViewModel extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _budgetsSubscription;


  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  List<Budget> _budgets = [];
  List<Budget> get budgets => _budgets;

  NotificationPreferences _userNotificationPreferences = NotificationPreferences();
  NotificationPreferences get userNotificationPreferences => _userNotificationPreferences;

  TransactionType? _filter;
  TransactionType? get filter => _filter;

  List<Transaction> get filteredTransactions {
    if (_filter == null) {
      return _transactions;
    } else {
      return _transactions.where((txn) => txn.type == _filter).toList();
    }
  }

  TransactionViewModel() {

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadData(user.uid);
    } else {
        _transactions = [];
        _budgets = [];
        _userNotificationPreferences = NotificationPreferences();
        Workmanager().cancelByUniqueName(SPENDING_SUMMARY_TASK);
        notifyListeners();
      }
    });
  }

  void _loadData(String userId) async {
    await _loadUserNotificationPreferences(userId);
    _listenToTransactions();
    _listenToBudgets();
    _manageSpendingSummaryNotification();
  }

  void _manageSpendingSummaryNotification() {

  if (_userNotificationPreferences.spendingSummaries) {
    print("Scheduling periodic spending summary task via Workmanager.");
    Workmanager().registerPeriodicTask(
      SPENDING_SUMMARY_TASK, 
      SPENDING_SUMMARY_TASK, 
      frequency: const Duration(days: 7),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.update
    );
  } else {
    print("Cancelling periodic spending summary task via Workmanager.");
    Workmanager().cancelByUniqueName(SPENDING_SUMMARY_TASK);
  }
  }


  void _listenToTransactions() {
    _transactionsSubscription = _transactionService.getTransactionsForCurrentUser().listen((transactionsList) {
      _transactions = transactionsList;
      notifyListeners();
    });
  }

  void _listenToBudgets() {
    _budgetsSubscription = _userRepository.getBudgetsForCurrentUser().listen((budgetsList) {
      _budgets = budgetsList;
      notifyListeners();
    });
  }

  @override
void dispose() {
  _transactionsSubscription?.cancel();
  _budgetsSubscription?.cancel();
  super.dispose();
}


  Future<void> _loadUserNotificationPreferences(String userId) async {
    _userNotificationPreferences = await _userRepository.getUserNotificationPreferences(userId) ?? NotificationPreferences();
    notifyListeners();
  }

  void setFilter(TransactionType? type) {
    _filter = type;
    notifyListeners();
  }

  Future<void> addTransaction({
    required double amount,
    required String description,
    required String category,
    required TransactionType type,
    String? receiptUrl,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print("addTransaction: Current user ID is null. Cannot add transaction.");
      return;
    }

    final txn = Transaction(
      userId: currentUserId,
      amount: amount,
      description: description,
      category: category,
      type: type,
      date: Timestamp.now(),
      receiptUrl: receiptUrl,
    );

    bool success = await _transactionService.addTransaction(txn);
    if (success) {
      Fluttertoast.showToast(msg: "Transaction added!");
      if (txn.type == TransactionType.EXPENSE && _userNotificationPreferences.overBudgetAlerts) {
        _checkForOverBudget(txn.userId, txn.category, txn.amount);
      }
    } else {
      Fluttertoast.showToast(msg: "Failed to add transaction.");
    }
  }

  Transaction? getTransactionById(String id) {
    return _transactions.firstWhere((txn) => txn.id == id, orElse: () => throw Exception("Transaction not found"));
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required String description,
    required String category,
    String? receiptUrl,
    required Timestamp date,
    required TransactionType type,
  }) async {
    final updatedTxn = _transactions.firstWhere((txn) => txn.id == id).copyWith(
      amount: amount,
      description: description,
      category: category,
      receiptUrl: receiptUrl,
      date: date,
      type: type,
    );

    bool success = await _transactionService.updateTransaction(updatedTxn);
    if (success) {
      Fluttertoast.showToast(msg: "Transaction updated!");
      if (updatedTxn.type == TransactionType.EXPENSE && _userNotificationPreferences.overBudgetAlerts) {
        _checkForOverBudget(updatedTxn.userId, updatedTxn.category, updatedTxn.amount);
      }
    } else {
      Fluttertoast.showToast(msg: "Failed to update transaction.");
    }
  }

  void _checkForOverBudget(String userId, String category, double newExpenseAmount) async {
    if (!_userNotificationPreferences.overBudgetAlerts) {
      print("Over budget alerts are disabled by user preferences.");
      return;
    }

    final budgetForCategory = _budgets.firstWhere(
      (budget) => budget.category == category && budget.userId == userId,
      orElse: () => throw Exception("No budget found for category $category"),
    );

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);

    final currentPeriodExpensesForCategory = _transactions
        .where((txn) =>
            txn.type == TransactionType.EXPENSE &&
            txn.category == category &&
            txn.userId == userId &&
            txn.date.toDate().isAfter(currentMonthStart.subtract(const Duration(days: 1)))
            )
        .fold(0.0, (sum, txn) => sum + txn.amount);

    print("Checking budget for category '$category'. Budget: €${budgetForCategory.amount}, Current expenses: €$currentPeriodExpensesForCategory");

    if (currentPeriodExpensesForCategory > budgetForCategory.amount) {
      final amountOver = currentPeriodExpensesForCategory - budgetForCategory.amount;
      print("Over budget for '$category' by €$amountOver. Triggering notification.");
      NotificationHelper.showOverBudgetNotification( category, amountOver);
    } else {
      print("Still within budget for '$category'.");
    }
  }

  void _checkAllBudgets() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    for (var budget in _budgets) {
      _checkForOverBudget(currentUserId, budget.category, 0.0);
    }
  }

  Future<void> addBudget(Budget budget) async {
  bool success = await _userRepository.addBudget(budget);
  if (success) {
    Fluttertoast.showToast(msg: "Budget added!");
  } else {
    Fluttertoast.showToast(msg: "Failed to add budget.");
  }
}

Future<void> deleteTransaction(String id) async {
  bool success = await _transactionService.deleteTransaction(id);
  if (success) {
    Fluttertoast.showToast(msg: "Transaction deleted!");
  } else {
    Fluttertoast.showToast(msg: "Failed to delete transaction.");
  }
}


}