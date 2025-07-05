import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/repository/supabase_service.dart';
import 'package:flutterapp/viewmodels/category_view_model.dart';
import 'package:flutterapp/viewmodels/transaction_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TransactionType _type;
  late String _category;
  late DateTime _selectedDate;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedReceiptImage;
  String? _existingReceiptUrl;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _descriptionController = TextEditingController(text: widget.transaction.description);
    _type = widget.transaction.type;
    _category = widget.transaction.category;
    _selectedDate = widget.transaction.date.toDate();
    _existingReceiptUrl = widget.transaction.receiptUrl;
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedReceiptImage = image;
        _existingReceiptUrl = null; // Clear previous URL to avoid confusion
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryVM = context.read<CategoryViewModel>();
    final categories = categoryVM.getAllCategoriesForDisplay();

    return Scaffold(
      appBar: AppBar(title: Text("Edit Transaction")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<TransactionType>(
              value: _type,
              items: TransactionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (val) => setState(() => _type = val!),
              decoration: InputDecoration(labelText: "Type"),
            ),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(labelText: "Category"),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.name,
                        child: Row(
                          children: [
                            Text(c.icon ?? ''),
                            SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Date"),
              subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _pickDate(context),
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 16),
            Text("Receipt (optional)"),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Select Receipt Image"),
            ),
            if (_selectedReceiptImage != null)
              Text("Selected: ${_selectedReceiptImage!.name}"),
            if (_existingReceiptUrl != null)
              Text("Existing: ${_existingReceiptUrl!}", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text.trim()) ?? widget.transaction.amount;
                final description = _descriptionController.text.trim();

                String? newReceiptUrl = _existingReceiptUrl;

                if (_selectedReceiptImage != null) {
                  newReceiptUrl = await SupabaseStorageService().uploadFileToSupabase(_selectedReceiptImage!);
                }

                final vm = context.read<TransactionViewModel>();

                await vm.updateTransaction(
                  id: widget.transaction.id!,
                  amount: amount,
                  description: description,
                  category: _category,
                  receiptUrl: newReceiptUrl,
                  date: Timestamp.fromDate(_selectedDate),
                  type: _type,
                );

                Navigator.pop(context);
              },
              child: Text("Save Changes"),
            ),
            ElevatedButton(
              onPressed: () async {
                final vm = context.read<TransactionViewModel>();
                bool confirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Transaction?'),
                    content: Text('Are you sure you want to delete this transaction?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
                    ],
                  ),
                );

                if (confirmed) {
                  await vm.deleteTransaction(widget.transaction.id!);
                  Navigator.pop(context); // go back after deletion
                }
              },
              child: Text("Delete Transaction"),
            ),
          ],
        ),
      ),
    );
  }
}
