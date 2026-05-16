import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StudentBottomNav extends StatelessWidget {
  final int currentIndex;
  const StudentBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    const routes = ['/student-dashboard', '/analysis', '/zen', '/profile'];
    final route = routes[index];
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_outlined, label: 'Home', index: 0, current: currentIndex, onTap: (i) => _onTap(context, i)),
            _NavItem(icon: Icons.bar_chart_outlined, label: 'Analysis', index: 1, current: currentIndex, onTap: (i) => _onTap(context, i)),
            const SizedBox(width: 48),
            _NavItem(icon: Icons.self_improvement_outlined, label: 'Zen', index: 2, current: currentIndex, onTap: (i) => _onTap(context, i)),
            _NavItem(icon: Icons.person_outline, label: 'Profile', index: 3, current: currentIndex, onTap: (i) => _onTap(context, i)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? AppColors.primary : Colors.black38),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.primary : Colors.black38,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}