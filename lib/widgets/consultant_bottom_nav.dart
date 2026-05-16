// Replace your existing consultant_bottom_nav.dart with this:

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
 
class ConsultantBottomNav extends StatelessWidget {
  final int currentIndex;
  const ConsultantBottomNav({super.key, required this.currentIndex});
 
  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    const routes = [
      '/consultant-dashboard',
      '/patient-consultation',
      '/emergency',
      '/consultant-profile',   // ← was missing
    ];
    if (index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) => _onTap(context, i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.black38,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Patients'),
        BottomNavigationBarItem(icon: Icon(Icons.emergency_outlined), label: 'Emergency'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

 