import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0, top: 4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: colors.bgSurface.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.borderColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: colors.glowColor.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, index: 0, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
                  _buildNavItem(context, index: 1, icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Input'),
                  _buildNavItem(context, index: 2, icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: 'Agents'),
                  _buildNavItem(context, index: 3, icon: Icons.insights_outlined, activeIcon: Icons.insights, label: 'Simulate'),
                  _buildNavItem(context, index: 4, icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Analytics'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final colors = AppTheme.of(context);
    final isSelected = currentIndex == index;
    final activeColor = colors.accentPrimary;
    final inactiveColor = colors.textSecondary.withOpacity(0.7);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withOpacity(0.12) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.accentPrimary.withOpacity(0.3) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.glowColor.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ).animate(target: isSelected ? 1 : 0)
               .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 250.ms, curve: Curves.easeOutBack)
               .then()
               .shake(hz: 2, duration: 150.ms),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.caption(context, isSelected ? activeColor : inactiveColor).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
