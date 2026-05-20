import 'package:flutter/material.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 5;
              final sliderWidth = 32.0;
              final leftOffset = (currentIndex * tabWidth) + (tabWidth / 2) - (sliderWidth / 2);
              
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    left: leftOffset,
                    child: Container(
                      height: 3,
                      width: sliderWidth,
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accentPrimary.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(context, index: 0, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', width: tabWidth),
                      _buildNavItem(context, index: 1, icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Input', width: tabWidth),
                      _buildNavItem(context, index: 2, icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: 'Agents', width: tabWidth),
                      _buildNavItem(context, index: 3, icon: Icons.insights_outlined, activeIcon: Icons.insights, label: 'Simulate', width: tabWidth),
                      _buildNavItem(context, index: 4, icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Analytics', width: tabWidth),
                    ],
                  ),
                ],
              );
            },
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
    required double width,
  }) {
    final colors = AppTheme.of(context);
    final isSelected = currentIndex == index;
    final activeColor = colors.accentPrimary;
    final inactiveColor = colors.textSecondary.withOpacity(0.7);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 9), // Replaces indicator height + spacing
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.caption(context, isSelected ? activeColor : inactiveColor).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
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
