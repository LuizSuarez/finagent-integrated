import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import '../widgets/buttons.dart';

class StatesGalleryScreen extends StatefulWidget {
  const StatesGalleryScreen({super.key});

  @override
  State<StatesGalleryScreen> createState() => _StatesGalleryScreenState();
}

class _StatesGalleryScreenState extends State<StatesGalleryScreen> {
  int _activeState = 0; // 0=Loading/Skeletons, 1=Empty Feed, 2=System Error

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'UX STATES GALLERY',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Preview Toggle buttons
            _buildStateToggleRow(context),
            const SizedBox(height: 24),

            // Preview Container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderColor),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildActivePreview(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateToggleRow(BuildContext context) {
    final colors = AppTheme.of(context);
    final labels = ['LOADING SHIMMER', 'EMPTY MATRIX', 'SYSTEM ERROR'];

    return Row(
      children: List.generate(3, (index) {
        final isSel = _activeState == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _activeState = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == 2 ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? colors.bgElevated : colors.bgSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSel ? colors.accentPrimary : colors.borderColor,
                  width: 1.2,
                ),
              ),
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: AppTheme.caption(context, isSel ? colors.accentPrimary : colors.textSecondary).copyWith(
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActivePreview(BuildContext context) {
    final colors = AppTheme.of(context);

    switch (_activeState) {
      case 0: // Loading skeletons
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIMULATED SHIMMER LOADING',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Skeleton(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 120, height: 14),
                      SizedBox(height: 6),
                      Skeleton(width: double.infinity, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 80, height: 12),
                  SizedBox(height: 12),
                  Skeleton(width: double.infinity, height: 18),
                  SizedBox(height: 8),
                  Skeleton(width: double.infinity, height: 40),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Skeleton(width: 90, height: 12),
                      Skeleton(width: 70, height: 12),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Uses dynamic shimmering linear gradients.',
                style: AppTheme.caption(context, colors.textSecondary),
              ),
            ),
          ],
        );

      case 1: // Empty Feed
        return Column(
          key: const ValueKey(1),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom painted vector empty box
            SizedBox(
              height: 120,
              width: 120,
              child: CustomPaint(
                painter: _EmptyStateGraphicPainter(
                  color: colors.textSecondary.withOpacity(0.3),
                  accent: colors.accentSecondary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'DECISION ENGINE DECK EMPTY',
              style: AppTheme.headingMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'No insights generated in this pipeline instance. Run the agent matrix against files to populate statistics.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySm(context, colors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'INGEST NEW DATA',
              onPressed: () {
                Navigator.of(context).pop(); // Back to settings
              },
            ),
          ],
        );

      case 2: // System Connection Error Banner
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIMULATED INTERRUPT EXCEPTION',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Connection Alert Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.accentDanger.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.accentDanger),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: colors.accentDanger, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEBSOCKET CONNECTION FAILURE',
                          style: AppTheme.bodySm(context, colors.accentDanger).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pipeline stream links were interrupted. Falling back to secure local sandbox data caching...',
                          style: AppTheme.caption(context, colors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomCard(
              backgroundColor: colors.bgElevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Cache Baseline',
                    style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stored operational snapshots are fully available offline. Subsystems will synchronize automatically upon connection restore.',
                    style: AppTheme.bodySm(context, colors.textSecondary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: PrimaryButton(
                text: 'RETRY CONNECTION',
                onPressed: () {
                  ToastService.showInfo(context, 'Pinging websocket server gate...');
                },
              ),
            )
          ],
        );
      default:
        return const SizedBox();
    }
  }
}

class _EmptyStateGraphicPainter extends CustomPainter {
  final Color color;
  final Color accent;

  _EmptyStateGraphicPainter({required this.color, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintAccent = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw cube nodes representing empty container
    final path = Path()
      ..moveTo(center.dx - 30, center.dy - 20)
      ..lineTo(center.dx + 30, center.dy - 20)
      ..lineTo(center.dx + 40, center.dy + 20)
      ..lineTo(center.dx - 40, center.dy + 20)
      ..close();
    canvas.drawPath(path, paint);

    // Draw dotted items fading out
    canvas.drawCircle(center, 4, paintAccent);
    canvas.drawCircle(Offset(center.dx - 20, center.dy + 5), 2, paint);
    canvas.drawCircle(Offset(center.dx + 20, center.dy + 5), 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
