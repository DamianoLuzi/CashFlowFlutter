import 'package:flutter/material.dart';
import 'package:flutterapp/models/category.dart';
import 'package:flutterapp/viewmodels/category_view_model.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatelessWidget {
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
    final _nameController = TextEditingController();
    final _iconController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Custom Category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: _iconController, decoration: InputDecoration(labelText: "Icon (emoji)")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final icon = _iconController.text.trim();
              if (name.isNotEmpty && icon.isNotEmpty) {
                final vm = context.read<CategoryViewModel>();
                vm.addCustomCategory(Category(name: name, icon: icon));
                Navigator.pop(ctx);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }
}
