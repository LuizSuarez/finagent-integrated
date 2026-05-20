import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/navigation.dart';
import 'dashboard_screen.dart';
import 'content_input_screen.dart';
import 'agent_trace_screen.dart';
import 'portfolio_state_screen.dart';
import 'analytics_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;

  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    // List of tab pages
    final List<Widget> pages = [
      const DashboardScreen(),
      const ContentInputScreen(),
      const AgentTraceScreen(),
      const PortfolioStateScreen(),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: onTabSelected,
      ),
    );
  }
}
