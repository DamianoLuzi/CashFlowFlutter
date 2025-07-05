import 'package:flutter/foundation.dart' as foundation;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/models/category.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CategoryViewModel extends foundation.ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  // Define default categories
 final List<Category> defaultCategories = [
  Category(userId: 'default', name: "Food", icon: "🍔"),
  Category(userId: 'default', name: "Transport", icon: "🚌"),
  Category(userId: 'default', name: "Housing", icon: "🏠"),
  Category(userId: 'default', name: "Entertainment", icon: "🎉"),
  Category(userId: 'default', name: "Shopping", icon: "🛍️"),
  Category(userId: 'default', name: "Health", icon: "🏥"),
  Category(userId: 'default', name: "Salary", icon: "💰"),
  Category(userId: 'default', name: "Investments", icon: "📈"),
];

  CategoryViewModel() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToCustomCategories();
      } else {
        _categories = [];
        notifyListeners();
      }
    });
  }


  void _listenToCustomCategories() {
  final userId = _auth.currentUser?.uid;
  if (userId == null) {
    _categories = [];
    notifyListeners();
    return;
  }
  _db
      .collection("categories")
      .where("userId", isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList())
      .listen((customCategories) {
        _categories = customCategories;
        notifyListeners();
      });
}

  List<Category> getAllCategoriesForDisplay() {
    final combinedList = <Category>[];

    // Add default categories first
    combinedList.addAll(defaultCategories);

    // Add custom categories, preferring custom ones if names overlap
    for (var customCat in _categories) {
      final existingIndex = combinedList.indexWhere((cat) => cat.name == customCat.name);
      if (existingIndex != -1) {
        combinedList[existingIndex] = customCat; // Replace default with custom
      } else {
        combinedList.add(customCat);
      }
    }
    combinedList.sort((a, b) => a.name.compareTo(b.name));
    return combinedList;
  }

Future<bool> addCustomCategory(Category category) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return false;

  try {
    // ensure the category has userId set
    final catToAdd = Category(
      userId: userId,
      name: category.name,
      icon: category.icon,
    );

    DocumentReference docRef = await  _db.collection("categories").add(catToAdd.toFirestore());
    await docRef.update({'id': docRef.id});
    return true;
  } catch (e) {
    print("Error adding custom category: $e");
    return false;
  }
}

Future<bool> deleteCategory(String categoryId) async {
    try {
      await _db.collection("categories").doc(categoryId).delete();
      Fluttertoast.showToast(msg: "Category deleted!"); // Feedback
      return true;
    } catch (e) {
      print("Error deleting category: $e");
      Fluttertoast.showToast(msg: "Failed to delete category."); // Feedback
      return false;
    }
  }
}