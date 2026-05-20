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
    
    // Fallback colors for slices
    final sliceColors = [
      colors.accentPrimary,
      colors.accentSecondary,
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
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 32,
          startDegreeOffset: -90,
          sections: List.generate(assets.length, (index) {
            final asset = assets[index];
            final color = sliceColors[index % sliceColors.length];
            final textColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                ? Colors.white
                : Colors.black87;

            return PieChartSectionData(
              color: color,
              value: asset.displayAllocationPercent,
              title: '${asset.displayAllocationPercent.toStringAsFixed(0)}%',
              radius: 28,
              titleStyle: AppTheme.caption(context, textColor).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
              ),
              badgeWidget: null,
            );
          }),
        ),
      ),
    );
  }
}

class RiskGauge extends StatelessWidget {
  final double riskScore; // 0 to 100
  final String riskLabel;

  const RiskGauge({
    super.key,
    required this.riskScore,
    required this.riskLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    
    Color getRiskColor() {
      if (riskScore < 35) return colors.accentSuccess;
      if (riskScore < 70) return colors.accentWarning;
      return colors.accentDanger;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 100,
            width: 180,
            child: CustomPaint(
              painter: _RiskGaugePainter(
                score: riskScore,
                trackColor: colors.borderColor,
                successColor: colors.accentSuccess,
                warningColor: colors.accentWarning,
                dangerColor: colors.accentDanger,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${riskScore.toStringAsFixed(0)} / 100',
            style: AppTheme.headingMd(context, colors.textPrimary).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            riskLabel.toUpperCase(),
            style: AppTheme.caption(context, getRiskColor()).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
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
    
    final paintTrack = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw background track arc (semi circle: 180 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      paintTrack,
    );

    // Color shift based on value
    double sweepAngle = (score / 100) * pi;
    if (score < 35) {
      paintFill.color = successColor;
    } else if (score < 70) {
      paintFill.color = warningColor;
    } else {
      paintFill.color = dangerColor;
    }

    // Draw active arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      paintFill,
    );

    // Draw indicator needle line
    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    double needleAngle = pi + sweepAngle;
    double needleLength = radius - 8;
    Offset needleTarget = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );
    canvas.drawLine(center, needleTarget, needlePaint);

    // Draw center hub pin
    final hubPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, hubPaint);
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

// A simple custom painted sparkline chart for analytics
class SparklineChart extends StatelessWidget {
  final List<double> data;
  final bool isPositive;

  const SparklineChart({super.key, required this.data, this.isPositive = true});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final lineColor = isPositive ? colors.accentSuccess : colors.accentDanger;

    return Container(
      height: 48,
      width: 100,
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
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double minVal = data.reduce(min);
    double maxVal = data.reduce(max);
    double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      // Invert Y coordinates since Flutter starts at 0,0 top-left
      double y = size.height - ((data[i] - minVal) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

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
      colors.accentWarning,
      colors.accentSuccess,
    ];

    return Column(
      children: List.generate(data.keys.length, (index) {
        final key = data.keys.elementAt(index);
        final value = data[key] ?? 0;
        final ratio = value / maxVal;
        final color = barColors[index % barColors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  key,
                  style: AppTheme.caption(context, colors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 12,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: colors.borderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 24,
                child: Text(
                  '$value',
                  textAlign: TextAlign.right,
                  style: AppTheme.monoSm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
