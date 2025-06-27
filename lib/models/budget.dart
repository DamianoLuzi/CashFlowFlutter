
import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  String? id;
  final String userId;
  final String category;
  final double amount;
  final Timestamp createdAt;

  Budget({
    this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.createdAt,
  });

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'category': category,
      'amount': amount,
      'createdAt': createdAt,
    };
  }
}