import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/models/budget.dart';
import 'package:flutterapp/models/notification_preferences.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/repository/transaction_service.dart';
import 'package:flutterapp/repository/user_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TransactionViewModel extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        _listenToTransactions(); // Start listening to transactions
        _listenToBudgets(); // Start listening to budgets
      } else {
        _transactions = [];
        _budgets = [];
        _userNotificationPreferences = NotificationPreferences();
        notifyListeners();
      }
    });
  }

  void _loadData(String userId) async {
    await _loadUserNotificationPreferences(userId);
  }

  void _listenToTransactions() {
    _transactionService.getTransactionsForCurrentUser().listen((transactionsList) {
      _transactions = transactionsList;
      notifyListeners();
      // After transactions are loaded/updated, re-check budgets if needed
      _checkAllBudgets();
    });
  }

  void _listenToBudgets() {
    _userRepository.getBudgetsForCurrentUser().listen((budgetsList) {
      _budgets = budgetsList;
      notifyListeners();
      // After budgets are loaded/updated, re-check budgets if needed
      _checkAllBudgets();
    });
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
      // Data will be reloaded automatically by stream listeners
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
    required TransactionType type, // Make sure type is included for updates
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
      // Data will be reloaded automatically by stream listeners
      if (updatedTxn.type == TransactionType.EXPENSE && _userNotificationPreferences.overBudgetAlerts) {
        _checkForOverBudget(updatedTxn.userId, updatedTxn.category, updatedTxn.amount);
      }
    } else {
      Fluttertoast.showToast(msg: "Failed to update transaction.");
    }
  }

  void _checkForOverBudget(String userId, String category, double newExpenseAmount) {
    if (!_userNotificationPreferences.overBudgetAlerts) {
      print("Over budget alerts are disabled by user preferences.");
      return;
    }

    final budgetForCategory = _budgets.firstWhere(
      (budget) => budget.category == category && budget.userId == userId,
      orElse: () => throw Exception("No budget found for category $category"), // Handle no budget scenario
    );

    // Calculate current month's expenses for this category
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);

    final currentPeriodExpensesForCategory = _transactions
        .where((txn) =>
            txn.type == TransactionType.EXPENSE &&
            txn.category == category &&
            txn.userId == userId &&
            txn.date.toDate().isAfter(currentMonthStart.subtract(const Duration(days: 1))) // Check from start of month
            )
        .fold(0.0, (sum, txn) => sum + txn.amount);

    print("Checking budget for category '$category'. Budget: €${budgetForCategory.amount}, Current expenses: €$currentPeriodExpensesForCategory");

    if (currentPeriodExpensesForCategory > budgetForCategory.amount) {
      final amountOver = currentPeriodExpensesForCategory - budgetForCategory.amount;
      print("Over budget for '$category' by €$amountOver. Triggering notification.");
      Fluttertoast.showToast(msg: "Over budget in $category by €${amountOver.toStringAsFixed(2)}", toastLength: Toast.LENGTH_LONG);
      // TODO: Integrate local notification package here for persistent notification
      // NotificationHelper.showOverBudgetNotification(getApplication(), category, amountOver);
    } else {
      print("Still within budget for '$category'.");
    }
  }

  void _checkAllBudgets() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    for (var budget in _budgets) {
      _checkForOverBudget(currentUserId, budget.category, 0.0); // Pass 0.0 as we are re-evaluating, not adding a new expense
    }
  }

  Future<void> addBudget(Budget budget) async {
  bool success = await _userRepository.addBudget(budget);
  if (success) {
    Fluttertoast.showToast(msg: "Budget added!");
    // No need to manually refresh, stream listener will update automatically
  } else {
    Fluttertoast.showToast(msg: "Failed to add budget.");
  }
}

}