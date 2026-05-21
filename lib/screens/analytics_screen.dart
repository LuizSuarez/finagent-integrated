import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/action_item.dart';
import '../services/api_service.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import '../widgets/state_display.dart';
import 'insight_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _dateRange = '7 Days'; // Today, 7 Days, 30 Days, All Time
  final ScrollController _statsScrollController = ScrollController();
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
    _statsScrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (!_statsScrollController.hasClients) return;
    Future.doWhile(() async {
      if (!_isAutoScrolling) return false;
      await Future.delayed(const Duration(milliseconds: 40));
      if (!_statsScrollController.hasClients || !_isAutoScrolling) return false;

      final maxScroll = _statsScrollController.position.maxScrollExtent;
      final currentScroll = _statsScrollController.position.pixels;

      if (currentScroll >= maxScroll - 0.5) {
        _statsScrollController.jumpTo(0);
      } else {
        _statsScrollController.jumpTo(currentScroll + 0.8);
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);

    // Compute stats from state
    final pipelinesRun = apiState.agentTraces.isNotEmpty
        ? (apiState.insights.length + 1)
        : apiState.insights.length;
    final insightsCount = apiState.insights.length;
    final simulatedCount = apiState.actions.where((a) => a.displayStatus == 'simulated').length;
    final pendingCount = apiState.actions.where((a) => a.displayStatus == 'pending').length;
    final simulatedActions = apiState.actions.where((a) => a.displayStatus == 'simulated').toList();

    // Chart break downs
    final Map<String, int> domainBreakdown = {};
    for (var insight in apiState.insights) {
      final dom = insight.displayDomain;
      domainBreakdown[dom] = (domainBreakdown[dom] ?? 0) + 1;
    }

    final Map<String, int> outcomeBreakdown = {
      'Trade': apiState.actions.where((a) => a.displayType.toLowerCase().contains('trade') && a.displayStatus == 'simulated').length,
      'Buy': apiState.actions.where((a) => a.displayTitle.toLowerCase().startsWith('buy') && a.displayStatus == 'simulated').length,
      'Sell': apiState.actions.where((a) => a.displayTitle.toLowerCase().startsWith('sell') && a.displayStatus == 'simulated').length,
    };

    // Sorted insights list (Top 5 by severity)
    final sortedInsights = List.from(apiState.insights);
    sortedInsights.sort((a, b) {
      int score(String sev) {
        switch (sev.toLowerCase()) {
          case 'critical': return 4;
          case 'high': return 3;
          case 'medium': return 2;
          case 'low': default: return 1;
        }
      }
      return score(b.displaySeverity).compareTo(score(a.displaySeverity));
    });

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'ANALYTICS ENGINE',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, color: colors.textSecondary),
            onPressed: () {
              ToastService.showInfo(context, 'Date range custom filter selected.');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Date Range Chips
            _buildDateRangeBar(context),
            const SizedBox(height: 20),

            // Section: Summary Stats (Horizontal scroll)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OPERATIONAL PERFORMANCE',
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
            _buildSummaryStatsRow(context, pipelinesRun, insightsCount, simulatedCount, pendingCount),
            const SizedBox(height: 24),

            // Section: Line Chart (Risk Trend)
            _buildLineChart(colors, apiState.portfolioState.displayRiskScore),
            const SizedBox(height: 16),

            // Section: Bar & Pie Charts
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 550;
                final bar = _buildBarChart(colors, domainBreakdown);
                final pie = _buildPieChart(colors, outcomeBreakdown);
                
                if (isNarrow) {
                  return Column(
                    children: [
                      bar,
                      const SizedBox(height: 16),
                      pie,
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: bar),
                      const SizedBox(width: 12),
                      Expanded(child: pie),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Section: Top Insights by Impact (Compact)
            Text(
              'TOP INSIGHTS BY SEVERITY',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedInsights.take(3).length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final insight = sortedInsights[index];
                return InsightCard(
                  insight: insight,
                  isCompact: true,
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
            const SizedBox(height: 24),

            // Section: Past Simulations
            Text(
              'PAST ACTION SIMULATION LOGS',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            _buildSimulationHistory(context, simulatedActions),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeBar(BuildContext context) {
    final colors = AppTheme.of(context);
    final options = ['Today', '7 Days', '30 Days', 'All Time'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSel = _dateRange == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                opt,
                style: AppTheme.caption(context, isSel ? Colors.black : colors.textSecondary).copyWith(
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSel,
              selectedColor: colors.accentPrimary,
              backgroundColor: colors.bgSurface,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _dateRange = opt;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryStatsRow(BuildContext context, int runs, int insights, int simulated, int pending) {
    final cards = [
      _buildStatCard(context, 'SIMULATIONS COMPLETED', '$simulated', Icons.science_outlined),
      _buildStatCard(context, 'AVG EXECUTION DURATION', '7.2s', Icons.timer_outlined),
      _buildStatCard(context, 'PIPELINES RUN', '$runs', Icons.settings_input_component),
      _buildStatCard(context, 'INSIGHTS EXTRACTED', '$insights', Icons.auto_graph),
      _buildStatCard(context, 'PENDING ACTIONS', '$pending', Icons.pending_actions_outlined),
    ];

    return GestureDetector(
      onTap: () {
        setState(() {
          _isAutoScrolling = !_isAutoScrolling;
          if (_isAutoScrolling) {
            _startAutoScroll();
          }
        });
      },
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          controller: _statsScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: cards.length * 500,
          itemBuilder: (context, index) {
            return cards[index % cards.length];
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String val, IconData icon) {
    final colors = AppTheme.of(context);

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.accentPrimary, size: 16),
            const SizedBox(height: 12),
            Text(
              val,
              style: AppTheme.headingLg(context, colors.textPrimary).copyWith(
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.caption(context, colors.textSecondary).copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationHistory(BuildContext context, List<ActionItem> actions) {
    final colors = AppTheme.of(context);

    if (actions.isEmpty) {
      return CustomCard(
        child: Center(
          child: Text(
            'No sandbox simulations executed in this timeframe.',
            style: AppTheme.bodySm(context, colors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: actions.map((act) {
          return TradeLogRow(
            actionType: act.displayTitle,
            target: act.displayTargetSystem,
            status: act.displayStatus,
            timestamp: act.simulatedAt ?? DateTime.now(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(AppThemeColors colors, double currentScore) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RISK SCORE TREND', style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 42), const FlSpot(1, 38), const FlSpot(2, 36), 
                      const FlSpot(3, 39), const FlSpot(4, 35), FlSpot(5, currentScore)
                    ],
                    isCurved: true,
                    color: colors.accentWarning,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.accentWarning.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(AppThemeColors colors, Map<String, int> data) {
    if (data.isEmpty) return const SizedBox();
    
    List<BarChartGroupData> barGroups = [];
    int i = 0;
    for (var entry in data.entries) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: colors.accentPrimary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        )
      );
      i++;
    }

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INSIGHTS BY DOMAIN', style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= data.keys.length || value.toInt() < 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data.keys.elementAt(value.toInt()).substring(0, 3).toUpperCase(),
                            style: AppTheme.caption(context, colors.textSecondary).copyWith(fontSize: 9),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(AppThemeColors colors, Map<String, int> data) {
    if (data.isEmpty) return const SizedBox();
    
    final sliceColors = [colors.accentSuccess, colors.accentWarning, colors.accentSecondary];
    
    List<PieChartSectionData> sections = [];
    int i = 0;
    for (var entry in data.entries) {
      if (entry.value > 0) {
        sections.add(
          PieChartSectionData(
            color: sliceColors[i % sliceColors.length],
            value: entry.value.toDouble(),
            title: '${entry.value}',
            radius: 40,
            titleStyle: AppTheme.monoSm(context, Colors.white).copyWith(fontWeight: FontWeight.bold),
          )
        );
        i++;
      }
    }

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(color: colors.borderColor, value: 1, title: '0', radius: 40));
    }

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIONS SIMULATED', style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: sections,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
