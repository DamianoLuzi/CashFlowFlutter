/* class Category {
  String? id;
  final String name;
  final String? icon; // For emojis or icons

  Category({this.id,required this.name, this.icon});

  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      name: data['name'] ?? '',
      icon: data['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
    };
  }
} */


import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  String? id;
  final String? userId;  // add this here
  final String name;
  final String? icon;

  Category({
    this.id,
    this.userId,
    required this.name,
    this.icon,
  });

  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      icon: data['icon'],
    );
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      icon: data['icon'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'icon': icon,
    };
  }
}
