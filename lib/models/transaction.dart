import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { EXPENSE, INCOME }

class Transaction {
  String? id;
  final String userId;
  final double amount;
  final String description;
  final String category;
  final TransactionType type;
  final Timestamp date;
  final String? receiptUrl;

  Transaction({
    this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.category,
    required this.type,
    required this.date,
    this.receiptUrl,
  });

  // Factory constructor for creating a Transaction from a Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      type: TransactionType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => TransactionType.EXPENSE),
      date: data['date'] ?? Timestamp.now(),
      receiptUrl: data['receiptUrl'],
    );
  }

  // Method to convert a Transaction to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'type': type.toString().split('.').last, // Store as string
      'date': date,
      'receiptUrl': receiptUrl,
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? description,
    String? category,
    TransactionType? type,
    Timestamp? date,
    String? receiptUrl,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}