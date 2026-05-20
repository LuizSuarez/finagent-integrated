import 'package:flutter/material.dart';
import '../core/theme.dart';

class AgentStatusDot extends StatefulWidget {
  final String status; // active (green), thinking (amber), error (red), waiting (grey)
  final double size;

  const AgentStatusDot({
    super.key,
    required this.status,
    this.size = 10,
  });

  @override
  State<AgentStatusDot> createState() => _AgentStatusDotState();
}

class _AgentStatusDotState extends State<AgentStatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor(AppThemeColors colors) {
    switch (widget.status) {
      case 'active':
      case 'done':
        return colors.accentSuccess;
      case 'thinking':
      case 'running':
        return colors.accentWarning;
      case 'error':
        return colors.accentDanger;
      case 'waiting':
      default:
        return colors.textSecondary.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final dotColor = _getStatusColor(colors);

    if (widget.status == 'waiting') {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 2,
              height: widget.size * 2,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.3 * _animation.value),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withOpacity(0.6),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const ProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        width: double.infinity,
        color: colors.borderColor,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
          builder: (context, animatedProgress, child) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: animatedProgress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accentPrimary, colors.accentSecondary],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CustomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withOpacity(0.15) : colors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderColor,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.caption(context, isSelected ? colors.accentPrimary : colors.textSecondary).copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 4,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gradientPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _gradientPosition = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_gradientPosition.value - 1.0, -0.3),
              end: Alignment(_gradientPosition.value, 0.3),
              colors: [
                colors.bgElevated,
                colors.bgElevated.withOpacity(0.4),
                colors.bgElevated,
              ],
            ),
          ),
        );
      },
    );
  }
}

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Divider(
      color: colors.borderColor,
      thickness: 1,
      height: 24,
    );
  }
}

class ToastService {
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, AppTheme.of(context).accentSuccess, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, AppTheme.of(context).accentDanger, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, AppTheme.of(context).accentPrimary, Icons.info_outline);
  }

  static void _showToast(BuildContext context, String message, Color accent, IconData icon) {
    final colors = AppTheme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: colors.bgElevated,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.borderColor, width: 1),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
