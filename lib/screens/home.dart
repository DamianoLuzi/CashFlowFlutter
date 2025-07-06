import 'package:flutter/material.dart';
import 'package:flutterapp/screens/add_transaction.dart';
import 'package:flutterapp/repository/auth_service.dart';
import 'package:flutterapp/screens/misc.dart';
import 'package:flutterapp/screens/transactions.dart';
import 'package:flutterapp/screens/dashboard_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';


enum BottomNavItem {
  overview('overview', 'Overview', Icons.home),
  add('addtransaction', 'Add', Icons.add_circle),
  transactions('transactionlist', 'Transactions', Icons.list),
  profile('profile', 'Account', Icons.account_circle);

  const BottomNavItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(key: PageStorageKey('dashboardScreen')),
    const AddTransactionScreen(key: PageStorageKey('addTransactionScreen')),
    TransactionsScreen(),
    const ProfileScreen(key: PageStorageKey('profileScreen')),
  ];
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }


  void _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    Fluttertoast.showToast(msg: "Logged out successfully!");
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(BottomNavItem.values[_selectedIndex].label),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: BottomNavItem.values.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}