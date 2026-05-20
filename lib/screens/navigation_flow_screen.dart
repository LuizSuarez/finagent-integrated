import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/cards.dart';

class NavigationFlowScreen extends StatefulWidget {
  const NavigationFlowScreen({super.key});

  @override
  State<NavigationFlowScreen> createState() => _NavigationFlowScreenState();
}

class _NavigationFlowScreenState extends State<NavigationFlowScreen> {
  int _activeFlow = 0; // 0=Flow 1, 1=Flow 2, 2=Flow 3

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          '🗺️ FIGMA NAVIGATION MAP',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECT SPECIFIC USER FLOW PATH',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            _buildFlowToggle(context),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FLOW DESCRIPTION',
                      style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    _buildFlowDescriptionCard(context),
                    const SizedBox(height: 20),

                    Text(
                      'INTERACTIVE FLOWCHART STEPS',
                      style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildInteractiveFlowSteps(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowToggle(BuildContext context) {
    final colors = AppTheme.of(context);
    final flows = ['FLOW 1: INGESTION', 'FLOW 2: SIMULATE', 'FLOW 3: ANALYTICS'];

    return Row(
      children: List.generate(3, (index) {
        final isSel = _activeFlow == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _activeFlow = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == 2 ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? colors.bgElevated : colors.bgSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSel ? colors.accentPrimary : colors.borderColor,
                  width: 1.2,
                ),
              ),
              child: Text(
                flows[index],
                style: AppTheme.caption(context, isSel ? colors.accentPrimary : colors.textSecondary).copyWith(
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 8.5,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFlowDescriptionCard(BuildContext context) {
    final colors = AppTheme.of(context);
    
    String title = '';
    String desc = '';
    switch (_activeFlow) {
      case 0:
        title = 'Content Ingestion & Pipeline Ingest';
        desc = 'Analyzes the process of uploading documents/text, running the sequential 8-agent intelligence pipeline with real-time logs, extracting structured insights, and mapping severity indicators.';
        break;
      case 1:
        title = 'Sandbox Simulation & State Mutation';
        desc = 'Tracks the simulation workflow where recommended mitigation actions are applied to sandbox environments. Evaluates before/after state diff values and logs variable changes.';
        break;
      case 2:
        title = 'Analytics & Administrative Configurations';
        desc = 'Coordinates historical risk tracking, communication draft extraction from notifications, dynamic theme switching, connection tests, and UX edge cases (Skeletons/Error States).';
        break;
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.bodyMd(context, colors.accentPrimary).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: AppTheme.bodySm(context, colors.textSecondary).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveFlowSteps(BuildContext context) {
    List<FlowStepNode> steps = [];

    switch (_activeFlow) {
      case 0:
        steps = [
          FlowStepNode(label: 'Splash Screen', sub: 'Triggers breathing glowing logo sequence.', icon: Icons.settings_input_component),
          FlowStepNode(label: 'Onboarding Carousel', sub: 'Slides describing system features.', icon: Icons.view_carousel),
          FlowStepNode(label: 'Dashboard Feed', sub: 'Central operations command deck.', icon: Icons.dashboard),
          FlowStepNode(label: 'Input Screen (New Analysis)', sub: 'Paste Text / scrape URL / upload PDF.', icon: Icons.add_circle_outline),
          FlowStepNode(label: 'Pipeline Running', sub: 'Animated vertical stepper & WebSocket console.', icon: Icons.sync),
          FlowStepNode(label: 'Insight Report', sub: 'Extracted facts & severity impact sheets.', icon: Icons.description),
          FlowStepNode(label: 'Action Simulation', sub: 'Sandbox testing of mitigation strategies.', icon: Icons.science_outlined),
        ];
        break;
      case 1:
        steps = [
          FlowStepNode(label: 'Dashboard Feed', sub: 'View pending actions recommended by agents.', icon: Icons.dashboard),
          FlowStepNode(label: 'Action Card Trigger', sub: 'Click "Simulate" on any recommended action.', icon: Icons.play_arrow),
          FlowStepNode(label: 'Action Sandbox Panel', sub: 'Exposes current baseline system variables.', icon: Icons.lock_open),
          FlowStepNode(label: 'Simulation execution', sub: 'Renders progress bars & system write logs.', icon: Icons.sync),
          FlowStepNode(label: 'Before/After Diff State', sub: 'Collapsible comparison columns.', icon: Icons.compare_arrows),
          FlowStepNode(label: 'Audit Trace logs', sub: 'Detailed timeline of which agents generated data.', icon: Icons.history),
        ];
        break;
      case 2:
        steps = [
          FlowStepNode(label: 'Dashboard Feed', sub: 'Shows notification alerts with bell icon.', icon: Icons.notifications),
          FlowStepNode(label: 'Notification Hub', sub: 'List of alerts and autonomous comm drafts.', icon: Icons.mail_outline),
          FlowStepNode(label: 'Communications Modal', sub: 'Copy draft text built by AI Agents.', icon: Icons.content_copy),
          FlowStepNode(label: 'Settings Screen', sub: 'Switch theme modes, presets and backend endpoints.', icon: Icons.settings),
          FlowStepNode(label: 'UX States Gallery', sub: 'Preview loading shimmers and connection errors.', icon: Icons.grid_view),
        ];
        break;
    }

    final colors = AppTheme.of(context);

    return Column(
      children: List.generate(steps.length, (index) {
        final node = steps[index];
        final isLast = index == steps.length - 1;

        return Column(
          children: [
            CustomCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(node.icon, color: colors.accentPrimary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.label,
                          style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          node.sub,
                          style: AppTheme.caption(context, colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Icon(Icons.arrow_downward, color: colors.borderColor, size: 18),
              ),
          ],
        );
      }),
    );
  }
}

class FlowStepNode {
  final String label;
  final String sub;
  final IconData icon;

  FlowStepNode({
    required this.label,
    required this.sub,
    required this.icon,
  });
}
