import 'package:flutter/material.dart';

class BottomNavItem {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  BottomNavItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
}

class CustomBottomNavigation extends StatelessWidget {
  final List<BottomNavItem> navItems;

  const CustomBottomNavigation({super.key, required this.navItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFFFDC16),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 80,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: navItems.map((item) => _buildNavItem(item)).toList(),
      ),
    );
  }

  Widget _buildNavItem(BottomNavItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.isSelected)
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF4E342E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFFFFDC16),
                size: 20,
              ),
            )
          else
            Icon(
              item.icon,
              color: const Color(0xFF1A1A1A),
              size: 20,
            ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: TextStyle(
              color: const Color(0xFF1A1A1A),
              fontSize: item.isSelected ? 13 : 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
