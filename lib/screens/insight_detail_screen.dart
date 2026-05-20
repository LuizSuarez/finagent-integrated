import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/insight.dart';
import '../models/action_item.dart';
import '../services/api_service.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import 'action_simulation_screen.dart';

class InsightDetailScreen extends StatelessWidget {
  final Insight insight;

  const InsightDetailScreen({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);

    // Grab actions corresponding to this insight
    List<ActionItem> recommendedActions = [];
    if (insight.associatedActionIds != null && insight.associatedActionIds!.isNotEmpty) {
      recommendedActions = apiState.actions
          .where((act) => insight.associatedActionIds!.contains(act.id))
          .toList();
    } else {
      // Fallback: match by domain
      recommendedActions = apiState.actions
          .where((act) => act.displayDomain.toLowerCase() == insight.displayDomain.toLowerCase())
          .toList();
    }

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

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'INSIGHT REPORT',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: colors.textSecondary),
            onPressed: () {
              ToastService.showInfo(context, 'Insight report copied to clipboard.');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Insight Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Text(
                        insight.displayDomain.toUpperCase(),
                        style: AppTheme.caption(context, colors.accentPrimary).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: getSeverityColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: getSeverityColor().withOpacity(0.4)),
                      ),
                      child: Text(
                        '${insight.displaySeverity.toUpperCase()} RISK',
                        style: AppTheme.caption(context, getSeverityColor()).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insight.displayTitle,
                  style: AppTheme.headingLg(context, colors.textPrimary),
                ),
                const SizedBox(height: 8),

                // Section: Source Info
                Row(
                  children: [
                    Icon(Icons.link_outlined, color: colors.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Source: ${insight.displaySource}',
                      style: AppTheme.bodySm(context, colors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, HH:mm').format(insight.displayTimestamp),
                      style: AppTheme.monoSm(context, colors.textSecondary),
                    ),
                  ],
                ),
                const CustomDivider(),

                // Section: Key Facts (Bulleted List)
                Text(
                  'EXTRACTED KEY FACTS',
                  style: AppTheme.caption(context, colors.textSecondary).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                ...insight.displayFacts.map((fact) => _buildFactItem(context, fact)),
                const SizedBox(height: 24),

                // Section: Impact Analysis Card
                Text(
                  'SYSTEM OVERVIEW & IMPACT ASSESSMENT',
                  style: AppTheme.caption(context, colors.textSecondary).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: colors.accentPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Why This Matters',
                            style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        insight.displayImpactText,
                        style: AppTheme.bodySm(context, colors.textSecondary).copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section: Implications list
                if (insight.displayImplications.isNotEmpty) ...[
                  Text(
                    'REAL-WORLD IMPLICATIONS',
                    style: AppTheme.caption(context, colors.textSecondary).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...insight.displayImplications.map((imp) => _buildImplicationRow(context, imp)),
                  const SizedBox(height: 24),
                ],

                // Section: Recommended Actions
                Text(
                  'RECOMMENDED MITIGATION ACTIONS',
                  style: AppTheme.caption(context, colors.textSecondary).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                if (recommendedActions.isEmpty)
                  CustomCard(
                    child: Center(
                      child: Text(
                        'No custom mitigation scripts compiled.',
                        style: AppTheme.bodySm(context, colors.textSecondary),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recommendedActions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final action = recommendedActions[index];
                      return ActionCard(
                        action: action,
                        onSimulate: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ActionSimulationScreen(action: action),
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Section: Agent Attribution
                _buildAgentAttribution(context),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Sticky Bottom CTA button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border(top: BorderSide(color: colors.borderColor, width: 1)),
              ),
              child: PrimaryButton(
                text: 'SIMULATE TOP ACTION',
                width: double.infinity,
                onPressed: recommendedActions.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ActionSimulationScreen(action: recommendedActions.first),
                          ),
                        );
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactItem(BuildContext context, String fact) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(color: colors.accentPrimary, fontSize: 18, height: 1.1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact,
              style: AppTheme.bodySm(context, colors.textPrimary).copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImplicationRow(BuildContext context, ImplicationItem item) {
    final colors = AppTheme.of(context);
    
    IconData getIcon() {
      switch (item.displayIcon) {
        case 'trending_down':
          return Icons.trending_down;
        case 'schedule':
          return Icons.schedule;
        case 'money_off':
          return Icons.money_off;
        case 'swap_horiz':
          return Icons.swap_horiz;
        case 'warning':
          return Icons.warning_amber_outlined;
        case 'verified_user':
          return Icons.verified_user_outlined;
        default:
          return Icons.info_outline;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(getIcon(), color: colors.accentSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.displayText,
              style: AppTheme.bodySm(context, colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentAttribution(BuildContext context) {
    final colors = AppTheme.of(context);
    return Row(
      children: [
        Icon(Icons.verified, color: colors.accentSuccess, size: 14),
        const SizedBox(width: 6),
        Text(
          'GENERATED BY: ',
          style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: insight.displayAgentsAttributed.map((agent) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Text(
                    agent,
                    style: AppTheme.caption(context, colors.textPrimary).copyWith(fontSize: 9),
                  ),
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }
}
