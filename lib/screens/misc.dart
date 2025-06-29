import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutterapp/viewmodels/profile_view_model.dart';
import 'package:flutterapp/viewmodels/budget_view_model.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder overview content
    return Center(
      child: Text(
        'Overview Screen',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => BudgetViewModel()), // For budget list
      ],
      child: Consumer2<ProfileViewModel, BudgetViewModel>(
        builder: (context, profileVM, budgetVM, _) {
          final budgets = budgetVM.budgets;

          return Scaffold(
            appBar: AppBar(title: Text("Profile")),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.account_circle, size: 100),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(profileVM.userName, style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(profileVM.userEmail, style: Theme.of(context).textTheme.bodyLarge),
                  ),
                  const SizedBox(height: 32),
                  SwitchListTile(
                    value: profileVM.preferences.overBudgetAlerts,
                    title: Text("Over-Budget Alerts"),
                    onChanged: profileVM.toggleOverBudgetAlerts,
                  ),
                  SwitchListTile(
                    value: profileVM.preferences.spendingSummary,
                    title: Text("Spending Summary Notifications"),
                    onChanged: (enabled) {
                      profileVM.toggleSpendingSummary(enabled); // You'll add this method below
                    },
                  ),
                  const SizedBox(height: 24),
                  Text("Your Budgets", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (budgets.isEmpty)
                    Text("No budgets set", style: TextStyle(color: Colors.grey)),
                  ...budgets.map((b) => ListTile(
                        title: Text(b.category),
                        trailing: Text("€${b.amount.toStringAsFixed(2)}"),
                      )),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await profileVM.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out')),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
