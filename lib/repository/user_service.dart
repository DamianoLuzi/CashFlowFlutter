import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/models/budget.dart';
import 'package:flutterapp/models/notification_preferences.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This is a simplified representation.
  // In a real app, you might have a User model that contains preferences.
  // For now, directly fetching preferences and budgets.

  Future<NotificationPreferences?> getUserNotificationPreferences(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection("users").doc(userId).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('notificationPreferences')) {
          return NotificationPreferences.fromMap(data['notificationPreferences']);
        }
      }
    } catch (e) {
      print("Error getting user notification preferences: $e");
    }
    return null;
  }

  Future<bool> updateUserNotificationPreferences(String userId, NotificationPreferences preferences) async {
    try {
      await _db.collection("users").doc(userId).set({
        'notificationPreferences': preferences.toMap(),
      }, SetOptions(merge: true)); // Merge to avoid overwriting other user data
      return true;
    } catch (e) {
      print("Error updating user notification preferences: $e");
      return false;
    }
  }

  Stream<List<Budget>> getBudgetsForCurrentUser() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return _db
        .collection("budgets")
        .where("userId", isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromFirestore(doc))
            .toList());
  }

  Future<bool> addBudget(Budget budget) async {
    try {
      DocumentReference docRef = await _db.collection("budgets").add(budget.toFirestore());
      await docRef.update({'id': docRef.id});
      return true;
    } catch (e) {
      print("Error adding budget: $e");
      return false;
    }
  }

  // You'll need more methods for updating/deleting budgets if your Android app has them
}