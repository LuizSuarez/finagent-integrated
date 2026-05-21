import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../models/action_item.dart';
import '../models/agent_trace.dart';
import '../models/portfolio.dart';
import '../models/notification.dart';
import '../models/settings.dart';
import '../core/constants.dart';

class ApiService extends ChangeNotifier {
  // Theme state
  bool _isDarkTheme = true;
  bool get isDarkTheme => _isDarkTheme;

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }

  // App Settings
  AppSettings _settings = const AppSettings(
    autoRun: true,
    enableWebsocket: true,
    mockMode: false,
    backendUrl: 'http://localhost:8000',
    preferredDomains: ['Business', 'Policy', 'Finance'],
  );
  AppSettings get settings => _settings;

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  // Portfolio State ( baseline system state )
  PortfolioState _portfolioState = const PortfolioState(
    totalValue: 0.0,
    riskScore: 0.0,
    riskLevel: 'Unknown',
    riskExplanation: 'Awaiting real data from backend...',
    assets: [],
    activeCampaigns: [],
    pricingTable: {},
  );
  PortfolioState get portfolioState => _portfolioState;

  // Data lists
  List<Insight> _insights = [];
  List<Insight> get insights => _insights;

  List<ActionItem> _actions = [];
  List<ActionItem> get actions => _actions;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  List<AgentTrace> _agentTraces = [];
  List<AgentTrace> get agentTraces => _agentTraces;

  // Pipeline Running State
  bool _isPipelineRunning = false;
  bool get isPipelineRunning => _isPipelineRunning;

  double _pipelineProgress = 0.0;
  double get pipelineProgress => _pipelineProgress;

  String _activeAgent = 'Idle';
  String get activeAgent => _activeAgent;

  List<String> _pipelineLogs = [];
  List<String> get pipelineLogs => _pipelineLogs;

  // Simulation Running State
  bool _isSimulationRunning = false;
  bool get isSimulationRunning => _isSimulationRunning;

  bool _isSimulationComplete = false;
  bool get isSimulationComplete => _isSimulationComplete;

  List<String> _simulationLogs = [];
  List<String> get simulationLogs => _simulationLogs;

  double _simulationProgress = 0.0;
  double get simulationProgress => _simulationProgress;

  // Active scenario input state
  String _selectedDomain = 'Business';
  String get selectedDomain => _selectedDomain;
  void setDomain(String val) {
    _selectedDomain = val;
    notifyListeners();
  }

  String _selectedScenario = 'Custom';
  String get selectedScenario => _selectedScenario;
  void setScenario(String val) {
    _selectedScenario = val;
    notifyListeners();
  }

  final Map<String, String> _customScenarios = {};
  Map<String, String> get allScenarios => {
        ...AppConstants.scenarios,
        ..._customScenarios,
      };

  void addCustomScenario(String name, String content) {
    _customScenarios[name] = content;
    notifyListeners();
  }

  void deleteScenario(String name) {
    if (_customScenarios.containsKey(name)) {
      _customScenarios.remove(name);
      notifyListeners();
    }
  }

  // Constructor
  ApiService() {
    _fetchPortfolio();
  }

  Future<void> _fetchPortfolio() async {
    try {
      final res = await http.get(Uri.parse("${_settings.backendUrl}/api/v1/portfolio"));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Backend returns { portfolio: { holdings: {...}, risk_level, risk_score } }
        // OR legacy format { portfolio: { AAPL: {...}, FDX: {...} } }
        final portfolioObj = body['portfolio'];
        if (portfolioObj == null) return;

        // Detect nested holdings vs flat format
        Map<String, dynamic> holdingsMap;
        double riskScore = 25.0;
        String riskLevel = 'Low';
        String riskExplanation = 'Live portfolio data loaded.';

        if (portfolioObj is Map && portfolioObj.containsKey('holdings')) {
          // Nested format from backend
          holdingsMap = Map<String, dynamic>.from(portfolioObj['holdings']);
          riskScore = ((portfolioObj['risk_score'] as num?) ?? 0.25).toDouble() * 100;
          riskLevel = portfolioObj['risk_level'] ?? 'Low';
        } else if (portfolioObj is Map) {
          // Flat format — each key is an asset
          holdingsMap = Map<String, dynamic>.from(portfolioObj);
        } else {
          return;
        }

        double totalVal = 0;
        List<AssetRow> assets = [];
        holdingsMap.forEach((k, v) {
          if (v is Map) {
            double assetVal = (v['value'] as num? ?? 0).toDouble();
            double allocPct = (v['allocation_pct'] as num? ?? 0).toDouble();
            totalVal += assetVal;
            assets.add(AssetRow(
              name: k,
              allocationPercent: allocPct,
              value: assetVal,
              riskLevel: 'Medium',
            ));
          }
        });

        _portfolioState = PortfolioState(
          totalValue: totalVal,
          riskScore: riskScore,
          riskLevel: riskLevel,
          riskExplanation: totalVal > 0 ? riskExplanation : 'Awaiting real data from backend...',
          assets: assets,
          activeCampaigns: [],
          pricingTable: {},
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed fetching portfolio: \$e");
    }
  }

  WebSocketChannel? _channel;

  void runScenario(String scenarioId) async {
    if (_isPipelineRunning) return;

    _isPipelineRunning = true;
    _pipelineProgress = 0.0;
    _pipelineLogs = [];
    _activeAgent = 'Starting Agent Matrix...';
    _agentTraces = [];
    _actions.clear();
    _insights.clear();
    notifyListeners();

    final isLive = scenarioId == '__live__';
    final endpoint = isLive
        ? '${_settings.backendUrl}/api/v1/pipeline/run'
        : '${_settings.backendUrl}/api/v1/scenario/$scenarioId';

    _pipelineLogs.add('[SYSTEM] Triggering remote FastAPI Pipeline...');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final runId = data['run_id'];
        _pipelineLogs.add('[SYSTEM] Pipeline started. Run ID: $runId');

        _channel = WebSocketChannel.connect(
            Uri.parse('ws://localhost:8000/api/v1/stream'));
        _channel!.stream.listen((message) {
          final payload = jsonDecode(message);
          final type = payload['type'];

          if (type == 'connected') {
            _pipelineLogs.add('[SYSTEM] ${payload['message']}');
            notifyListeners();
          } else if (type == 'agent_progress') {
            _activeAgent = payload['agent_id'] ?? _activeAgent;
            _pipelineLogs.add('[$_activeAgent] Reasoning update received...');

            final tracesRaw =
                payload['trace_log'] as List<dynamic>? ?? [];
            _agentTraces = tracesRaw
                .map((e) => AgentTrace(
                      agentName: e['agent_id'],
                      iconName: 'smart_toy',
                      status: e['fallback_triggered'] == true ? 'error' : 'done',
                      inputReceived: 'Payload received',
                      outputProduced:
                          'Generated output with confidence ${e['confidence_score']}',
                      reasoning: (e['reasoning_trace'] as List<dynamic>?)
                          ?.join('\n'),
                      timestamp: DateTime.now(),
                      durationMs: e['execution_time_ms'],
                    ))
                .toList();

            _pipelineProgress = _agentTraces.length / 8.0;
            notifyListeners();
          } else if (type == 'pipeline_complete') {
            _isPipelineRunning = false;
            _pipelineProgress = 1.0;
            _activeAgent = 'Idle';
            _pipelineLogs.add('[SYSTEM] Pipeline complete.');

            final insightRaw = payload['insight'];
            if (insightRaw != null) {
              _insights.insert(
                  0,
                  Insight(
                    id: 'ins_${DateTime.now().millisecondsSinceEpoch}',
                    title: insightRaw['summary'] ?? 'Market Insight',
                    domain: 'Finance',
                    severity: insightRaw['severity'] ?? 'Medium',
                    timestamp: DateTime.now(),
                    source: 'FinAgent AI',
                    facts: (insightRaw['tags'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    impactText:
                        'Affecting: ${insightRaw['sector_focus']}',
                  ));
            }

            final execRaw = payload['execution'];
            if (execRaw != null && execRaw['trades'] != null) {
              for (var t in (execRaw['trades'] as List<dynamic>)) {
                _actions.insert(
                    0,
                    ActionItem(
                      id: 'act_${DateTime.now().millisecondsSinceEpoch}_${t['asset']}',
                      title: '${t['action']} ${t['asset']}',
                      type: 'Trade',
                      domain: 'Finance',
                      description:
                          'Execute ${t['action']} for ${t['quantity']} units at \$${t['exec_price']}',
                      targetSystem: 'Brokerage API',
                      metricName: 'Delta Value',
                      metricValue: '\$${t['delta_value']}',
                      isPositiveMetric: true,
                      status: 'pending',
                    ));
              }
            }

            _notifications.insert(
                0,
                AppNotification(
                  id: 'not_${DateTime.now().millisecondsSinceEpoch}',
                  title: 'Pipeline Finished',
                  body:
                      'Generated new insights and rebalanced portfolio.',
                  category: 'pipeline',
                  isRead: false,
                  timestamp: DateTime.now(),
                ));

            _fetchPortfolio();
            notifyListeners();
            _channel?.sink.close();
          }
        });
      } else {
        _isPipelineRunning = false;
        _pipelineLogs.add(
            '[ERROR] Failed to start pipeline: ${response.statusCode}');
        notifyListeners();
      }
    } catch (e) {
      _isPipelineRunning = false;
      _pipelineLogs.add('[ERROR] Exception: $e');
      notifyListeners();
    }
  }

  void runPipeline(String scenarioName, String rawContent) async {
    runScenario('__live__');
  }

  void cancelPipeline() {
    if (!_isPipelineRunning) return;
    _channel?.sink.close();
    _isPipelineRunning = false;
    _activeAgent = 'Cancelled';
    _pipelineLogs.add('[SYSTEM] Pipeline cancelled by operator.');
    notifyListeners();
  }

  // --- Simulation Simulation ---
  StreamSubscription? _simulationTimer;

  void executeActionSimulation(ActionItem action) {
    if (_isSimulationRunning) return;

    _isSimulationRunning = true;
    _isSimulationComplete = false;
    _simulationProgress = 0.0;
    _simulationLogs = [];
    notifyListeners();

    int stepIndex = 0;
    final steps = ['Validating trade parameters', 'Checking liquidity', 'Executing via API', 'Confirming fill'];
    final totalSteps = steps.length;

    _simulationLogs.add('[SIMULATOR] Launching system simulation sandbox...');
    _simulationLogs.add('[SIMULATOR] Targeting core interface: "\${action.displayTargetSystem}"');

    _simulationTimer = Stream.periodic(const Duration(milliseconds: 600)).listen((_) {
      if (!_isSimulationRunning) return;

      if (stepIndex < totalSteps) {
        _simulationLogs.add('[SIMULATOR] [OK] \${steps[stepIndex]}');
        stepIndex++;
        _simulationProgress = stepIndex / totalSteps;
      } else {
        _isSimulationRunning = false;
        _isSimulationComplete = true;
        _simulationProgress = 1.0;
        _simulationLogs.add('[SIMULATOR] Simulation completed. Baseline metrics mutated.');

        _actions = _actions.map((act) {
          if (act.id == action.id) {
            return ActionItem(
              id: act.id,
              title: act.title,
              type: act.type,
              domain: act.domain,
              description: act.description,
              targetSystem: act.targetSystem,
              beforeState: act.beforeState,
              afterState: act.afterState,
              simulationSteps: steps,
              metricName: act.metricName,
              metricValue: act.metricValue,
              isPositiveMetric: act.isPositiveMetric,
              status: 'simulated',
              simulatedAt: DateTime.now(),
            );
          }
          return act;
        }).toList();

        _notifications.insert(0, AppNotification(
          id: 'not_\${DateTime.now().millisecondsSinceEpoch}',
          title: 'Action Simulation Complete',
          body: 'Action "\${action.displayTitle}" has successfully simulated outcome \${action.displayMetricValue} on target systems.',
          category: 'action',
          isRead: false,
          timestamp: DateTime.now(),
        ));

        _simulationTimer?.cancel();
      }
      notifyListeners();
    });
  }

  void resetPortfolio() async {
    try {
      await http.post(Uri.parse("\${_settings.backendUrl}/api/v1/portfolio/reset"));
      _actions = [];
      _insights = [];
      _fetchPortfolio();
    } catch (e) {
      debugPrint("Error resetting portfolio: \$e");
    }
  }

  void markAllNotificationsAsRead() {
    _notifications = _notifications.map((e) => AppNotification(
      id: e.id,
      title: e.title,
      body: e.body,
      category: e.category,
      isRead: true,
      timestamp: e.timestamp,
      draftRecipient: e.draftRecipient,
      draftSubject: e.draftSubject,
      draftBody: e.draftBody,
    )).toList();
    notifyListeners();
  }

  void clearAllLogs() {
    _pipelineLogs = [];
    _simulationLogs = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
