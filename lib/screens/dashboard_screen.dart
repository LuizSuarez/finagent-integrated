import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/cards.dart';
import '../widgets/charts.dart';
import '../widgets/feedback.dart';
import '../widgets/state_display.dart';
import 'main_shell.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'insight_detail_screen.dart';
import 'action_simulation_screen.dart';
import 'pipeline_running_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _actionScrollController = ScrollController();
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
    _actionScrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (!_actionScrollController.hasClients) return;
    Future.doWhile(() async {
      if (!_isAutoScrolling) return false;
      await Future.delayed(const Duration(milliseconds: 40));
      if (!_actionScrollController.hasClients || !_isAutoScrolling) return false;

      final maxScroll = _actionScrollController.position.maxScrollExtent;
      final currentScroll = _actionScrollController.position.pixels;

      if (currentScroll >= maxScroll - 0.5) {
        _actionScrollController.jumpTo(0);
      } else {
        _actionScrollController.jumpTo(currentScroll + 0.8);
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'FINAGENT',
              style: AppTheme.headingLg(context, colors.textPrimary).copyWith(letterSpacing: 2.0),
            ),
            const SizedBox(width: 12),
            // WebSocket live connection status
            WebSocketIndicator(isLive: apiState.settings.displayEnableWebsocket),
          ],
        ),
        actions: [
          // Settings button
          IconButton(
            icon: Icon(Icons.settings, color: colors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, color: colors.textSecondary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              // Unread dot
              if (apiState.notifications.any((element) => !element.displayIsRead))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accentDanger,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Pipeline Status
              _buildPipelineStatusCard(context, apiState),
              const SizedBox(height: 20),

              // Section: Quick Input Bar
              _buildQuickInputBar(context),
              const SizedBox(height: 20),

              // Section: Risk Overview & Portfolio Snapshot side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 11,
                    child: _buildRiskOverview(context, apiState),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 12,
                    child: _buildPortfolioSnapshot(context, apiState),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Recent Action Cards (Horizontal Scroll)
              _buildRecentActions(context, apiState),
              const SizedBox(height: 24),

              // Section: Insights Feed (Last 5)
              _buildInsightsFeed(context, apiState),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineStatusCard(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);
    final isRunning = state.isPipelineRunning;

    return CustomCard(
      hasGlow: isRunning,
      glowColor: colors.accentPrimary.withOpacity(0.2),
      onTap: () {
        if (isRunning) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PipelineRunningScreen(rawContent: 'Running Pipeline...')),
          );
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PIPELINE STATUS',
                      style: AppTheme.caption(context, colors.textSecondary).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AgentStatusDot(status: isRunning ? 'thinking' : 'waiting'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isRunning ? 'ANALYZING INGESTED DATA...' : 'SYSTEM IDLE',
                  style: AppTheme.headingMd(context, isRunning ? colors.accentWarning : colors.textSecondary).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isRunning) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Active: ${state.activeAgent}',
                    style: AppTheme.caption(context, colors.accentPrimary),
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(progress: state.pipelineProgress),
                ],
              ],
            ),
          ),
          if (isRunning)
            Icon(Icons.chevron_right, color: colors.accentPrimary)
        ],
      ),
    );
  }

  Widget _buildQuickInputBar(BuildContext context) {
    final colors = AppTheme.of(context);

    return CustomCard(
      backgroundColor: colors.bgElevated,
      onTap: () {
        // Switch shell to content input tab
        final shellState = context.findAncestorStateOfType<MainShellState>();
        shellState?.onTabSelected(1);
      },
      child: Row(
        children: [
          Icon(Icons.edit_note, color: colors.accentPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'What do you want to analyze today?',
              style: AppTheme.bodyMd(context, colors.textSecondary).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: colors.textSecondary, size: 14),
        ],
      ),
    );
  }

  Widget _buildRiskOverview(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);
    final portfolio = state.portfolioState;

    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            'RISK LEVEL',
            style: AppTheme.caption(context, colors.textSecondary).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          RiskGauge(
            riskScore: portfolio.displayRiskScore,
            riskLabel: portfolio.displayRiskLevel,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              portfolio.displayRiskExplanation,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.caption(context, colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSnapshot(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);
    final portfolio = state.portfolioState;

    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PORTFOLIO VALUE',
            style: AppTheme.caption(context, colors.textSecondary).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${portfolio.displayTotalValue.toStringAsRange()}',
            style: AppTheme.headingLg(context, colors.accentPrimary).copyWith(
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 12),
          PortfolioPieChart(assets: portfolio.displayAssets),
          const SizedBox(height: 12),
          // Top 2 assets lists
          ...portfolio.displayAssets.take(2).map((asset) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      asset.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(context, colors.textPrimary),
                    ),
                  ),
                  Text(
                    '\$${asset.displayValue.toStringAsRange()}',
                    style: AppTheme.monoSm(context, colors.textSecondary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentActions(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);
    final pendingActions = state.actions.where((a) => a.displayStatus == 'pending').toList();

    if (pendingActions.isEmpty) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isAutoScrolling = !_isAutoScrolling;
          if (_isAutoScrolling) {
            _startAutoScroll();
          }
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECOMMENDED ACTIONS',
                style: AppTheme.caption(context, colors.textSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                _isAutoScrolling ? '⚡ AUTO-SCROLLING (TAP TO PAUSE)' : '⏸️ PAUSED (TAP TO RESUME)',
                style: AppTheme.caption(context, _isAutoScrolling ? colors.accentPrimary : colors.textSecondary).copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: ListView.builder(
              controller: _actionScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: pendingActions.length * 50,
              itemBuilder: (context, index) {
                final action = pendingActions[index % pendingActions.length];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  child: ActionCard(
                    action: action,
                    isCompact: true,
                    onSimulate: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ActionSimulationScreen(action: action),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsFeed(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);
    final feed = state.insights.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT INSIGHTS FEED',
          style: AppTheme.caption(context, colors.textSecondary).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        if (feed.isEmpty)
          CustomCard(
            child: Center(
              child: Text(
                'No insights generated yet. Input content to start analysis.',
                style: AppTheme.bodySm(context, colors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feed.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final insight = feed[index];
              return InsightCard(
                insight: insight,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => InsightDetailScreen(insight: insight),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

// Quick helper to write dollar amounts with commas
extension DoubleFormatter on double {
  String toStringAsRange() {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}
