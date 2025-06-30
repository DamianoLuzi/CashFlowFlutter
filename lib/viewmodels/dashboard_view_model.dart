import 'package:flutter/foundation.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/viewmodels/transaction_view_model.dart';
import 'package:intl/intl.dart';

class DashboardViewModel extends ChangeNotifier {

  final TransactionViewModel _transactionViewModel;

  DashboardViewModel(this._transactionViewModel) {
    _transactionViewModel.addListener(_onTransactionsChanged);
  }
  void _onTransactionsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _transactionViewModel.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  Map<String, double> getTotalsForDateRange(DateTime startDate, DateTime endDate) {
    double totalIncome = 0.0;
    double totalExpenses = 0.0;

    final filteredTransactions = _transactionViewModel.transactions.where((txn) {
      final transactionDate = txn.date.toDate();
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

  Map<String, Map<String, double>> getMonthlyTrends(int numberOfMonths) {
    Map<String, Map<String, double>> monthlyData = {};
    final now = DateTime.now();

    for (int i = numberOfMonths - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final monthKey = DateFormat('MMM yy').format(month); 
      monthlyData[monthKey] = {'income': 0.0, 'expenses': 0.0};
      final transactionsInMonth = _transactionViewModel.transactions.where((txn) {
        final transactionDate = txn.date.toDate();
        return transactionDate.isAfter(month.subtract(const Duration(days: 1))) && 
               transactionDate.isBefore(nextMonth);
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