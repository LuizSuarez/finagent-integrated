import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/agent_trace.dart';
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

    // Navigate to insight details when pipeline finishes
    if (!apiState.isPipelineRunning &&
        apiState.pipelineProgress == 1.0 &&
        apiState.insights.isNotEmpty) {
      final finishedInsight = apiState.insights.first;
      final navigator = Navigator.of(context);
      Future.microtask(() {
        if (mounted) {
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  InsightDetailScreen(insight: finishedInsight),
            ),
          );
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final isRunning = apiState.isPipelineRunning;
    final doneStepsCount =
        apiState.agentTraces.where((t) => t.displayStatus == 'done').length;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'Agent Execution Trace',
          style: AppTheme.headingMd(context, colors.textPrimary),
        ),
        actions: [
          if (isRunning)
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
          // Top progress bar
          ProgressBar(progress: apiState.pipelineProgress),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status row ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AUTONOMOUS WORKFLOW',
                        style: AppTheme.caption(context, colors.textSecondary)
                            .copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5),
                      ),
                      // Running / complete badge
                      _StatusBadge(isRunning: isRunning, colors: colors),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Input preview ────────────────────────────────
                  _buildInputPreview(context, colors),
                  const SizedBox(height: 24),

                  // ── Timeline trace ───────────────────────────────
                  if (apiState.agentTraces.isNotEmpty)
                    _TimelineTraceList(
                      traces: apiState.agentTraces,
                      isRunning: isRunning,
                    ),

                  const SizedBox(height: 24),

                  // ── Console ──────────────────────────────────────
                  Text(
                    'LIVE ORCHESTRATION CONSOLE',
                    style: AppTheme.caption(context, colors.textSecondary)
                        .copyWith(
                            fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 10),
                  _buildTerminalConsole(context, apiState, colors),
                  const SizedBox(height: 20),

                  if (doneStepsCount >= 2)
                    SecondaryButton(
                      text: 'VIEW PARTIAL RESULTS',
                      width: double.infinity,
                      onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildInputPreview(BuildContext context, AppThemeColors colors) {
    final snippet = widget.rawContent.length > 80
        ? '${widget.rawContent.substring(0, 80)}...'
        : widget.rawContent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.bgSurface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.feed_rounded, color: colors.accentPrimary, size: 15),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ingested: "$snippet"',
                  style: AppTheme.caption(context, colors.textSecondary)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalConsole(
      BuildContext context, ApiService state, AppThemeColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 160,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF070B13).withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: colors.accentPrimary.withOpacity(0.2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.accentPrimary.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
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
                    Color logColor = Colors.white38;
                    if (log.contains('[SYSTEM]'))
                      logColor = colors.accentPrimary;
                    if (log.contains('complete') || log.contains('took'))
                      logColor = colors.accentSuccess;
                    if (log.contains('Ingest:'))
                      logColor = colors.accentSecondary;
                    if (log.contains('cancel') || log.contains('Halted'))
                      logColor = colors.accentDanger;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(log,
                          style: AppTheme.monoSm(context, logColor)
                              .copyWith(fontSize: 10)),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Status Badge
// ──────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatefulWidget {
  final bool isRunning;
  final AppThemeColors colors;
  const _StatusBadge({required this.isRunning, required this.colors});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..repeat(reverse: true);
    _pulse =
        Tween<double>(begin: 0.5, end: 1.2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isRunning ? widget.colors.accentWarning : widget.colors.accentSuccess;
    final label = widget.isRunning ? 'EXECUTING AGENTS...' : 'WORKFLOW COMPLETE ✓';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isRunning)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 7 * _pulse.value,
                height: 7 * _pulse.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6 * _pulse.value)
                  ],
                ),
              ),
            )
          else
            Container(
                width: 7, height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTheme.caption(context, color)
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Timeline Trace List — the full vertical timeline
// ──────────────────────────────────────────────────────────────────────
class _TimelineTraceList extends StatelessWidget {
  final List<AgentTrace> traces;
  final bool isRunning;

  const _TimelineTraceList(
      {required this.traces, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(traces.length, (index) {
        final trace = traces[index];
        final isLast = index == traces.length - 1;
        return _TimelineRow(
          trace: trace,
          index: index,
          isLast: isLast,
          isRunning: isRunning,
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Timeline Row — dot + line + animated card
// ──────────────────────────────────────────────────────────────────────
class _TimelineRow extends StatefulWidget {
  final AgentTrace trace;
  final int index;
  final bool isLast;
  final bool isRunning;

  const _TimelineRow({
    required this.trace,
    required this.index,
    required this.isLast,
    required this.isRunning,
  });

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  bool _expanded = false;

  // Only show card once agent has been activated
  static bool _isVisible(String status) =>
      status == 'done' || status == 'running' || status == 'error';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _slide = Tween<Offset>(begin: const Offset(-0.8, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // If this trace is already active on first render, show immediately
    if (_isVisible(widget.trace.displayStatus)) {
      _ctrl.forward();
    }
  }

  @override
  void didUpdateWidget(_TimelineRow old) {
    super.didUpdateWidget(old);
    final wasVisible = _isVisible(old.trace.displayStatus);
    final nowVisible = _isVisible(widget.trace.displayStatus);
    // Newly activated — slide in fresh from the left
    if (!wasVisible && nowVisible) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't render until this agent is activated
    if (!_isVisible(widget.trace.displayStatus)) {
      return const SizedBox.shrink();
    }

    final colors = AppTheme.of(context);
    final status = widget.trace.displayStatus;
    final isDone = status == 'done';
    final isRunning = status == 'running';
    final isError = status == 'error';

    // Dot color matches the design.dart reference
    Color dotColor = colors.borderColor;
    if (isRunning) dotColor = colors.accentWarning;
    if (isDone) dotColor = colors.accentPrimary;
    if (isError) dotColor = colors.accentDanger;

    // Generate a timestamp string
    final ts = widget.trace.timestamp != null
        ? '${widget.trace.timestamp!.hour.toString().padLeft(2, '0')}:'
            '${widget.trace.timestamp!.minute.toString().padLeft(2, '0')}:'
            '${widget.trace.timestamp!.second.toString().padLeft(2, '0')}'
        : '??:??:??';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: dot + vertical line ──────────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Dot
                _TimelineDot(color: dotColor, isPulsing: isRunning),
                // Connecting line (hidden for last item)
                if (!widget.isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              dotColor.withOpacity(0.6),
                              dotColor.withOpacity(0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Right: animated slide-in card ──────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 14),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.bgSurface.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRunning
                                  ? dotColor.withOpacity(0.5)
                                  : colors.borderColor.withOpacity(0.5),
                              width: isRunning ? 1.5 : 1,
                            ),
                            boxShadow: isRunning
                                ? [
                                    BoxShadow(
                                      color: dotColor.withOpacity(0.2),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.trace.displayAgentName,
                                      style: AppTheme.bodyMd(
                                              context, colors.textPrimary)
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '[$ts]',
                                    style: AppTheme.monoSm(
                                            context, colors.textSecondary)
                                        .copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Status + expand arrow
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: dotColor,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        status.toUpperCase(),
                                        style: AppTheme.caption(
                                                context, dotColor)
                                            .copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _expanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    size: 18,
                                    color: colors.textSecondary
                                        .withOpacity(0.6),
                                  ),
                                ],
                              ),

                              // Expandable reasoning
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Divider(
                                          color: colors.borderColor
                                              .withOpacity(0.4),
                                          height: 16),
                                      Text(
                                        widget.trace.displayReasoning,
                                        style: AppTheme.caption(
                                            context, colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                crossFadeState: _expanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration:
                                    const Duration(milliseconds: 220),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Timeline Dot — optionally pulsing
// ──────────────────────────────────────────────────────────────────────
class _TimelineDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;

  const _TimelineDot({required this.color, required this.isPulsing});

  @override
  State<_TimelineDot> createState() => _TimelineDotState();
}

class _TimelineDotState extends State<_TimelineDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _scale = Tween<double>(begin: 0.7, end: 1.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isPulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TimelineDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isPulsing && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) {
        final s = widget.isPulsing ? _scale.value : 1.0;
        return Container(
          width: 14 * s,
          height: 14 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F172A), // bg behind dot ring
            border: Border.all(color: widget.color, width: 3.0),
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(widget.isPulsing ? 0.5 : 0.3),
                  blurRadius: 8 * s,
                  spreadRadius: widget.isPulsing ? 2 * s : 0),
            ],
          ),
        );
      },
    );
  }
}
