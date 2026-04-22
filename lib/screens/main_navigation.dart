import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/screens/home_screen.dart';
import 'package:skincare_analyzer_app/screens/history_screen.dart';
import 'package:skincare_analyzer_app/screens/profile_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  List<Widget> get _pages => [
    HomeScreen(
      onNavigateToHistory: () {
        setState(() {
          _currentPageIndex = 1; // History page index
        });
      },
    ),
    const HistoryScreen(),
    ProfileScreen(
      onNavigateToHistory: () {
        setState(() {
          _currentPageIndex = 1; // History page index
        });
      },
    ),
  ];

  // Map nav bar index to _pages index (skip index 1 which is Scan)
  int _navToPageIndex(int navIndex) {
    if (navIndex == 0) return 0; // Home
    if (navIndex == 2) return 1; // History
    if (navIndex == 3) return 2; // Profile
    return 0;
  }

  int _pageToNavIndex(int pageIndex) {
    if (pageIndex == 0) return 0; // Home
    if (pageIndex == 1) return 2; // History
    if (pageIndex == 2) return 3; // Profile
    return 0;
  }

  int _currentPageIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) {
      // Scan tab → navigate to ScanScreen
      Navigator.pushNamed(context, '/scan');
      return;
    }
    setState(() {
      _currentPageIndex = _navToPageIndex(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _pageToNavIndex(_currentPageIndex),
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textGray,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            activeIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
