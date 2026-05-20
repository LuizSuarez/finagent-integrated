import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/action_item.dart';
import '../services/api_service.dart';
import '../widgets/buttons.dart';
import '../widgets/feedback.dart';
import 'main_shell.dart';

// ============================================================
// ACTION SIMULATION SCREEN — Trade Execution Design
// ============================================================
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
        duration: const Duration(milliseconds: 150),
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
        backgroundColor: colors.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTION SANDBOX',
              style: AppTheme.headingMd(context, colors.textPrimary)
                  .copyWith(letterSpacing: 1.2, fontSize: 14),
            ),
            Text(
              updatedAction.displayType.toUpperCase(),
              style: AppTheme.caption(context, colors.accentPrimary)
                  .copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ],
        ),
        actions: [
          // Live status badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          ? 'COMPLETE ✓'
                          : 'PENDING',
                  style: AppTheme.caption(
                    context,
                    isComplete
                        ? colors.accentSuccess
                        : isRunning
                            ? colors.accentWarning
                            : colors.textSecondary,
                  ).copyWith(fontWeight: FontWeight.bold),
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
            _buildActionHeader(context, updatedAction, colors),
            const SizedBox(height: 20),

            // ─── Section 2: Portfolio Rebalancing Transition ──
            _buildSectionLabel(context, 'PORTFOLIO REBALANCING TRANSITION', colors),
            const SizedBox(height: 12),
            _buildBeforeAfterCharts(context, isComplete, colors),
            const SizedBox(height: 24),

            // ─── Section 3: Execute Button or Simulation Logs ─
            if (!isRunning && !isComplete) ...[
              _buildSandboxNotice(context, updatedAction, colors),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'EXECUTE SIMULATION',
                width: double.infinity,
                icon: Icons.rocket_launch_outlined,
                onPressed: () => apiState.executeActionSimulation(updatedAction),
              ),
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
              _buildRiskProgressCard(context, isComplete, colors),
              const SizedBox(height: 24),

              // ─── Section 6: P&L Summary ─────────────────────
              _buildPnLCard(context, updatedAction, colors),
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Helper: section label
  // ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(BuildContext context, String label, AppThemeColors colors) {
    return Text(
      label,
      style: AppTheme.caption(context, colors.textSecondary).copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Action Header
  // ──────────────────────────────────────────────────────────
  Widget _buildActionHeader(BuildContext context, ActionItem action, AppThemeColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgSurface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColor.withOpacity(0.6)),
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
                style: AppTheme.headingLg(context, colors.textPrimary),
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

  // ──────────────────────────────────────────────────────────
  // Before / After Pie Charts
  // ──────────────────────────────────────────────────────────
  Widget _buildBeforeAfterCharts(BuildContext context, bool isComplete, AppThemeColors colors) {
    final beforeState = widget.action.displayBeforeState;
    final afterState = widget.action.displayAfterState;

    // Convert before/after state maps to simple display values
    final beforeEntries = beforeState.entries.take(3).toList();
    final afterEntries = afterState.entries.take(3).toList();

    // Use 3 fixed accent colors for pie slices
    const sliceColors = [Color(0xFFFF4757), Color(0xFF00FF88), Color(0xFF00D4FF)];

    List<PieChartSectionData> makeSections(List<MapEntry<String, String>> entries) {
      // Generate rough percentage splits
      final count = entries.length.clamp(1, 3);
      final splits = count == 1
          ? [100.0]
          : count == 2
              ? [40.0, 60.0]
              : [35.0, 25.0, 40.0];

      return List.generate(count, (i) {
        return PieChartSectionData(
          color: sliceColors[i % sliceColors.length],
          value: splits[i],
          title: '${splits[i].toInt()}%',
          radius: 20,
          titleStyle: AppTheme.monoSm(context, Colors.white).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 8,
          ),
        );
      });
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BEFORE card
        Expanded(
          child: _glassBox(
            context,
            colors,
            borderHighlight: colors.accentDanger.withOpacity(0.4),
            child: Column(
              children: [
                Text(
                  'BEFORE',
                  style: AppTheme.caption(context, colors.accentDanger)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 22,
                      sections: makeSections(beforeEntries),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...beforeEntries.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: sliceColors[e.key % sliceColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${e.value.key}: ${e.value.value}',
                            style: AppTheme.caption(context, colors.textSecondary)
                                .copyWith(fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Arrow
        Padding(
          padding: const EdgeInsets.only(top: 55, left: 6, right: 6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_rounded, color: colors.accentPrimary, size: 14),
          ),
        ),

        // AFTER card
        Expanded(
          child: _glassBox(
            context,
            colors,
            borderHighlight: isComplete ? colors.accentSuccess.withOpacity(0.4) : null,
            child: Column(
              children: [
                Text(
                  'AFTER',
                  style: AppTheme.caption(
                    context,
                    isComplete ? colors.accentSuccess : colors.textSecondary,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: isComplete
                      ? PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 22,
                            sections: makeSections(afterEntries),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.lock_clock_outlined,
                            color: colors.textSecondary.withOpacity(0.4),
                            size: 32,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                if (isComplete) ...[
                  ...afterEntries.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: sliceColors[e.key % sliceColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${e.value.key}: ${e.value.value}',
                              style: AppTheme.caption(context, colors.textSecondary)
                                  .copyWith(fontSize: 9),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else
                  Text(
                    'Run simulation\nto reveal',
                    style: AppTheme.caption(context, colors.textSecondary)
                        .copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // Sandbox Notice
  // ──────────────────────────────────────────────────────────
  Widget _buildSandboxNotice(BuildContext context, ActionItem action, AppThemeColors colors) {
    return _glassBox(
      context,
      colors,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: colors.accentPrimary, size: 18),
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
                  'Prod DBs isolated. Virtual sim only.',
                  style: AppTheme.caption(context, colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Terminal Console (Audit Log)
  // ──────────────────────────────────────────────────────────
  Widget _buildTerminalConsole(BuildContext context, ApiService apiState, AppThemeColors colors) {
    final logs = apiState.simulationLogs;
    final isRunning = apiState.isSimulationRunning;

    // Static audit lines (always shown)
    final staticLines = [
      _TerminalLine(time: '11:01:23', side: 'SELL', sideColor: const Color(0xFFFF4757),
          asset: widget.action.displayTitle, qty: 'Qty: A', price: '@ market', value: '-Δ'),
      _TerminalLine(time: '11:02:05', side: 'BUY ', sideColor: const Color(0xFF00FF88),
          asset: widget.action.displayTargetSystem, qty: 'Qty: B', price: '@ market', value: '+Δ'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF070B13).withOpacity(0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.accentSuccess.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: colors.accentPrimary.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terminal header row
              Row(
                children: [
                  _PulsingDot(color: colors.accentSuccess),
                  const SizedBox(width: 8),
                  Text(
                    'TERMINAL — ORDER EXECUTION ENGINE',
                    style: AppTheme.monoSm(context, colors.accentSuccess)
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Static trade lines
              ...staticLines.map((line) => _buildTerminalLine(context, line)),
              const SizedBox(height: 8),

              // Divider
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 6),

              // Live simulation logs (if available)
              if (logs.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    controller: _logsScrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Color logColor = Colors.white38;
                      if (log.contains('[SIMULATOR]')) logColor = colors.accentPrimary;
                      if (log.contains('[OK]')) logColor = colors.accentSuccess;
                      return _AnimatedLog(log: log, logColor: logColor, context: context);
                    },
                  ),
                )
              else
                Text(
                  '>> ALL ORDERS SETTLED VIA LIQUIDITY POOL PORT A.\n>> MARGIN RATIO ADEQUATE. EXPOSURE REDUCTION CONFIRMED.',
                  style: AppTheme.monoSm(context, Colors.grey.shade600).copyWith(fontSize: 9),
                ),

              // Progress bar if running
              if (isRunning) ...[
                const SizedBox(height: 10),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('[${line.time}]',
              style: AppTheme.monoSm(context, Colors.white38).copyWith(fontSize: 10)),
          const SizedBox(width: 8),
          Text(line.side,
              style: AppTheme.monoSm(context, line.sideColor)
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(line.asset,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.monoSm(context, Colors.white).copyWith(fontSize: 10))),
          Text(line.qty,
              style: AppTheme.monoSm(context, Colors.white54).copyWith(fontSize: 10)),
          const SizedBox(width: 8),
          Text(line.price,
              style: AppTheme.monoSm(context, Colors.white54).copyWith(fontSize: 10)),
          const SizedBox(width: 8),
          Text(line.value,
              style: AppTheme.monoSm(context, line.sideColor)
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Risk Score Progression
  // ──────────────────────────────────────────────────────────
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

  // ──────────────────────────────────────────────────────────
  // P&L Summary Metrics
  // ──────────────────────────────────────────────────────────
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
                        ? 'Simulated. Positive Delta.'
                        : 'Simulated. High Risk Warning.',
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

  // ──────────────────────────────────────────────────────────
  // Shared glass box container
  // ──────────────────────────────────────────────────────────
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
            color: colors.bgSurface.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderHighlight ?? colors.borderColor.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Supporting Widgets
// ──────────────────────────────────────────────────────────

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
  final BuildContext context;

  const _AnimatedLog(
      {required this.log, required this.logColor, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 6 * (1 - value)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Text(
          log,
          style: AppTheme.monoSm(ctx, logColor).copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
