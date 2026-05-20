import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import '../widgets/buttons.dart';
import 'insight_detail_screen.dart';

class PipelineRunningScreen extends StatefulWidget {
  final String rawContent;

  const PipelineRunningScreen({super.key, required this.rawContent});

  @override
  State<PipelineRunningScreen> createState() => _PipelineRunningScreenState();
}

class _PipelineRunningScreenState extends State<PipelineRunningScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add post frame callback to scroll terminal logs to bottom on startup
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant PipelineRunningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
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
    
    // Automatically navigate to insight details when pipeline is finished
    if (!apiState.isPipelineRunning && apiState.pipelineProgress == 1.0 && apiState.insights.isNotEmpty) {
      final finishedInsight = apiState.insights.first;
      final navigator = Navigator.of(context);
      // Use scheduleMicrotask to avoid setState during build
      Future.microtask(() {
        if (mounted) {
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => InsightDetailScreen(insight: finishedInsight),
            ),
          );
        }
      });
    }

    // Scroll to bottom as logs update
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Calculate completed steps
    final doneStepsCount = apiState.agentTraces.where((t) => t.displayStatus == 'done').length;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'PIPELINE EXECUTING',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
        actions: [
          if (apiState.isPipelineRunning)
            IconButton(
              icon: Icon(Icons.cancel_outlined, color: colors.accentDanger),
              onPressed: () {
                apiState.cancelPipeline();
                ToastService.showInfo(context, 'Pipeline cancelled.');
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Linear progress bar at top of body
          ProgressBar(progress: apiState.pipelineProgress),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Live Header
                  _buildLiveHeader(context, apiState),
                  const SizedBox(height: 16),

                  // Section: Input Preview (Collapsed)
                  _buildInputPreview(context),
                  const SizedBox(height: 20),

                  // Section: Stepper List of Agents
                  Text(
                    'INTELLIGENCE MATRIX PIPELINE',
                    style: AppTheme.caption(context, colors.textSecondary).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: apiState.agentTraces.length,
                    itemBuilder: (context, index) {
                      final trace = apiState.agentTraces[index];
                      return AgentTraceTile(
                        trace: trace,
                        stepNumber: index + 1,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Section: Monospace Log Terminal
                  Text(
                    'LIVE ORCHESTRATION CONSOLE (WEBSOCKET)',
                    style: AppTheme.caption(context, colors.textSecondary).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTerminalConsole(context, apiState),
                  const SizedBox(height: 24),

                  // Section: Quick Out actions
                  if (doneStepsCount >= 2)
                    Center(
                      child: SecondaryButton(
                        text: 'VIEW PARTIAL RESULTS',
                        width: double.infinity,
                        onPressed: () {
                          // View dashboard immediately
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveHeader(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);
    final isRunning = state.isPipelineRunning;

    return CustomCard(
      backgroundColor: colors.bgSurface,
      child: Row(
        children: [
          AgentStatusDot(status: isRunning ? 'thinking' : 'error', size: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRunning ? 'REASONING SEQUENCE ENGAGED' : 'PIPELINE HALTED',
                  style: AppTheme.caption(context, isRunning ? colors.accentWarning : colors.accentDanger).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRunning ? 'Active: ${state.activeAgent}' : 'Halted / Idling',
                  style: AppTheme.headingMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPreview(BuildContext context) {
    final colors = AppTheme.of(context);
    final snippet = widget.rawContent.length > 80 ? '${widget.rawContent.substring(0, 80)}...' : widget.rawContent;

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: colors.bgElevated,
      child: Row(
        children: [
          Icon(Icons.feed, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ingested: "$snippet"',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalConsole(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black, // true dark terminal
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderColor),
      ),
      child: state.pipelineLogs.isEmpty
          ? Center(
              child: Text(
                'Connecting to terminal sockets...',
                style: AppTheme.monoSm(context, colors.textSecondary),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: state.pipelineLogs.length,
              itemBuilder: (context, index) {
                final log = state.pipelineLogs[index];
                
                // Color code warnings and checkmarks
                Color logColor = colors.textSecondary;
                if (log.contains('[SYSTEM]')) logColor = colors.accentPrimary;
                if (log.contains('complete') || log.contains('took')) logColor = colors.accentSuccess;
                if (log.contains('Ingest:')) logColor = colors.accentSecondary;
                if (log.contains('cancel') || log.contains('Halted')) logColor = colors.accentDanger;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    log,
                    style: AppTheme.monoSm(context, logColor),
                  ),
                );
              },
            ),
    );
  }
}
