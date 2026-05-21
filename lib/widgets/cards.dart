import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/insight.dart';
import '../models/action_item.dart';
import '../models/agent_trace.dart';
import 'feedback.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final bool hasGlow;
  final Color? glowColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.hasGlow = false,
    this.glowColor,
    this.backgroundColor,
    this.padding,
    this.borderRadius = 16.0, // Swapped to 16.0 for modern rounded layout
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final cardBg = backgroundColor ?? colors.bgSurface;
    final borderCol = colors.borderColor;

    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: hasGlow ? (glowColor ?? colors.accentPrimary).withOpacity(0.4) : borderCol,
              width: 1.2,
            ),
            boxShadow: hasGlow
                ? [
                    BoxShadow(
                      color: (glowColor ?? colors.glowColor).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: cardContent,
        ),
      );
    }
    return cardContent;
  }
}

class InsightCard extends StatelessWidget {
  final Insight insight;
  final bool isCompact;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.insight,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    Color getSeverityColor() {
      switch (insight.displaySeverity.toLowerCase()) {
        case 'critical':
          return colors.accentDanger;
        case 'high':
          return colors.accentWarning;
        case 'medium':
          return colors.accentSecondary;
        case 'low':
        default:
          return colors.accentSuccess;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.accentPrimary.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        insight.displayDomain.toUpperCase(),
                        style: AppTheme.caption(context, colors.accentPrimary).copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: getSeverityColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: getSeverityColor().withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        insight.displaySeverity.toUpperCase(),
                        style: AppTheme.caption(context, getSeverityColor()).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('HH:mm').format(insight.displayTimestamp),
                  style: AppTheme.monoSm(context, colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.displayTitle,
              style: AppTheme.headingMd(context, colors.textPrimary).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hub_outlined, size: 14, color: colors.textSecondary.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        insight.displaySource,
                        style: AppTheme.caption(context, colors.textSecondary.withOpacity(0.7)).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward, color: colors.accentPrimary, size: 14),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final ActionItem action;
  final bool isCompact;
  final VoidCallback onSimulate;

  const ActionCard({
    super.key,
    required this.action,
    this.isCompact = false,
    required this.onSimulate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final metricColor = action.displayIsPositiveMetric ? colors.accentSuccess : colors.accentWarning;

    return CustomCard(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.accentSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.accentSecondary.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      action.displayType.toUpperCase(),
                      style: AppTheme.caption(context, colors.accentSecondary).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.accentPrimary.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      action.displayDomain.toUpperCase(),
                      style: AppTheme.caption(context, colors.accentPrimary).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (action.displayStatus == 'simulated')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.accentSuccess, width: 1.2),
                  ),
                  child: Text(
                    'SIMULATED',
                    style: AppTheme.caption(context, colors.accentSuccess).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            action.displayTitle,
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: (isCompact
                    ? AppTheme.bodyMd(context, colors.textPrimary)
                    : AppTheme.headingMd(context, colors.textPrimary))
                .copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.displayDescription,
            maxLines: isCompact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodySm(context, colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.displayMetricName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(context, colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.displayMetricValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (isCompact
                              ? AppTheme.bodyMd(context, metricColor)
                              : AppTheme.headingMd(context, metricColor))
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: action.displayStatus == 'simulated' ? null : onSimulate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colors.bgElevated,
                  disabledForegroundColor: colors.textSecondary,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 18,
                    vertical: isCompact ? 8 : 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  shadowColor: colors.accentPrimary.withOpacity(0.4),
                  elevation: action.displayStatus == 'simulated' ? 0 : 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action.displayStatus == 'simulated' ? Icons.check : Icons.insights,
                      size: isCompact ? 12 : 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      action.displayStatus == 'simulated' ? 'Simulated' : 'Simulate',
                      style: AppTheme.caption(context, action.displayStatus == 'simulated' ? colors.textSecondary : Colors.white).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 9 : 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AgentTraceTile extends StatefulWidget {
  final AgentTrace trace;
  final int stepNumber;

  const AgentTraceTile({
    super.key,
    required this.trace,
    required this.stepNumber,
  });

  @override
  State<AgentTraceTile> createState() => _AgentTraceTileState();
}

class _AgentTraceTileState extends State<AgentTraceTile> {
  bool _isExpanded = false;

  IconData _getIcon() {
    switch (widget.trace.displayIconName) {
      case 'edit_note':
        return Icons.edit_note;
      case 'newspaper':
        return Icons.newspaper;
      case 'psychology':
        return Icons.psychology;
      case 'auto_graph':
        return Icons.auto_graph;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'security':
        return Icons.security;
      case 'gavel':
        return Icons.gavel;
      case 'insights':
        return Icons.insights;
      default:
        return Icons.smart_toy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isCurrentlyRunning = widget.trace.displayStatus == 'running';

    Color getStatusColor() {
      switch (widget.trace.displayStatus.toLowerCase()) {
        case 'done':
          return colors.accentSuccess;
        case 'running':
          return colors.accentWarning;
        case 'error':
          return colors.accentDanger;
        case 'waiting':
        default:
          return colors.textSecondary.withOpacity(0.4);
      }
    }

    return CustomCard(
      padding: const EdgeInsets.all(4),
      hasGlow: isCurrentlyRunning,
      glowColor: colors.accentWarning,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Stack(
                alignment: Alignment.center,
                children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: getStatusColor().withOpacity(0.3), width: 1),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: getStatusColor(),
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: AgentStatusDot(status: widget.trace.displayStatus, size: 6),
                ),
              ],
            ),
            title: Text(
              '${widget.stepNumber}. ${widget.trace.displayAgentName}',
              style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              widget.trace.displayStatus == 'done'
                  ? 'Processed in ${widget.trace.displayDurationMs}ms'
                  : widget.trace.displayStatus.toUpperCase(),
              style: AppTheme.caption(context, getStatusColor()).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: widget.trace.displayStatus == 'waiting'
                ? null
                : IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: colors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
            ),
          ),
          if (_isExpanded && widget.trace.displayStatus != 'waiting') ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildSection(context, 'INPUT RECEIVED', widget.trace.displayInputReceived),
                  const SizedBox(height: 12),
                  _buildSection(context, 'OUTPUT GENERATED', widget.trace.displayOutputProduced),
                  const SizedBox(height: 12),
                  Text(
                    'REASONING',
                    style: AppTheme.caption(context, colors.accentSecondary).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.bgElevated.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Text(
                      widget.trace.displayReasoning,
                      style: AppTheme.monoSm(context, colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String header, String content) {
    final colors = AppTheme.of(context);
    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: AppTheme.caption(context, colors.accentPrimary).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: AppTheme.bodySm(context, colors.textSecondary),
        ),
      ],
    );
  }
}
