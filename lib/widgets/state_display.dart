import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import 'feedback.dart';

class BeforeAfterState extends StatelessWidget {
  final Map<String, String> before;
  final Map<String, String> after;
  final bool initiallyExpanded;

  const BeforeAfterState({
    super.key,
    required this.before,
    required this.after,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final allKeys = {...before.keys, ...after.keys}.toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: ExpansionTile(
        title: Text(
          'System State Mutation Diff',
          style: AppTheme.caption(context, colors.textPrimary).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        collapsedIconColor: colors.textSecondary,
        iconColor: colors.accentPrimary,
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BEFORE STATE',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption(context, colors.accentDanger).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.compare_arrows, color: colors.textSecondary, size: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'AFTER STATE (SIMULATED)',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption(context, colors.accentSuccess).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: allKeys.map((key) {
              final beforeVal = before[key] ?? '—';
              final afterVal = after[key] ?? '—';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key,
                      style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.accentDanger.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.accentDanger.withOpacity(0.2)),
                            ),
                            child: Text(
                              beforeVal,
                              style: AppTheme.monoSm(context, colors.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.accentSuccess.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.accentSuccess.withOpacity(0.2)),
                            ),
                            child: Text(
                              afterVal,
                              style: AppTheme.monoSm(context, colors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class WebSocketIndicator extends StatelessWidget {
  final bool isLive;

  const WebSocketIndicator({super.key, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AgentStatusDot(status: isLive ? 'active' : 'waiting', size: 6),
        const SizedBox(width: 6),
        Text(
          isLive ? 'LIVE' : 'MOCK',
          style: AppTheme.caption(context, isLive ? colors.accentPrimary : colors.textSecondary).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class TradeLogRow extends StatelessWidget {
  final String actionType;
  final String target;
  final String status;
  final DateTime timestamp;

  const TradeLogRow({
    super.key,
    required this.actionType,
    required this.target,
    required this.status,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    
    Color getStatusColor() {
      switch (status.toLowerCase()) {
        case 'simulated':
        case 'done':
        case 'success':
          return colors.accentSuccess;
        case 'pending':
          return colors.accentWarning;
        case 'error':
        case 'failed':
        default:
          return colors.accentDanger;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderColor, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionType,
                  style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  target,
                  style: AppTheme.caption(context, colors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: getStatusColor().withOpacity(0.3)),
              ),
              child: Text(
                status.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTheme.caption(context, getStatusColor()).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('HH:mm:ss').format(timestamp),
              textAlign: TextAlign.right,
              style: AppTheme.monoSm(context, colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
