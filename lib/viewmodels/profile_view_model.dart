import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/models/notification_preferences.dart';
import 'package:flutterapp/repository/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  String _userName = '';
  String _userEmail = '';
  NotificationPreferences _preferences = NotificationPreferences();

  String get userName => _userName;
  String get userEmail => _userEmail;
  NotificationPreferences get preferences => _preferences;

  ProfileViewModel() {
    _loadUserData();
  }

  void _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userEmail = user.email ?? '';
      _userName = user.displayName ?? 'User'; // Or fetch from Firestore
      _preferences = await _userRepository.getUserNotificationPreferences(user.uid) ?? NotificationPreferences();
      notifyListeners();
    }
  }

  Future<void> toggleOverBudgetAlerts(bool enabled) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _preferences = _preferences.copyWith(overBudgetAlerts: enabled);
    final success = await _userRepository.updateUserNotificationPreferences(userId, _preferences);
    if (success) {
      notifyListeners();
    }
  }

  Future<void> toggleSpendingSummary(bool enabled) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return;

  _preferences = _preferences.copyWith(spendingSummary: enabled);
  final success = await _userRepository.updateUserNotificationPreferences(userId, _preferences);
  if (success) {
    notifyListeners();
  }
}


  Future<void> signOut() async {
    await _auth.signOut();
  }
}
