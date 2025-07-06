import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/models/transaction.dart';

class TransactionService {
  final firestore.FirebaseFirestore _db = firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> addTransaction(Transaction transaction) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("User not logged in. Cannot add transaction.");
      return false;
    }

    try {
      firestore.DocumentReference docRef = await _db.collection("transaction").add(transaction.toFirestore());
      await docRef.update({'id': docRef.id});
      print("Transaction added successfully with ID: ${docRef.id}");
      return true;
    } catch (e) {
      print("Error adding transaction: $e");
      return false;
    }
  }

  Stream<List<Transaction>> getTransactionsForCurrentUser() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection("transaction")
        .where("userId", isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .toList());
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      print("Transaction ID is null. Cannot update.");
      return false;
    }
    try {
      await _db.collection("transaction").doc(transaction.id).update(transaction.toFirestore());
      print("Transaction updated successfully: ${transaction.id}");
      return true;
    } catch (e) {
      print("Error updating transaction: $e");
      return false;
    }
  }

  Future<List<Transaction>> getTransactionsByDateRange(
      String userId, firestore.Timestamp startDate, firestore.Timestamp endDate) async {
    if (userId.isEmpty) {
      print("User ID is blank. Returning empty list.");
      return [];
    }
    if (startDate.seconds > endDate.seconds) {
      print("Start date is after end date. Returning empty list.");
      return [];
    }

    try {
      firestore.QuerySnapshot querySnapshot = await _db
          .collection("transaction")
          .where("userId", isEqualTo: userId)
          .where("date", isGreaterThanOrEqualTo: startDate)
          .where("date", isLessThanOrEqualTo: endDate)
          .get();

      return querySnapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching transactions by date range: $e");
      return [];
    }
  }

  Future<bool> deleteTransaction(String id) async {
  try {
    await _db.collection("transaction").doc(id).delete();
    print("Transaction deleted successfully: $id");
    return true;
  } catch (e) {
    print("Error deleting transaction: $e");
    return false;
  }
}

}