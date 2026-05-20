import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../widgets/buttons.dart';
import '../widgets/inputs.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import 'states_gallery_screen.dart';
import 'navigation_flow_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _scenarioNameController = TextEditingController();
  final TextEditingController _scenarioContentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final apiState = Provider.of<ApiService>(context, listen: false);
    _urlController.text = apiState.settings.displayBackendUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _scenarioNameController.dispose();
    _scenarioContentController.dispose();
    super.dispose();
  }

  void _showAddScenarioDialog(BuildContext context, ApiService apiState) {
    final colors = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.bgElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colors.borderColor),
          ),
          title: Text(
            'ADD CUSTOM SCENARIO',
            style: AppTheme.headingMd(context, colors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InputField(
                  label: 'Scenario Name',
                  placeholder: 'e.g. Price Wars',
                  controller: _scenarioNameController,
                ),
                const SizedBox(height: 12),
                TextArea(
                  label: 'Scenario Content / Text',
                  placeholder: 'Specify what logs our agents should analyze...',
                  controller: _scenarioContentController,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CANCEL',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _scenarioNameController.text.trim();
                final content = _scenarioContentController.text.trim();
                if (name.isNotEmpty && content.isNotEmpty) {
                  apiState.addCustomScenario(name, content);
                  _scenarioNameController.clear();
                  _scenarioContentController.clear();
                  Navigator.of(context).pop();
                  ToastService.showSuccess(context, 'Custom scenario added.');
                } else {
                  ToastService.showError(context, 'Please fill in all fields.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.black,
              ),
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);
    final settings = apiState.settings;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: AppTheme.headingMd(context, colors.textPrimary).copyWith(letterSpacing: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Profile Card
            _buildProfileCard(context),
            const SizedBox(height: 24),

            // Navigation Gallery links
            Text(
              'UX UTILITIES',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'STATES GALLERY',
                    icon: Icons.grid_view_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const StatesGalleryScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    text: 'FLOW MAP',
                    icon: Icons.map_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const NavigationFlowScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Theme Toggle
            Text(
              'INTERFACE PREFERENCES',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            CustomCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Theme Mode',
                        style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        apiState.isDarkTheme ? 'Cyberpunk Dark' : 'Professional Light',
                        style: AppTheme.caption(context, colors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      apiState.isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                      color: colors.accentPrimary,
                    ),
                    onPressed: () {
                      apiState.toggleTheme();
                      ToastService.showInfo(
                        context,
                        apiState.isDarkTheme ? 'Switched to Cyberpunk Dark Theme' : 'Switched to Professional Light Theme',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Pipeline Config
            Text(
              'PIPELINE CORE CONTROLS',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            CustomCard(
              child: Column(
                children: [
                  _buildToggleRow(
                    context,
                    label: 'Auto-run on Input Submit',
                    val: settings.displayAutoRun,
                    onChanged: (v) {
                      apiState.updateSettings(settings.copyWith(autoRun: v));
                    },
                  ),
                  const Divider(),
                  _buildToggleRow(
                    context,
                    label: 'Enable WebSocket Live Feed',
                    val: settings.displayEnableWebsocket,
                    onChanged: (v) {
                      apiState.updateSettings(settings.copyWith(enableWebsocket: v));
                    },
                  ),
                  const Divider(),
                  _buildToggleRow(
                    context,
                    label: 'Mock Mode (Simulated Data)',
                    val: settings.displayMockMode,
                    onChanged: (v) {
                      apiState.updateSettings(settings.copyWith(mockMode: v));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Scenario Management
            Text(
              'SCENARIO CONGESTION MANAGEMENT',
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
                  ...apiState.allScenarios.keys.map((scName) {
                    final isCustom = apiState.allScenarios.containsKey(scName) &&
                        !AppConstants.scenarios.containsKey(scName);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            scName,
                            style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (isCustom)
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: colors.accentDanger, size: 18),
                              onPressed: () {
                                apiState.deleteScenario(scName);
                                ToastService.showInfo(context, 'Deleted scenario: $scName');
                              },
                            )
                          else
                            Text(
                              'PRESET',
                              style: AppTheme.caption(context, colors.textSecondary).copyWith(fontSize: 9),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    text: '+ ADD CUSTOM SCENARIO',
                    width: double.infinity,
                    onPressed: () => _showAddScenarioDialog(context, apiState),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: API Connections
            Text(
              'NODE INTEGRATION STATUS',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            CustomCard(
              child: Column(
                children: [
                  _buildConnectionRow(context, 'Google Antigravity Connector', true),
                  const Divider(),
                  _buildConnectionRow(context, 'Firebase Analytics Hub', true),
                  const Divider(),
                  _buildConnectionRow(context, 'World News Aggregator (API)', true),
                  const Divider(),
                  _buildConnectionRow(context, 'National Transport RSS Gateway', true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Backend Config
            Text(
              'API GATEWAY CONFIGURATION',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            InputField(
              label: 'Server Endpoint URL',
              controller: _urlController,
              placeholder: 'https://api.finagent.ai/v1',
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              text: 'SAVE BACKEND CONFIG',
              onPressed: () {
                apiState.updateSettings(settings.copyWith(backendUrl: _urlController.text));
                ToastService.showSuccess(context, 'API endpoint saved.');
              },
            ),
            const SizedBox(height: 24),

            // Section: Danger Zone
            Text(
              'SYSTEM MAINTENANCE (DANGER ZONE)',
              style: AppTheme.caption(context, colors.accentDanger).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            CustomCard(
              backgroundColor: colors.accentDanger.withOpacity(0.03),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purge Mutated States',
                            style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Resets portfolio simulation deltas.',
                            style: AppTheme.caption(context, colors.textSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          apiState.resetPortfolio();
                          ToastService.showInfo(context, 'System baseline restored.');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: colors.accentDanger),
                        child: Text(
                          'RESET',
                          style: AppTheme.caption(context, Colors.white).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clear Sockets Logs',
                            style: AppTheme.bodySm(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Wipes out terminal stream histories.',
                            style: AppTheme.caption(context, colors.textSecondary),
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () {
                          apiState.clearAllLogs();
                          ToastService.showInfo(context, 'Terminal logs cleared.');
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.accentDanger),
                        ),
                        child: Text(
                          'CLEAR',
                          style: AppTheme.caption(context, colors.accentDanger).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section: App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'FINAGENT CONSOLE v1.0.4',
                    style: AppTheme.caption(context, colors.textSecondary).copyWith(letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      ToastService.showInfo(context, 'Fetching architecture manuals...');
                    },
                    child: Text(
                      'View Architecture Specifications',
                      style: AppTheme.caption(context, colors.accentPrimary).copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required String label,
    required bool val,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = AppTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodySm(context, colors.textPrimary),
        ),
        Switch(
          value: val,
          activeColor: colors.accentPrimary,
          activeTrackColor: colors.accentPrimary.withOpacity(0.3),
          inactiveThumbColor: colors.textSecondary,
          inactiveTrackColor: colors.bgElevated,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildConnectionRow(BuildContext context, String title, bool isConnected) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.bodySm(context, colors.textPrimary),
          ),
          Row(
            children: [
              AgentStatusDot(status: isConnected ? 'active' : 'error', size: 6),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'CONNECTED' : 'OFFLINE',
                style: AppTheme.caption(context, isConnected ? colors.accentSuccess : colors.accentDanger).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final colors = AppTheme.of(context);
    return CustomCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: colors.accentPrimary, width: 1.5),
            ),
            child: Icon(Icons.face_retouching_natural, color: colors.accentPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATOR CONSOLE',
                  style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Role: L3 Risk Analyst',
                  style: AppTheme.caption(context, colors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.accentSuccess),
            ),
            child: Text(
              'ACTIVE NODE',
              style: AppTheme.caption(context, colors.accentSuccess).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
