import 'package:flutter/material.dart';
import 'package:flutterapp/models/category.dart';
import 'package:flutterapp/viewmodels/category_view_model.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryViewModel(),
      child: Scaffold(
        appBar: AppBar(title: Text("Categories")),
        body: Consumer<CategoryViewModel>(
          builder: (context, vm, _) {
            final categories = vm.getAllCategoriesForDisplay();
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: Text(category.icon! , style: TextStyle(fontSize: 24)),
                  title: Text(category.name),
                  trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteCategory(context, category, vm), // Pass vm
                            ),
                          ],
                        )
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => _showAddCategoryDialog(context),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final iconController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Custom Category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: iconController, decoration: InputDecoration(labelText: "Icon (emoji)")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final icon = iconController.text.trim();
              if (name.isNotEmpty && icon.isNotEmpty) {
                final vm = context.read<CategoryViewModel>();
                vm.addCustomCategory(Category( name: name,icon: icon));
                Navigator.pop(ctx);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, Category category, CategoryViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete the category '${category.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (category.id != null) { // Ensure ID exists for deletion
                vm.deleteCategory(category.id!);
              } else {
                // This case ideally shouldn't happen for custom categories if ID is set on creation
                print("Error: Attempted to delete a custom category without an ID.");
              }
              Navigator.pop(ctx); // Close dialog
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
