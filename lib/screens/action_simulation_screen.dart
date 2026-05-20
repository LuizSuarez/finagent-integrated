import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/action_item.dart';
import '../services/api_service.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import '../widgets/state_display.dart';
import 'main_shell.dart';

class ActionSimulationScreen extends StatefulWidget {
  final ActionItem action;

  const ActionSimulationScreen({super.key, required this.action});

  @override
  State<ActionSimulationScreen> createState() => _ActionSimulationScreenState();
}

class _ActionSimulationScreenState extends State<ActionSimulationScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);

    // Fetch the updated action object from state (in case its status changed to simulated)
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
        title: Text(
          'ACTION SANDBOX',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: colors.textSecondary),
            onPressed: () {
              ToastService.showInfo(context, 'This simulation runs mock algorithms inside a virtual sandbox.');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Action Header
            _buildActionHeader(context, updatedAction),
            const SizedBox(height: 16),

            // Section: Simulation Explainer
            _buildExplainer(context, updatedAction),
            const SizedBox(height: 20),

            // Section: Before State panel
            if (!isRunning && !isComplete) ...[
              Text(
                'CURRENT BASELINE STATE',
                style: AppTheme.caption(context, colors.textSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatePanel(context, updatedAction.displayBeforeState, false),
              const SizedBox(height: 24),
              
              // Glow Execute Button
              PrimaryButton(
                text: 'EXECUTE SIMULATION',
                width: double.infinity,
                icon: Icons.science_outlined,
                onPressed: () {
                  apiState.executeActionSimulation(updatedAction);
                },
              ),
            ],

            // Section: Running progress indicators & Terminal logs
            if (isRunning || (isComplete && apiState.simulationLogs.isNotEmpty)) ...[
              Text(
                'SIMULATION ENGINE EXECUTION TRACE',
                style: AppTheme.caption(context, colors.textSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              _buildExecutionLogs(context, apiState),
              const SizedBox(height: 20),
            ],

            // Section: After State panel, Diffs & Outcomes
            if (isComplete) ...[
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Outcome summary
                    Text(
                      'PREDICTED OUTCOME METRIC',
                      style: AppTheme.caption(context, colors.textSecondary).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildOutcomeCard(context, updatedAction),
                    const SizedBox(height: 20),

                    // Section: Side-by-side Diffs (collapsible)
                    BeforeAfterState(
                      before: updatedAction.displayBeforeState,
                      after: updatedAction.displayAfterState,
                      initiallyExpanded: true,
                    ),
                    const SizedBox(height: 24),

                    // Navigation CTAs
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            text: 'VIEW FULL TRACE',
                            icon: Icons.history,
                            onPressed: () {
                              // Switch tab to Agent Trace and pop
                              final shellState = context.findAncestorStateOfType<MainShellState>();
                              shellState?.onTabSelected(2); // Agent trace tab index
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            text: 'DASHBOARD',
                            icon: Icons.dashboard,
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeader(BuildContext context, ActionItem action) {
    final colors = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.borderColor),
              ),
              child: Text(
                action.displayType.toUpperCase(),
                style: AppTheme.caption(context, colors.accentSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.borderColor),
              ),
              child: Text(
                action.displayDomain.toUpperCase(),
                style: AppTheme.caption(context, colors.accentPrimary).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          action.displayTitle,
          style: AppTheme.headingLg(context, colors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildExplainer(BuildContext context, ActionItem action) {
    final colors = AppTheme.of(context);

    return CustomCard(
      backgroundColor: colors.bgElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Sandbox Safety Protocol',
                style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'We will simulate this action across connected CRM, router, and pricing modules. No client-facing production databases will be altered.',
            style: AppTheme.caption(context, colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            'Target Interface: ${action.displayTargetSystem}',
            style: AppTheme.monoSm(context, colors.accentSecondary).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatePanel(BuildContext context, Map<String, String> stateValues, bool isAfter) {
    final colors = AppTheme.of(context);
    final headerColor = isAfter ? colors.accentSuccess : colors.accentDanger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAfter ? 'MUTATED VARIABLES' : 'BASELINE SYSTEM SETTINGS',
            style: AppTheme.caption(context, headerColor).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...stateValues.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(context, colors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.monoSm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExecutionLogs(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);

    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.simulationLogs.length,
              itemBuilder: (context, index) {
                final log = state.simulationLogs[index];
                Color logColor = colors.textSecondary;
                if (log.contains('[SIMULATOR]')) logColor = colors.accentPrimary;
                if (log.contains('[OK]')) logColor = colors.accentSuccess;

                return AnimatedLogEntry(
                  log: log,
                  logColor: logColor,
                );
              },
            ),
          ),
          if (state.isSimulationRunning) ...[
            const SizedBox(height: 8),
            ProgressBar(progress: state.simulationProgress),
          ]
        ],
      ),
    );
  }

  Widget _buildOutcomeCard(BuildContext context, ActionItem action) {
    final colors = AppTheme.of(context);
    final isPos = action.displayIsPositiveMetric;
    final metricColor = isPos ? colors.accentSuccess : colors.accentDanger;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: metricColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPos ? Icons.trending_up : Icons.trending_down,
              color: metricColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.displayMetricName.toUpperCase(),
                  style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  action.displayMetricValue,
                  style: AppTheme.headingLg(context, metricColor).copyWith(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPos ? colors.accentSuccess.withOpacity(0.1) : colors.accentWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isPos ? colors.accentSuccess : colors.accentWarning),
            ),
            child: Text(
              isPos ? 'SAFE DELTA' : 'RISK WARNING',
              style: AppTheme.caption(context, isPos ? colors.accentSuccess : colors.accentWarning).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedLogEntry extends StatelessWidget {
  final String log;
  final Color logColor;

  const AnimatedLogEntry({
    super.key,
    required this.log,
    required this.logColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0.0, 8.0 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          log,
          style: AppTheme.monoSm(context, logColor),
        ),
      ),
    );
  }
}
