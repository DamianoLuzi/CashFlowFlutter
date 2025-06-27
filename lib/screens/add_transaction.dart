import 'package:flutter/material.dart';
import 'package:flutterapp/models/category.dart';
import 'package:flutterapp/models/transaction.dart';
import 'package:flutterapp/repository/supabase_service.dart';
import 'package:flutterapp/viewmodels/category_view_model.dart';
import 'package:flutterapp/viewmodels/transaction_view_model.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';


class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  TransactionType _transactionType = TransactionType.EXPENSE;
  XFile? _selectedReceiptImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedReceiptImage = image;
    });
  }

  void _saveTransaction() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty || _selectedCategory == null) {
      return;
    }

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? receiptUrl;
    if (_selectedReceiptImage != null) {
      receiptUrl = await SupabaseStorageService().uploadFileToSupabase(_selectedReceiptImage!);
    }

    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    await transactionViewModel.addTransaction(
      amount: amount,
      description: _descriptionController.text,
      category: _selectedCategory!,
      type: _transactionType,
      receiptUrl: receiptUrl,
    );

    setState(() {
      _isSubmitting = false;
    });
    if (mounted) {
      Navigator.pop(context); // Go back after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryViewModel = Provider.of<CategoryViewModel>(context);
    final allCategories = categoryViewModel.getAllCategoriesForDisplay();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Transaction"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: TransactionType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: _transactionType == type,
                    label: Text(type.name.toLowerCase().replaceFirst(type.name[0], type.name[0].toUpperCase())),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _transactionType = type;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text("Select Category"),
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              items: allCategories.map<DropdownMenuItem<String>>((Category category) {
                return DropdownMenuItem<String>(
                  value: category.name,
                  child: Row(
                    children: [
                      Text(category.icon ?? ""),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Custom Category"),
                onPressed: () {
                  Navigator.pushNamed(context, '/addcategory'); // Implement this route
                },
              ),
            ),
            const SizedBox(height: 16),
            Text("Receipt (optional)"),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Select Receipt Image"),
            ),
            if (_selectedReceiptImage != null)
              Text("Selected: ${_selectedReceiptImage!.name}"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveTransaction,
                child: _isSubmitting
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}