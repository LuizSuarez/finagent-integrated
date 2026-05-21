import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../models/action_item.dart';
import '../services/api_service.dart';
import '../widgets/buttons.dart';
import 'main_shell.dart';

class ActionSimulationScreen extends StatefulWidget {
  final ActionItem action;

  const ActionSimulationScreen({super.key, required this.action});

  @override
  State<ActionSimulationScreen> createState() => _ActionSimulationScreenState();
}

class _ActionSimulationScreenState extends State<ActionSimulationScreen> {
  final ScrollController _logsScrollController = ScrollController();

  void _scrollToBottom() {
    if (_logsScrollController.hasClients) {
      _logsScrollController.animateTo(
        _logsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _logsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);

    final updatedAction = apiState.actions.firstWhere(
      (a) => a.id == widget.action.id,
      orElse: () => widget.action,
    );

    final isSimulated = updatedAction.displayStatus == 'simulated';
    final isRunning = apiState.isSimulationRunning;
    final isComplete = apiState.isSimulationComplete || isSimulated;

    if (isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary.withOpacity(0.7),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTION SANDBOX',
              style: AppTheme.headingMd(context, colors.textPrimary)
                  .copyWith(letterSpacing: 1.2, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              updatedAction.displayType.toUpperCase(),
              style: AppTheme.caption(context, colors.accentPrimary)
                  .copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 9),
            ),
          ],
        ),
        actions: [
          // Live status badge
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isComplete
                  ? colors.accentSuccess.withOpacity(0.12)
                  : isRunning
                      ? colors.accentWarning.withOpacity(0.12)
                      : colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isComplete
                    ? colors.accentSuccess.withOpacity(0.4)
                    : isRunning
                        ? colors.accentWarning.withOpacity(0.4)
                        : colors.borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRunning)
                  _PulsingDot(color: colors.accentWarning)
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isComplete ? colors.accentSuccess : colors.textSecondary,
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  isRunning
                      ? 'EXECUTING...'
                      : isComplete
                          ? 'COMPLETE'
                          : 'PENDING',
                  style: AppTheme.caption(
                    context,
                    isComplete
                        ? colors.accentSuccess
                        : isRunning
                            ? colors.accentWarning
                            : colors.textSecondary,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section 1: Action Header ───────────────────
            _buildActionHeader(context, updatedAction, colors)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ─── Section 2: Portfolio Rebalancing Transition ──
            _buildSectionLabel(context, 'PORTFOLIO REBALANCING TRANSITION', colors),
            const SizedBox(height: 12),
            _buildBeforeAfterCharts(context, isComplete, colors)
                .animate()
                .fadeIn(duration: 450.ms, delay: 100.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 24),

            // ─── Section 3: Execute Button or Simulation Logs ─
            if (!isRunning && !isComplete) ...[
              _buildSandboxNotice(context, updatedAction, colors)
                  .animate()
                  .fadeIn(duration: 350.ms),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'EXECUTE SIMULATION',
                width: double.infinity,
                icon: Icons.rocket_launch_outlined,
                onPressed: () => apiState.executeActionSimulation(updatedAction),
              ).animate().fadeIn(duration: 400.ms).scaleY(begin: 0.9, end: 1),
              const SizedBox(height: 24),
            ],

            // ─── Section 4: Execution Audit Log ───────────────
            _buildSectionLabel(context, 'EXECUTION ORDER AUDIT LOG', colors),
            const SizedBox(height: 10),
            _buildTerminalConsole(context, apiState, colors),
            const SizedBox(height: 24),

            // ─── Section 5: Risk Score Progression (shown after sim) ──
            if (isComplete || isRunning) ...[
              _buildSectionLabel(context, 'RISK PROFILE SCORE PROGRESSION', colors),
              const SizedBox(height: 12),
              _buildRiskProgressCard(context, isComplete, colors)
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 24),

              // ─── Section 6: P&L Summary ─────────────────────
              _buildPnLCard(context, updatedAction, colors)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 24),
            ],

            // ─── Section 7: Navigation CTAs (after complete) ──
            if (isComplete) ...[
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'VIEW TRACE',
                      icon: Icons.psychology_rounded,
                      onPressed: () {
                        final shellState =
                            context.findAncestorStateOfType<MainShellState>();
                        shellState?.onTabSelected(2);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'DASHBOARD',
                      icon: Icons.dashboard_rounded,
                      onPressed: () =>
                          Navigator.of(context).popUntil((route) => route.isFirst),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, AppThemeColors colors) {
    return Text(
      label,
      style: AppTheme.caption(context, colors.textSecondary).copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildActionHeader(BuildContext context, ActionItem action, AppThemeColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgSurface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _chip(context, action.displayDomain.toUpperCase(), colors.accentPrimary, colors),
                  const SizedBox(width: 8),
                  _chip(context, action.displayType.toUpperCase(), colors.accentSecondary, colors),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                action.displayTitle,
                style: AppTheme.headingLg(context, colors.textPrimary).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.memory_rounded, size: 14, color: colors.accentSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Target: ${action.displayTargetSystem}',
                      style: AppTheme.monoSm(context, colors.accentSecondary)
                          .copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color, AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: AppTheme.caption(context, color).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBeforeAfterCharts(BuildContext context, bool isComplete, AppThemeColors colors) {
    // Determine allocation data from action
    final beforeData = widget.action.displayBeforeState;
    final afterData = widget.action.displayAfterState;

    // Build before sections — always show as single red ring (100% = before state)
    List<PieChartSectionData> buildBeforeSections() {
      if (beforeData.isEmpty) {
        return [
          PieChartSectionData(
            color: const Color(0xFFFF6B7A),
            value: 100,
            title: '100%',
            radius: 32,
            titleStyle: AppTheme.bodyMd(context, Colors.white)
                .copyWith(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ];
      }
      final entries = beforeData.entries.toList();
      final sliceColors = [
        const Color(0xFFFF6B7A),
        const Color(0xFFFF9A9A),
        const Color(0xFFFFB3B3),
      ];
      double perSlice = 100.0 / entries.length;
      return List.generate(entries.length, (i) => PieChartSectionData(
        color: sliceColors[i % sliceColors.length],
        value: perSlice,
        title: '${perSlice.toInt()}%',
        radius: 32,
        titleStyle: AppTheme.bodySm(context, Colors.white)
            .copyWith(fontWeight: FontWeight.bold, fontSize: 11),
      ));
    }

    List<PieChartSectionData> buildAfterSections() {
      if (!isComplete || afterData.isEmpty) {
        return [
          PieChartSectionData(
            color: const Color(0xFFFF6B7A),
            value: 100,
            title: '100%',
            radius: 32,
            titleStyle: AppTheme.bodyMd(context, Colors.white)
                .copyWith(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ];
      }
      final entries = afterData.entries.toList();
      final sliceColors = [
        const Color(0xFF00D4AA),
        const Color(0xFF00B391),
        const Color(0xFF009978),
      ];
      double perSlice = 100.0 / entries.length;
      return List.generate(entries.length, (i) => PieChartSectionData(
        color: sliceColors[i % sliceColors.length],
        value: perSlice,
        title: '${perSlice.toInt()}%',
        radius: 32,
        titleStyle: AppTheme.bodySm(context, Colors.black)
            .copyWith(fontWeight: FontWeight.bold, fontSize: 11),
      ));
    }

    Widget _donutCard({
      required String label,
      required Color labelColor,
      required Color borderColor,
      required List<PieChartSectionData> sections,
      required String statusText,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTheme.caption(context, labelColor).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 38,
                  startDegreeOffset: -90,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: labelColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: AppTheme.caption(context, colors.textSecondary)
                      .copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // BEFORE card
        Expanded(
          child: _donutCard(
            label: 'BEFORE',
            labelColor: const Color(0xFFFF6B7A),
            borderColor: const Color(0xFFFF6B7A).withOpacity(0.5),
            sections: buildBeforeSections(),
            statusText: 'Status: Inactive',
          ),
        ),

        // Arrow connector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: colors.accentPrimary.withOpacity(0.35), width: 1),
            ),
            child: Icon(Icons.arrow_forward_rounded,
                color: colors.accentPrimary, size: 16),
          ),
        ),

        // AFTER card
        Expanded(
          child: _donutCard(
            label: 'AFTER',
            labelColor: isComplete ? const Color(0xFF00D4AA) : colors.textSecondary,
            borderColor: isComplete
                ? const Color(0xFF00D4AA).withOpacity(0.5)
                : colors.borderColor,
            sections: buildAfterSections(),
            statusText: isComplete ? 'Status: Modified' : 'Status: Pending',
          ),
        ),
      ],
    );
  }

  Widget _buildSandboxNotice(BuildContext context, ActionItem action, AppThemeColors colors) {
    return _glassBox(
      context,
      colors,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: colors.accentPrimary.withOpacity(0.3)),
            ),
            child: Icon(Icons.shield_outlined, color: colors.accentPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sandbox Safety Protocol',
                  style: AppTheme.bodyMd(context, colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Production DBs isolated. Virtual execution only.',
                  style: AppTheme.caption(context, colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalConsole(BuildContext context, ApiService apiState, AppThemeColors colors) {
    final logs = apiState.simulationLogs;
    final isRunning = apiState.isSimulationRunning;

    final staticLines = [
      _TerminalLine(time: '11:01:23', side: 'SELL', sideColor: colors.accentDanger,
          asset: widget.action.displayTitle, qty: 'Qty: A', price: '@ market', value: '-Δ'),
      _TerminalLine(time: '11:02:05', side: 'BUY ', sideColor: colors.accentSuccess,
          asset: widget.action.displayTargetSystem, qty: 'Qty: B', price: '@ market', value: '+Δ'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x99070B13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.accentSuccess.withOpacity(0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.glowColor.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PulsingDot(color: colors.accentSuccess),
                  const SizedBox(width: 8),
                  Text(
                    'TERMINAL — ORDER SIMULATION SYSTEM',
                    style: AppTheme.monoSm(context, colors.accentSuccess)
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...staticLines.map((line) => _buildTerminalLine(context, line)),
              const SizedBox(height: 8),

              Divider(color: colors.borderColor.withOpacity(0.2)),
              const SizedBox(height: 6),

              if (logs.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    controller: _logsScrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Color logColor = colors.textSecondary;
                      if (log.contains('[SIMULATOR]')) logColor = colors.accentPrimary;
                      if (log.contains('[OK]')) logColor = colors.accentSuccess;
                      return _AnimatedLog(log: log, logColor: logColor);
                    },
                  ),
                )
              else
                Text(
                  '>> ALL ORDERS SETTLED VIA LIQUIDITY POOL PORT A.\n>> MARGIN RATIO ADEQUATE. EXPOSURE REDUCTION CONFIRMED.',
                  style: AppTheme.monoSm(context, colors.textSecondary.withOpacity(0.6)).copyWith(fontSize: 10, height: 1.4),
                ),

              if (isRunning) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: apiState.simulationProgress,
                    backgroundColor: colors.bgElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                    minHeight: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalLine(BuildContext context, _TerminalLine line) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('[${line.time}]',
              style: AppTheme.monoSm(context, colors.textSecondary.withOpacity(0.5)).copyWith(fontSize: 10)),
          const SizedBox(width: 8),
          Text(line.side,
              style: AppTheme.monoSm(context, line.sideColor)
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(line.asset,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.monoSm(context, colors.textPrimary).copyWith(fontSize: 10))),
          Text(line.qty,
              style: AppTheme.monoSm(context, colors.textSecondary).copyWith(fontSize: 10)),
          const SizedBox(width: 8),
          Text(line.price,
              style: AppTheme.monoSm(context, colors.textSecondary).copyWith(fontSize: 10)),
          const SizedBox(width: 8),
          Text(line.value,
              style: AppTheme.monoSm(context, line.sideColor)
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRiskProgressCard(BuildContext context, bool isComplete, AppThemeColors colors) {
    return _glassBox(
      context,
      colors,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Before: 90% (HIGH)',
                      style: AppTheme.bodySm(context, colors.accentDanger)
                          .copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('After: 45% (MEDIUM)',
                      style: AppTheme.bodySm(
                        context,
                        isComplete ? colors.accentWarning : colors.textSecondary,
                      ).copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween<double>(begin: 0.9, end: isComplete ? 0.45 : 0.9),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: colors.bgElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? colors.accentWarning : colors.accentDanger,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPnLCard(BuildContext context, ActionItem action, AppThemeColors colors) {
    final isPos = action.displayIsPositiveMetric;
    final metricColor = isPos ? colors.accentSuccess : colors.accentDanger;

    return _glassBox(
      context,
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREDICTED OUTCOME METRICS',
            style: AppTheme.caption(context, colors.textSecondary)
                .copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPnlTile(context, action.displayMetricName.toUpperCase(),
                  action.displayMetricValue, metricColor, colors),
              _buildPnlDivider(colors),
              _buildPnlTile(
                  context, 'VOLATILITY DELTA', '-0.43', colors.accentSuccess, colors),
              _buildPnlDivider(colors),
              _buildPnlTile(
                  context, 'HEDGE EFFICIENCY', '97.4%', colors.accentWarning, colors),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isPos
                  ? colors.accentSuccess.withOpacity(0.08)
                  : colors.accentWarning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isPos
                  ? colors.accentSuccess.withOpacity(0.3)
                  : colors.accentWarning.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: isPos ? colors.accentSuccess : colors.accentDanger,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPos
                        ? 'Simulated execution verified. Positive outlook delta.'
                        : 'Simulated execution complete. High Risk exposure flagged.',
                    style: AppTheme.caption(context, colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPnlTile(BuildContext context, String title, String value, Color color, AppThemeColors colors) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: AppTheme.caption(context, colors.textSecondary)
                .copyWith(fontSize: 8, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.headingMd(context, color).copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPnlDivider(AppThemeColors colors) {
    return Container(width: 1, height: 40, color: colors.borderColor);
  }

  Widget _glassBox(BuildContext context, AppThemeColors colors,
      {required Widget child, Color? borderHighlight}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgSurface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderHighlight ?? colors.borderColor,
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(seconds: 1), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7 * _anim.value,
        height: 7 * _anim.value,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 6 * _anim.value)
          ],
        ),
      ),
    );
  }
}

class _TerminalLine {
  final String time;
  final String side;
  final Color sideColor;
  final String asset;
  final String qty;
  final String price;
  final String value;

  const _TerminalLine({
    required this.time,
    required this.side,
    required this.sideColor,
    required this.asset,
    required this.qty,
    required this.price,
    required this.value,
  });
}

class _AnimatedLog extends StatelessWidget {
  final String log;
  final Color logColor;

  const _AnimatedLog({required this.log, required this.logColor});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 6 * (1 - value)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          log,
          style: AppTheme.monoSm(context, logColor).copyWith(fontSize: 10, height: 1.3),
        ),
      ),
    );
  }
}
