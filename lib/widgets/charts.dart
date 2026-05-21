import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../models/portfolio.dart';

class PortfolioPieChart extends StatelessWidget {
  final List<AssetRow> assets;

  const PortfolioPieChart({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    
    // Fallback colors for slices - premium high-fidelity palette
    final sliceColors = [
      colors.accentPrimary,
      colors.accentSecondary,
      colors.accentSuccess,
      colors.accentWarning,
      colors.accentDanger,
    ];

    if (assets.isEmpty) {
      return Center(
        child: Text(
          'No portfolio data available.',
          style: AppTheme.bodySm(context, colors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sectionsSpace: 6,
          centerSpaceRadius: 55,
          startDegreeOffset: -90,
          sections: List.generate(assets.length, (index) {
            final asset = assets[index];
            final color = sliceColors[index % sliceColors.length];
            final isDarkText = ThemeData.estimateBrightnessForColor(color) == Brightness.light;
            final textColor = isDarkText ? const Color(0xFF0A0E1A) : Colors.white;

            return PieChartSectionData(
              color: color,
              value: asset.displayAllocationPercent,
              title: '${asset.displayAllocationPercent.toStringAsFixed(0)}%',
              radius: 45,
              titleStyle: AppTheme.caption(context, textColor).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              badgeWidget: null,
            );
          }),
        ),
      ),
    );
  }
}

class RiskGauge extends StatefulWidget {
  final double riskScore; // 0 to 100
  final String riskLabel;

  const RiskGauge({
    super.key,
    required this.riskScore,
    required this.riskLabel,
  });

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: widget.riskScore).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riskScore != widget.riskScore) {
      _animation = Tween<double>(begin: oldWidget.riskScore, end: widget.riskScore).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    
    Color getRiskColor() {
      if (widget.riskScore < 35) return colors.accentSuccess;
      if (widget.riskScore < 70) return colors.accentWarning;
      return colors.accentDanger;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value;
        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 105,
                width: 190,
                child: CustomPaint(
                  painter: _RiskGaugePainter(
                    score: currentScore,
                    trackColor: colors.borderColor.withOpacity(0.15),
                    successColor: colors.accentSuccess,
                    warningColor: colors.accentWarning,
                    dangerColor: colors.accentDanger,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.riskScore.toStringAsFixed(0)} / 100',
                style: AppTheme.displayXl(context, colors.textPrimary).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getRiskColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: getRiskColor().withOpacity(0.3), width: 1),
                ),
                child: Text(
                  widget.riskLabel.toUpperCase(),
                  style: AppTheme.caption(context, getRiskColor()).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RiskGaugePainter extends CustomPainter {
  final double score;
  final Color trackColor;
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;

  _RiskGaugePainter({
    required this.score,
    required this.trackColor,
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final paintTrack = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw background track arc (semi circle: 180 degrees)
    canvas.drawArc(rect, pi, pi, false, paintTrack);

    double sweepAngle = (score / 100).clamp(0.0, 1.0) * pi;

    final fillGradient = SweepGradient(
      colors: [
        successColor,
        warningColor,
        dangerColor,
      ],
      stops: const [0.0, 0.5, 1.0],
      startAngle: pi,
      endAngle: 2 * pi,
    );

    // Draw fill arc (no glow)
    if (sweepAngle > 0.05) {
      final paintFill = Paint()
        ..shader = fillGradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, pi, sweepAngle, false, paintFill);
    }

    // Determine color at current pointer for needle
    Color currentNeedleColor = successColor;
    if (score >= 70) {
      currentNeedleColor = dangerColor;
    } else if (score >= 35) {
      currentNeedleColor = warningColor;
    }

    // Draw indicator needle line (clean, no glow)
    double needleAngle = pi + sweepAngle;
    double needleLength = radius - 4;
    Offset needleTarget = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleTarget, needlePaint);

    // Draw center hub pin (clean, no glow)
    final hubOuter = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, hubOuter);

    final hubInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, hubInner);
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

// A highly polished, custom painted cubic Bezier area sparkline chart for analytics
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final bool isPositive;

  const SparklineChart({super.key, required this.data, this.isPositive = true});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final lineColor = isPositive ? colors.accentSuccess : colors.accentDanger;

    return Container(
      height: 52,
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: lineColor),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();
    
    double minVal = data.reduce(min);
    double maxVal = data.reduce(max);
    double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    double stepX = size.width / (data.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double y = size.height - ((data[i] - minVal) / range * size.height);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      
      // Interpolate with a smooth cubic bezier S-curve
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
      
      fillPath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }
    
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Draw background gradient fill under line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.data != data;
}

// A simple custom painted horizontal bar chart for breakdowns
class SimpleBarChart extends StatelessWidget {
  final Map<String, int> data;

  const SimpleBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    if (data.isEmpty) return const SizedBox();

    int maxVal = data.values.reduce(max);
    if (maxVal == 0) maxVal = 1;

    final barColors = [
      colors.accentPrimary,
      colors.accentSecondary,
      colors.accentSuccess,
      colors.accentWarning,
    ];

    return Column(
      children: List.generate(data.keys.length, (index) {
        final key = data.keys.elementAt(index);
        final value = data[key] ?? 0;
        final ratio = value / maxVal;
        final color = barColors[index % barColors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 85,
                child: Text(
                  key,
                  style: AppTheme.caption(context, colors.textSecondary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 12,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: colors.borderColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.borderColor.withOpacity(0.2), width: 1),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.75)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: -1,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 28,
                child: Text(
                  '$value',
                  textAlign: TextAlign.right,
                  style: AppTheme.monoSm(context, colors.textPrimary).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
