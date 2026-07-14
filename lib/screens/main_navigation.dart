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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
        switchOutCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentPageIndex),
          child: _pages[_currentPageIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _pageToNavIndex(_currentPageIndex),
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primaryGreenDark,
          unselectedItemColor: AppColors.textGray.withValues(alpha: 0.8),
          backgroundColor: Colors.transparent,
          elevation: 0,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11.5,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Icon(Icons.home_rounded, size: 26),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner_outlined, size: 24),
              activeIcon: Icon(Icons.document_scanner_rounded, size: 26),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded, size: 24),
              activeIcon: Icon(Icons.history_rounded, size: 26),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 24),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
