import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/models/budget.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/viewmodels/category_view_model.dart';
import 'package:flutterapp/viewmodels/transaction_view_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Transactions"),
          actions: [
            PopupMenuButton<TransactionType?>(
              icon: Icon(Icons.filter_list),
              onSelected: (val) {
                setState(() {
                  _filter = val;
                });
                context.read<TransactionViewModel>().setFilter(val);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: null, child: Text("All")),
                PopupMenuItem(value: TransactionType.INCOME, child: Text("Income")),
                PopupMenuItem(value: TransactionType.EXPENSE, child: Text("Expense")),
              ],
            )
          ],
        ),
        body: Consumer<TransactionViewModel>(
          builder: (context, vm, _) {
            final transactions = vm.filteredTransactions;
            if (transactions.isEmpty) return Center(child: Text("No transactions"));

            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return ListTile(
                  title: Text("${txn.category} - €${txn.amount.toStringAsFixed(2)}"),
                  subtitle: Text(txn.description),
                  trailing: Text(DateFormat.yMMMd().format(txn.date.toDate())),
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
  final categoryVM = context.read<CategoryViewModel>();
  final categories = categoryVM.getAllCategoriesForDisplay();

  showDialog(
    context: context,
    builder: (ctx) {
      String? selectedCategory;

      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Add Budget"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.name,
                            child: Text("${c.icon} ${c.name}"),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedCategory = val),
                  decoration: InputDecoration(labelText: "Category"),
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: "Amount"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;

                if (selectedCategory != null && amount > 0) {
                  final budget = Budget(
                    userId: FirebaseAuth.instance.currentUser!.uid,
                    category: selectedCategory!,
                    amount: amount,
                  );

                  context.read<TransactionViewModel>().addBudget(budget);
                  Navigator.pop(ctx);
                } else {
                  // Optionally show an error message
                }
              },
              child: Text("Add"),
            )
          ],
        ),
      );
    },
  );
}


  /* void _showAddTransactionDialog(BuildContext context) {
    final _amountController = TextEditingController();
    final _descController = TextEditingController();
    String? selectedCategory;
    TransactionType selectedType = TransactionType.EXPENSE;

    final categoryVM = context.read<CategoryViewModel>();
    final categories = categoryVM.getAllCategoriesForDisplay();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Transaction"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                items: categories
                    .map((c) => DropdownMenuItem(child: Text("${c.icon} ${c.name}"), value: c.name))
                    .toList(),
                onChanged: (val) => selectedCategory = val,
                decoration: InputDecoration(labelText: "Category"),
              ),
              DropdownButtonFormField<TransactionType>(
                value: selectedType,
                onChanged: (val) => selectedType = val ?? TransactionType.EXPENSE,
                items: TransactionType.values
                    .map((e) => DropdownMenuItem(child: Text(e.toString().split('.').last), value: e))
                    .toList(),
                decoration: InputDecoration(labelText: "Type"),
              ),
              TextField(controller: _amountController, decoration: InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
              TextField(controller: _descController, decoration: InputDecoration(labelText: "Description")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
              final desc = _descController.text.trim();
              if (amount > 0 && selectedCategory != null && desc.isNotEmpty) {
                context.read<TransactionViewModel>().addTransaction(
                  amount: amount,
                  description: desc,
                  category: selectedCategory!,
                  type: selectedType,
                );
                Navigator.pop(ctx);
              }
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  } */
}
