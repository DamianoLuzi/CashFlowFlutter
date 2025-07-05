import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/models/budget.dart';
import 'package:flutterapp/viewmodels/budget_view_model.dart';
import 'package:flutterapp/viewmodels/category_view_model.dart';
import 'package:provider/provider.dart';


class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BudgetViewModel(),
      child: Scaffold(
        appBar: AppBar(title: Text("Budgets")),
        body: Consumer<BudgetViewModel>(
          builder: (context, vm, _) {
            final budgets = vm.budgets;
            if (budgets.isEmpty) return Center(child: Text("No budgets set"));

            return ListView.builder(
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                return ListTile(
                  title: Text(budget.category),
                  trailing: Row( // Use a Row for multiple trailing widgets
                    mainAxisSize: MainAxisSize.min, // Keep row compact
                    children: [
                      Text("€${budget.amount.toStringAsFixed(2)}"),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), // Delete icon
                        onPressed: () => _confirmDeleteBudget(context, budget), // Confirmation dialog
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => _showAddBudgetDialog(context),
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final amountController = TextEditingController();
    String? selectedCategory;

    final categoryVM = context.read<CategoryViewModel>();
    final categories = categoryVM.getAllCategoriesForDisplay();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Budget"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              items: categories
                  .map((c) => DropdownMenuItem(value: c.name, child: Text("${c.icon} ${c.name}")))
                  .toList(),
              onChanged: (val) => selectedCategory = val,
              decoration: InputDecoration(labelText: "Category"),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (selectedCategory != null && amount > 0) {
                final budget = Budget(
                  userId: FirebaseAuth.instance.currentUser!.uid,
                  category: selectedCategory!,
                  amount: amount,
                );
                context.read<BudgetViewModel>().addBudget(budget);
                Navigator.pop(ctx);
              }
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }

  void _confirmDeleteBudget(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Budget"),
        content: Text("Are you sure you want to delete the budget for ${budget.category}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<BudgetViewModel>().deleteBudget(budget.id!); // Pass budget ID
              Navigator.pop(ctx); // Close dialog
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Red button for delete
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

}