import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/cards.dart';
import '../widgets/charts.dart';
import 'dashboard_screen.dart';
import 'action_simulation_screen.dart';

class PortfolioStateScreen extends StatelessWidget {
  const PortfolioStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);

    // Filter pending vs simulated actions
    final pendingActions = apiState.actions.where((a) => a.displayStatus == 'pending').toList();
    final simulatedActions = apiState.actions.where((a) => a.displayStatus == 'simulated').toList();

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'PORTFOLIO STATE SANDBOX',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Balance Header
            _buildBalanceHeader(context, apiState),
            const SizedBox(height: 20),

            // Section: Portfolio Allocations (Chart + Table)
            Text(
              'ALLOCATION BREAKDOWN',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            _buildAllocationChartTable(context, apiState),
            const SizedBox(height: 24),

            // Section: Sandbox Action Lists
            Text(
              'PENDING SIMULATIONS (${pendingActions.length})',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            if (pendingActions.isEmpty)
              CustomCard(
                child: Center(
                  child: Text(
                    'No pending actions. Try running a pipeline scenario first!',
                    style: AppTheme.bodySm(context, colors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingActions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final action = pendingActions[index];
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

            // Section: Already Simulated Actions
            if (simulatedActions.isNotEmpty) ...[
              Text(
                'COMPLETED SIMULATIONS (${simulatedActions.length})',
                style: AppTheme.caption(context, colors.textSecondary).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: simulatedActions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final action = simulatedActions[index];
                  return ActionCard(
                    action: action,
                    onSimulate: () {}, // Simulated already
                  );
                },
              ),
              const SizedBox(height: 20),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);
    final portfolio = state.portfolioState;
    final changes = state.actions.where((a) => a.displayStatus == 'simulated').length;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NET ASSET VALUE',
                style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
              ),
              if (changes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.accentSuccess),
                  ),
                  child: Text(
                    'MUTATED STATE',
                    style: AppTheme.caption(context, colors.accentSuccess).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '\$${portfolio.displayTotalValue.toStringAsRange()}',
            style: AppTheme.headingLg(context, colors.accentPrimary).copyWith(
              fontFamily: 'Orbitron',
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text(
                'Risk Score: ${portfolio.displayRiskScore.toStringAsFixed(0)} (${portfolio.displayRiskLevel})',
                style: AppTheme.caption(context, colors.textSecondary),
              ),
              const Spacer(),
              Text(
                'Cash Reserve: \$${(portfolio.displayTotalValue * 0.15).toStringAsRange()}',
                style: AppTheme.monoSm(context, colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationChartTable(BuildContext context, ApiService state) {
    final colors = AppTheme.of(context);
    final portfolio = state.portfolioState;

    return CustomCard(
      child: Column(
        children: [
          PortfolioPieChart(assets: portfolio.displayAssets),
          const SizedBox(height: 16),
          // Allocations State Matrix Table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.borderColor, width: 1)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('ASSET', style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('ALLOC %', style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('VALUE (USD)', textAlign: TextAlign.right, style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              ...portfolio.displayAssets.map((asset) {
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.borderColor, width: 0.5)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(asset.displayName, style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('${asset.displayAllocationPercent.toStringAsFixed(1)}%', style: AppTheme.monoSm(context, colors.textSecondary)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('\$${asset.displayValue.toStringAsRange()}', textAlign: TextAlign.right, style: AppTheme.monoSm(context, colors.textPrimary)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
