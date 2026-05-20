import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Auto navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: Stack(
        children: [
          // Background grid decor elements
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridPaper(
                color: colors.accentPrimary,
                divisions: 1,
                subdivisions: 1,
                interval: 40,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Breathing Glow Ring + Logo
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.accentPrimary.withOpacity(0.12 * _pulseAnimation.value),
                            blurRadius: 50 * _pulseAnimation.value,
                            spreadRadius: 10 * _pulseAnimation.value,
                          )
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circuit Logo icon
                      Icon(
                        Icons.settings_input_component,
                        color: colors.accentPrimary,
                        size: 72,
                      ),
                      const SizedBox(height: 16),
                      // FinAgent Display text
                      Text(
                        AppConstants.appName.toUpperCase(),
                        style: AppTheme.displayXl(context, colors.textPrimary).copyWith(
                          letterSpacing: 6.0,
                          shadows: [
                            Shadow(
                              color: colors.accentPrimary.withOpacity(0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Tagline text
                Text(
                  AppConstants.appTagline,
                  style: AppTheme.caption(context, colors.textSecondary).copyWith(
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          // Lower indicator text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: colors.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'INITIALIZING SECURE LINK...',
                    style: AppTheme.caption(context, colors.textSecondary.withOpacity(0.5)).copyWith(
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
