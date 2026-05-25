import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 14, right: 14, bottom: 25),
        decoration: BoxDecoration(
          color: const Color(0xFF161618).withOpacity(0.7),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.03),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Colors.orange,
                  unselectedItemColor: Colors.white54,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    height: 1.4,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                  currentIndex: currentIndex,
                  onTap: onTap,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.dashboard_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.dashboard),
                      ),
                      label: 'Overview',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.people_outline),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.people),
                      ),
                      label: 'Users',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.forum_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.forum),
                      ),
                      label: 'Community',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.rate_review_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.rate_review),
                      ),
                      label: 'Feedback',
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.fitness_center_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Icon(Icons.fitness_center),
                      ),
                      label: 'Workout',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
