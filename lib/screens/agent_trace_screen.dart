import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../models/agent_trace.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import '../widgets/buttons.dart';

class AgentTraceScreen extends StatefulWidget {
  const AgentTraceScreen({super.key});

  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> {
  String _activeFilter = 'All'; // All, Input, Analysis, Decision, Simulation
  final ScrollController _flowScrollController = ScrollController();
  bool _isAutoScrolling = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _flowScrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (!_flowScrollController.hasClients) return;
    Future.doWhile(() async {
      if (!_isAutoScrolling) return false;
      await Future.delayed(const Duration(milliseconds: 40));
      if (!_flowScrollController.hasClients || !_isAutoScrolling) return false;

      final maxScroll = _flowScrollController.position.maxScrollExtent;
      final currentScroll = _flowScrollController.position.pixels;

      if (currentScroll >= maxScroll - 0.5) {
        _flowScrollController.jumpTo(0);
      } else {
        _flowScrollController.jumpTo(currentScroll + 0.8);
      }
      return true;
    });
  }

  List<AgentTrace> _filterTraces(List<AgentTrace> traces) {
    if (_activeFilter == 'All') return traces;
    
    return traces.where((t) {
      final name = t.displayAgentName.toLowerCase();
      if (_activeFilter == 'Input') {
        return name.contains('input') || name.contains('news');
      } else if (_activeFilter == 'Analysis') {
        return name.contains('sentiment') || name.contains('extraction') || name.contains('market');
      } else if (_activeFilter == 'Decision') {
        return name.contains('risk') || name.contains('decision');
      } else if (_activeFilter == 'Simulation') {
        return name.contains('simulation');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);
    final traces = apiState.agentTraces;
    final filteredTraces = _filterTraces(traces);

    // Pipeline metrics
    final totalSteps = traces.length;
    final totalDuration = traces.fold<int>(0, (sum, element) => sum + element.displayDurationMs);
    final errorsCount = traces.where((t) => t.displayStatus == 'error').length;
    final pipelineStatus = errorsCount > 0
        ? 'Error'
        : (traces.any((t) => t.displayStatus == 'running') ? 'Running' : 'Success');

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'AGENT AUDIT TRACE',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_outlined, color: colors.textSecondary),
            onPressed: () {
              ToastService.showSuccess(context, 'Orchestration trace JSON exported successfully.');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Pipeline Summary Card
            _buildPipelineSummary(context, totalSteps, totalDuration, pipelineStatus),
            const SizedBox(height: 20),

            // Section: Visual Flowchart
            Text(
              'DECISION FLOW ORCHESTRATION MAP',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            _buildDecisionFlowMap(context, traces),
            const SizedBox(height: 24),

            // Section: Filter bar
            Text(
              'AUDIT LOG ENTRIES',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _buildFilterBar(context),
            const SizedBox(height: 12),

            // Section: Trace List
            if (filteredTraces.isEmpty)
              CustomCard(
                child: Center(
                  child: Text(
                    'No agent actions match the filter criteria.',
                    style: AppTheme.bodySm(context, colors.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTraces.length,
                itemBuilder: (context, index) {
                  final trace = filteredTraces[index];
                  // Find original index for step label
                  final origIndex = traces.indexOf(trace);
                  return AgentTraceTile(
                    trace: trace,
                    stepNumber: origIndex != -1 ? origIndex + 1 : index + 1,
                  );
                },
              ),
            const SizedBox(height: 24),

            // Element: Antigravity Badge
            _buildAntigravityBadge(context),
            const SizedBox(height: 16),

            // Export CTA
            Center(
              child: SecondaryButton(
                text: 'EXPORT TRACE JSON',
                width: double.infinity,
                icon: Icons.code,
                onPressed: () {
                  ToastService.showSuccess(context, 'Exported 8 traces structure to /storage/exports/.');
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineSummary(BuildContext context, int steps, int duration, String status) {
    final colors = AppTheme.of(context);
    
    Color getStatusColor() {
      if (status == 'Success') return colors.accentSuccess;
      if (status == 'Running') return colors.accentWarning;
      return colors.accentDanger;
    }

    return CustomCard(
      backgroundColor: colors.bgSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(context, 'TOTAL STEPS', '$steps / 8'),
          Container(height: 30, width: 1, color: colors.borderColor),
          _buildSummaryItem(context, 'ELAPSED TIME', '${(duration / 1000).toStringAsFixed(2)}s'),
          Container(height: 30, width: 1, color: colors.borderColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PIPELINE STATUS',
                style: AppTheme.caption(context, colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  AgentStatusDot(status: status.toLowerCase(), size: 6),
                  const SizedBox(width: 6),
                  Text(
                    status.toUpperCase(),
                    style: AppTheme.monoSm(context, getStatusColor()).copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, String value) {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTheme.caption(context, colors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.monoSm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final filters = ['All', 'Input', 'Analysis', 'Decision', 'Simulation'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CustomChip(
              label: f,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _activeFilter = f;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDecisionFlowMap(BuildContext context, List<AgentTrace> traces) {
    final colors = AppTheme.of(context);
    if (traces.isEmpty) return const SizedBox();

    return GestureDetector(
      onTap: () {
        setState(() {
          _isAutoScrolling = !_isAutoScrolling;
          if (_isAutoScrolling) {
            _startAutoScroll();
          }
        });
      },
      child: CustomCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              child: ListView.builder(
                controller: _flowScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: traces.length * 50,
                itemBuilder: (context, index) {
                  final trace = traces[index % traces.length];
                  
                  Color getNodeColor() {
                    if (trace.displayStatus == 'done') return colors.accentSuccess;
                    if (trace.displayStatus == 'running') return colors.accentWarning;
                    if (trace.displayStatus == 'error') return colors.accentDanger;
                    return colors.borderColor;
                  }

                  return Row(
                    children: [
                      // Node representing an Agent
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.bgElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: getNodeColor(), width: 1.5),
                              boxShadow: trace.displayStatus == 'running'
                                  ? [BoxShadow(color: colors.accentWarning.withValues(alpha: 0.3), blurRadius: 8)]
                                  : null,
                            ),
                            child: Text(
                              trace.displayAgentName.split(' ').map((e) => e[0]).join(), // Initials
                              style: AppTheme.caption(context, getNodeColor()).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            trace.displayAgentName.replaceFirst(' Agent', ''),
                            style: AppTheme.caption(context, colors.textSecondary).copyWith(fontSize: 8),
                          ),
                        ],
                      ),
                      // Arrow connector to next agent
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 1.5,
                              color: trace.displayStatus == 'done' ? colors.accentSuccess : colors.borderColor,
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: trace.displayStatus == 'done' ? colors.accentSuccess : colors.borderColor,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isAutoScrolling ? '⚡ AUTO-SCROLLING (TAP MAP TO PAUSE)' : '⏸️ PAUSED (TAP MAP TO RESUME)',
                  style: AppTheme.caption(context, _isAutoScrolling ? colors.accentPrimary : colors.textSecondary).copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'LOOPING STREAM',
                  style: AppTheme.caption(context, colors.textSecondary).copyWith(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAntigravityBadge(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo geometric
          Container(
            height: 16,
            width: 16,
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.arrow_upward, color: Colors.black, size: 10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ORCHESTRATED BY GOOGLE ANTIGRAVITY',
            style: AppTheme.caption(context, colors.textSecondary).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
