import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/models/budget.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/screens/transaction_details.dart';
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
                  onTap: () async {
                    final updatedTxn = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionDetailScreen(transaction: txn),
                      ),
                    );
                  },
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
}
