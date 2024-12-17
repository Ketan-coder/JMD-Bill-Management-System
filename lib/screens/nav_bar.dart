import 'package:flutter/material.dart';
import 'package:kenan/screens/home_page.dart';
import 'package:kenan/screens/settings_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const HomePage(),
    // const InventoryPage(),
    // const DashboardPage(),
    const SettingsPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _tabs[_currentIndex],
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          selectedFontSize: 15,
          // unselectedFontSize: 20,
          selectedIconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          unselectedItemColor: Colors.grey.shade600,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          enableFeedback: true,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.paste), label: 'Bills'),
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.inventory_2), label: 'Inventory'),
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.analytics), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Settings'),
          ]),
    );
  }
}
