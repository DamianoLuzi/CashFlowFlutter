import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/models/budget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutterapp/repository/user_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Budget> _budgets = [];
  List<Budget> get budgets => _budgets;

  BudgetViewModel() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToBudgets();
      } else {
        _budgets = [];
        notifyListeners();
      }
    });
  }

  void _listenToBudgets() {
    _userRepository.getBudgetsForCurrentUser().listen((budgetsList) {
      _budgets = budgetsList;
      notifyListeners();
    });
  }

  Future<void> addBudget(Budget budget) async {
    bool success = await _userRepository.addBudget(budget);
    if (success) {
      Fluttertoast.showToast(msg: "Budget added!");
    } else {
      Fluttertoast.showToast(msg: "Failed to add budget.");
    }
  }
  Future<void> deleteBudget(String budgetId) async {
    bool success = await _userRepository.deleteBudget(budgetId);
    if (success) {
      Fluttertoast.showToast(msg: "Budget deleted!");
    } else {
      Fluttertoast.showToast(msg: "Failed to delete budget.");
    }
  }
}
