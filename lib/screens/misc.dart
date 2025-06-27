import 'package:flutter/material.dart';
import 'package:flutterapp/repository/auth_service.dart';
import 'package:provider/provider.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({Key? key}) : super(key: key);

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

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder list of transactions
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10, // Replace with your transaction count
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.money),
            title: Text('Transaction #$index'),
            subtitle: Text('Description here'),
            trailing: Text('-\$${(index + 1) * 10}'),
          ),
        );
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder profile info with logout button
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.account_circle, size: 100),
          ),
          const SizedBox(height: 24),
          Text(
            'User Name',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'user@example.com',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Call logout from AuthService or show confirmation
              final authService = Provider.of<AuthService>(context, listen: false);
              authService.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out')),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
