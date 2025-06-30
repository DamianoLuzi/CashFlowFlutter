import 'package:flutter/material.dart';
import 'package:flutterapp/screens/add_transaction.dart';
import 'package:flutterapp/repository/auth_service.dart';
import 'package:flutterapp/screens/misc.dart';
import 'package:flutterapp/screens/transactions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';



// Enum to define the items in the bottom navigation bar
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
  int _selectedIndex = 0; // Tracks the currently selected tab index

  // List of widgets (screens) corresponding to each navigation bar item
  // We use PageStorageKey to maintain scroll position and state for each page
  // when navigating between tabs.
  static final List<Widget> _widgetOptions = <Widget>[
    const OverviewScreen(key: PageStorageKey('overviewScreen')),
    const AddTransactionScreen(key: PageStorageKey('addTransactionScreen')),
    //const TransactionListScreen(key: PageStorageKey('transactionListScreen')),
    TransactionsScreen(),
    const ProfileScreen(key: PageStorageKey('profileScreen')),
  ];

  // Controller for page view to allow programmatic page changes if needed
  final PageController _pageController = PageController();

  // Callback for when a bottom navigation bar item is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Animate to the selected page
    _pageController.jumpToPage(index);
  }

  // Example logout function (you might integrate this into your ProfileScreen)
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
          // Example: Logout button in AppBar, could be in Profile screen too
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
        children: _widgetOptions, // Disables horizontal swipe
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