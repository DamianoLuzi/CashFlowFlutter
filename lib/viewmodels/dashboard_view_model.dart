// lib/viewmodels/dashboard_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/viewmodels/transaction_view_model.dart';
import 'package:intl/intl.dart';

// Renamed from OverviewViewModel to DashboardViewModel
class DashboardViewModel extends ChangeNotifier {
  // DashboardViewModel now directly depends on TransactionViewModel
  final TransactionViewModel _transactionViewModel;

  // Constructor receives the TransactionViewModel instance
  DashboardViewModel(this._transactionViewModel) {
    // Listen to changes in TransactionViewModel to update the dashboard
    _transactionViewModel.addListener(_onTransactionsChanged);
  }

  // This method is called when TransactionViewModel notifies listeners
  void _onTransactionsChanged() {
    // Re-calculate dashboard data if needed and notify this ViewModel's listeners
    notifyListeners();
  }

  @override
  void dispose() {
    // Important: Remove the listener to prevent memory leaks
    _transactionViewModel.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  // --- Data Aggregation Methods for Dashboard ---

  // Get aggregated income and expenses for a specific date range
  Map<String, double> getTotalsForDateRange(DateTime startDate, DateTime endDate) {
    double totalIncome = 0.0;
    double totalExpenses = 0.0;

    // Filter transactions from the TransactionViewModel's list
    final filteredTransactions = _transactionViewModel.transactions.where((txn) {
      final transactionDate = txn.date.toDate();
      // Ensure the transaction date is within the specified range (inclusive of start, exclusive of end day's start)
      return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    for (var txn in filteredTransactions) {
      if (txn.type == TransactionType.INCOME) {
        totalIncome += txn.amount;
      } else {
        totalExpenses += txn.amount;
      }
    }
    return {'income': totalIncome, 'expenses': totalExpenses};
  }

  // Get expenses by category for a specific date range
  Map<String, double> getExpensesByCategory(DateTime startDate, DateTime endDate) {
    Map<String, double> categoryExpenses = {};

    final filteredTransactions = _transactionViewModel.transactions.where((txn) {
      final transactionDate = txn.date.toDate();
      return txn.type == TransactionType.EXPENSE &&
             transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    for (var txn in filteredTransactions) {
      categoryExpenses.update(txn.category, (value) => value + txn.amount,
          ifAbsent: () => txn.amount);
    }
    return categoryExpenses;
  }

  // Get income by category for a specific date range
  Map<String, double> getIncomeByCategory(DateTime startDate, DateTime endDate) {
    Map<String, double> categoryIncome = {};

    final filteredTransactions = _transactionViewModel.transactions.where((txn) {
      final transactionDate = txn.date.toDate();
      return txn.type == TransactionType.INCOME &&
             transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    for (var txn in filteredTransactions) {
      categoryIncome.update(txn.category, (value) => value + txn.amount,
          ifAbsent: () => txn.amount);
    }
    return categoryIncome;
  }

  // Get monthly income/expense trends for a given number of past months
  Map<String, Map<String, double>> getMonthlyTrends(int numberOfMonths) {
    Map<String, Map<String, double>> monthlyData = {};
    final now = DateTime.now();

    for (int i = numberOfMonths - 1; i >= 0; i--) {
      // Calculate the start and end of the current month in the loop
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1); // Start of next month

      final monthKey = DateFormat('MMM yy').format(month); // e.g., 'Jul 24'

      // Initialize data for the month
      monthlyData[monthKey] = {'income': 0.0, 'expenses': 0.0};

      // Filter transactions for the current month in the loop
      final transactionsInMonth = _transactionViewModel.transactions.where((txn) {
        final transactionDate = txn.date.toDate();
        // Check if transaction date is within the current month
        return transactionDate.isAfter(month.subtract(const Duration(days: 1))) && // From start of month
               transactionDate.isBefore(nextMonth); // Up to (but not including) start of next month
      }).toList();

      for (var txn in transactionsInMonth) {
        if (txn.type == TransactionType.INCOME) {
          monthlyData[monthKey]!['income'] = (monthlyData[monthKey]!['income'] ?? 0.0) + txn.amount;
        } else {
          monthlyData[monthKey]!['expenses'] = (monthlyData[monthKey]!['expenses'] ?? 0.0) + txn.amount;
        }
      }
    }
    return monthlyData;
  }
}