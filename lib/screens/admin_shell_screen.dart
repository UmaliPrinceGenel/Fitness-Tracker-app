import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_community_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_custom_workout_screen.dart';

class AdminShellScreen extends StatefulWidget {
  final int initialIndex;
  const AdminShellScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    
    // Exactly matches the duration and curve used in the Customer UI PageView transition
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 800;

    if (isWeb && isLargeScreen) {
      // On web large layout, return the pages directly to preserve their individual sidebar structures
      if (_currentIndex == 0) return const AdminDashboardScreen();
      if (_currentIndex == 1) return const AdminUsersScreen();
      if (_currentIndex == 2) return const AdminCommunityScreen();
      if (_currentIndex == 3) return const AdminFeedbackScreen();
      return const AdminCustomWorkoutScreen();
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Match Customer UI navigation style
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          AdminDashboardScreen(isInsideShell: true),
          AdminUsersScreen(isInsideShell: true),
          AdminCommunityScreen(isInsideShell: true),
          AdminFeedbackScreen(isInsideShell: true),
          AdminCustomWorkoutScreen(isInsideShell: true),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}
