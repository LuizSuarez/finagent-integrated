import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/buttons.dart';
import 'main_shell.dart'; // Navigation container for dashboard

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Ingest Any Content',
      subtitle: 'Upload news documents, PDF reports, web URLs, or paste raw unstructured text directly into the agent pipelines.',
      type: OnboardingGraphicType.ingest,
    ),
    OnboardingSlideData(
      title: 'AI Agents Do The Thinking',
      subtitle: 'Eight specialized intelligence agents process content in sequence to extract facts, check risks, and formulate actions.',
      type: OnboardingGraphicType.agents,
    ),
    OnboardingSlideData(
      title: 'Watch Actions Execute',
      subtitle: 'Simulate recommended action scripts inside secure sandbox environments and see before/after system state changes.',
      type: OnboardingGraphicType.simulate,
    ),
  ];

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastPage)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: GhostButton(
                text: 'SKIP',
                onPressed: _finishOnboarding,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Vector Graphic Area
                      Container(
                        height: 220,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 40),
                        child: CustomPaint(
                          painter: _OnboardingGraphicPainter(
                            type: slide.type,
                            primaryColor: colors.accentPrimary,
                            secondaryColor: colors.accentSecondary,
                            borderColor: colors.borderColor,
                            textColor: colors.textPrimary,
                          ),
                        ),
                      ),
                      // Slide Title
                      Text(
                        slide.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppTheme.headingLg(context, colors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      // Slide Subtitle
                      Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMd(context, colors.textSecondary).copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Pagination Indicator & CTA Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pagination Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final isSelected = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isSelected ? 24 : 8,
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                // Buttons
                if (isLastPage)
                  PrimaryButton(
                    text: 'GET STARTED',
                    width: double.infinity,
                    onPressed: _finishOnboarding,
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous button (hidden on first page)
                      if (_currentPage > 0)
                        SecondaryButton(
                          text: 'BACK',
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        )
                      else
                        const SizedBox(width: 80),
                      // Next button
                      PrimaryButton(
                        text: 'NEXT',
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum OnboardingGraphicType { ingest, agents, simulate }

class OnboardingSlideData {
  final String title;
  final String subtitle;
  final OnboardingGraphicType type;

  OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

// Vector painters for slides
class _OnboardingGraphicPainter extends CustomPainter {
  final OnboardingGraphicType type;
  final Color primaryColor;
  final Color secondaryColor;
  final Color borderColor;
  final Color textColor;

  _OnboardingGraphicPainter({
    required this.type,
    required this.primaryColor,
    required this.secondaryColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case OnboardingGraphicType.ingest:
        _paintIngest(canvas, size);
        break;
      case OnboardingGraphicType.agents:
        _paintAgents(canvas, size);
        break;
      case OnboardingGraphicType.simulate:
        _paintSimulate(canvas, size);
        break;
    }
  }

  void _paintIngest(Canvas canvas, Size size) {
    // Paints a central digital scanner/ingest funnel
    final center = Offset(size.width / 2, size.height / 2);
    final paintLine = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintAccent = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw document shape
    final docRect = Rect.fromCenter(center: Offset(center.dx, center.dy - 30), width: 70, height: 90);
    canvas.drawRect(docRect, paintLine);
    
    // Draw doc lines
    for (int i = 0; i < 4; i++) {
      double y = docRect.top + 20 + i * 16;
      canvas.drawLine(
        Offset(docRect.left + 12, y),
        Offset(docRect.right - 12, y),
        paintLine,
      );
    }

    // Draw arrows flowing downwards to database node
    final dbCenter = Offset(center.dx, center.dy + 60);
    canvas.drawCircle(dbCenter, 20, paintAccent);
    canvas.drawCircle(dbCenter, 28, paintLine..color = secondaryColor.withOpacity(0.5));

    // Downward connecting lines
    canvas.drawLine(
      Offset(center.dx, docRect.bottom + 10),
      Offset(center.dx, dbCenter.dy - 28),
      paintAccent..color = primaryColor,
    );

    // Arrowhead
    final path = Path()
      ..moveTo(center.dx - 5, dbCenter.dy - 35)
      ..lineTo(center.dx, dbCenter.dy - 28)
      ..lineTo(center.dx + 5, dbCenter.dy - 35);
    canvas.drawPath(path, paintAccent);
  }

  void _paintAgents(Canvas canvas, Size size) {
    // Paints a distributed neural/agent network
    final center = Offset(size.width / 2, size.height / 2);
    final paintLine = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintAgent = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final paintPrimary = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Center node (orchestrator)
    canvas.drawCircle(center, 16, paintPrimary);
    canvas.drawCircle(center, 24, Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill);

    // Peripheral nodes
    final nodeOffset = [
      const Offset(-70, -40),
      const Offset(70, -40),
      const Offset(-60, 50),
      const Offset(60, 50),
    ];

    for (var offset in nodeOffset) {
      final nodeCenter = center + offset;
      canvas.drawLine(center, nodeCenter, paintLine);
      canvas.drawCircle(nodeCenter, 10, paintAgent);
      canvas.drawCircle(nodeCenter, 14, Paint()
        ..color = secondaryColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);
    }
  }

  void _paintSimulate(Canvas canvas, Size size) {
    // Paints a dashboard slider comparing states side-by-side
    final center = Offset(size.width / 2, size.height / 2);
    final paintLine = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintGlow = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Left and Right sandbox panels
    final leftPanel = Rect.fromCenter(center: Offset(center.dx - 60, center.dy), width: 90, height: 100);
    final rightPanel = Rect.fromCenter(center: Offset(center.dx + 60, center.dy), width: 90, height: 100);

    canvas.drawRRect(RRect.fromRectAndRadius(leftPanel, const Radius.circular(8)), paintLine);
    canvas.drawRRect(RRect.fromRectAndRadius(rightPanel, const Radius.circular(8)), paintGlow);

    // State indicators (Bar graph inside panels)
    final leftBar = Rect.fromLTWH(leftPanel.left + 15, leftPanel.bottom - 40, 20, 30);
    final rightBar = Rect.fromLTWH(rightPanel.left + 15, rightPanel.bottom - 70, 20, 60);

    canvas.drawRect(leftBar, Paint()..color = secondaryColor.withOpacity(0.4));
    canvas.drawRect(rightBar, Paint()..color = primaryColor);

    // Arrow indicator between panels
    final arrowPath = Path()
      ..moveTo(center.dx - 10, center.dy - 10)
      ..lineTo(center.dx + 10, center.dy)
      ..lineTo(center.dx - 10, center.dy + 10);
    canvas.drawPath(arrowPath, paintLine..color = primaryColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
