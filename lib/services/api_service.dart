import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/insight.dart';
import '../models/action_item.dart';
import '../models/agent_trace.dart';
import '../models/portfolio.dart';
import '../models/notification.dart';
import '../models/settings.dart';
import '../core/constants.dart';
import 'mock_data.dart';

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
    mockMode: true,
    backendUrl: AppConstants.defaultBackendUrl,
    preferredDomains: ['Business', 'Policy', 'Finance'],
  );
  AppSettings get settings => _settings;

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  // Portfolio State ( baseline system state )
  late PortfolioState _portfolioState;
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

  // Preset custom scenarios in memory
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
    // Populate defaults
    _portfolioState = MockData.getInitialPortfolioState();
    _insights = MockData.getInitialInsights();
    _actions = MockData.getInitialActions();
    _notifications = MockData.getInitialNotifications();
    _agentTraces = MockData.getAgentStepsForScenario('Sales Decline');
  }

  // --- Pipeline Simulation ---
  StreamSubscription? _pipelineTimer;

  void runPipeline(String scenarioName, String rawContent) {
    if (_isPipelineRunning) return;

    _isPipelineRunning = true;
    _pipelineProgress = 0.0;
    _pipelineLogs = [];
    _activeAgent = 'Starting Agent Matrix...';
    _agentTraces = MockData.getAgentStepsForScenario(scenarioName);
    notifyListeners();

    int stepIndex = 0;
    int logCounter = 0;

    // Simulate logs streaming
    const logInterval = Duration(milliseconds: 300);
    _pipelineLogs.add('[SYSTEM] Initializing Agentic Content-to-Action Pipeline...');
    _pipelineLogs.add('[SYSTEM] Ingesting content payload (${rawContent.length} chars)...');

    _pipelineTimer = Stream.periodic(logInterval).listen((_) {
      if (!_isPipelineRunning) return;

      logCounter++;
      
      // Update agent traces and pipeline step index
      int activeStep = min(stepIndex, _agentTraces.length - 1);
      
      // Update trace status
      List<AgentTrace> updatedTraces = [];
      for (int i = 0; i < _agentTraces.length; i++) {
        if (i < activeStep) {
          updatedTraces.add(AgentTrace(
            agentName: _agentTraces[i].agentName,
            iconName: _agentTraces[i].iconName,
            status: 'done',
            inputReceived: _agentTraces[i].inputReceived,
            outputProduced: _agentTraces[i].outputProduced,
            reasoning: _agentTraces[i].reasoning,
            timestamp: _agentTraces[i].timestamp,
            durationMs: _agentTraces[i].durationMs,
          ));
        } else if (i == activeStep) {
          updatedTraces.add(AgentTrace(
            agentName: _agentTraces[i].agentName,
            iconName: _agentTraces[i].iconName,
            status: 'running',
            inputReceived: _agentTraces[i].inputReceived,
            outputProduced: null,
            reasoning: _agentTraces[i].reasoning,
            timestamp: DateTime.now(),
            durationMs: _agentTraces[i].durationMs,
          ));
        } else {
          updatedTraces.add(_agentTraces[i]);
        }
      }
      _agentTraces = updatedTraces;
      
      final currentAgentObj = _agentTraces[activeStep];
      _activeAgent = currentAgentObj.displayAgentName;

      // Add dummy logs for agent activity
      if (logCounter % 3 == 1) {
        _pipelineLogs.add('[${currentAgentObj.displayAgentName}] Initializing reason sequence...');
      } else if (logCounter % 3 == 2) {
        _pipelineLogs.add('[${currentAgentObj.displayAgentName}] Ingest: ${currentAgentObj.displayInputReceived.substring(0, min(30, currentAgentObj.displayInputReceived.length))}...');
      } else {
        _pipelineLogs.add('[${currentAgentObj.displayAgentName}] Reasoning complete (took ${currentAgentObj.displayDurationMs}ms)');
        stepIndex++;
      }

      // Progress updating
      _pipelineProgress = min((stepIndex / _agentTraces.length), 1.0);

      // Finish logic
      if (stepIndex >= _agentTraces.length) {
        _isPipelineRunning = false;
        _pipelineProgress = 1.0;
        _activeAgent = 'Idle';
        _pipelineLogs.add('[SYSTEM] Pipeline complete. Extracted new insights and action points.');
        
        // Add final done state to all traces
        _agentTraces = _agentTraces.map((e) => AgentTrace(
          agentName: e.agentName,
          iconName: e.iconName,
          status: 'done',
          inputReceived: e.inputReceived,
          outputProduced: e.outputProduced ?? 'Successfully produced scenario tokens.',
          reasoning: e.reasoning,
          timestamp: e.timestamp,
          durationMs: e.durationMs,
        )).toList();

        // Inject new insight and actions generated from mock data scenarios
        final results = MockData.getPipelineResults(scenarioName);
        final newInsight = results['insight'] as Insight;
        final newActions = results['actions'] as List<ActionItem>;

        _insights.insert(0, newInsight);
        _actions.insertAll(0, newActions);

        // System Alert Notification
        _notifications.insert(0, AppNotification(
          id: 'not_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Pipeline Ingestion Finished',
          body: 'Generated insight: "${newInsight.displayTitle}" and recommended ${newActions.length} actions.',
          category: 'pipeline',
          isRead: false,
          timestamp: DateTime.now(),
        ));

        _pipelineTimer?.cancel();
      }

      notifyListeners();
    });
  }

  void cancelPipeline() {
    if (!_isPipelineRunning) return;
    _pipelineTimer?.cancel();
    _isPipelineRunning = false;
    _activeAgent = 'Cancelled';
    _pipelineLogs.add('[SYSTEM] Pipeline cancelled by operator.');
    
    // Set running trace to error
    _agentTraces = _agentTraces.map((e) => AgentTrace(
      agentName: e.agentName,
      iconName: e.iconName,
      status: e.status == 'running' ? 'error' : e.status,
      inputReceived: e.inputReceived,
      outputProduced: e.status == 'running' ? 'Cancelled by operator' : e.outputProduced,
      reasoning: e.reasoning,
      timestamp: e.timestamp,
      durationMs: e.durationMs,
    )).toList();

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
    final totalSteps = action.displaySimulationSteps.length;

    _simulationLogs.add('[SIMULATOR] Launching system simulation sandbox...');
    _simulationLogs.add('[SIMULATOR] Targeting core interface: "${action.displayTargetSystem}"');

    _simulationTimer = Stream.periodic(const Duration(milliseconds: 600)).listen((_) {
      if (!_isSimulationRunning) return;

      if (stepIndex < totalSteps) {
        _simulationLogs.add('[SIMULATOR] [OK] ${action.displaySimulationSteps[stepIndex]}');
        stepIndex++;
        _simulationProgress = stepIndex / totalSteps;
      } else {
        _isSimulationRunning = false;
        _isSimulationComplete = true;
        _simulationProgress = 1.0;
        _simulationLogs.add('[SIMULATOR] Applying state mutation diff matrices...');
        _simulationLogs.add('[SIMULATOR] Simulation completed. Baseline metrics mutated.');

        // Update action status to simulated
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
              simulationSteps: act.simulationSteps,
              metricName: act.metricName,
              metricValue: act.metricValue,
              isPositiveMetric: act.isPositiveMetric,
              status: 'simulated',
              simulatedAt: DateTime.now(),
            );
          }
          return act;
        }).toList();

        // Mutate System Portfolio State
        _mutateSystemState(action);

        // Trigger Notification
        _notifications.insert(0, AppNotification(
          id: 'not_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Action Simulation Complete',
          body: 'Action "${action.displayTitle}" has successfully simulated outcome ${action.displayMetricValue} on target systems.',
          category: 'action',
          isRead: false,
          timestamp: DateTime.now(),
        ));

        // If specific drafts are triggered, inject drafted comms
        if (action.id == 'act_sc_01' || action.id == 'act_01') {
          _notifications.insert(0, AppNotification(
            id: 'not_draft_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Marketing Draft Created',
            body: 'AI-generated campaign newsletter is ready for review in notifications.',
            category: 'draft',
            isRead: false,
            timestamp: DateTime.now(),
            draftRecipient: 'marketing.distribution@finagent.ai',
            draftSubject: '[PROMOTIONAL DRAFT] Q2 Retail Discount Promotion - Lahore',
            draftBody: 'Hey Retail Partners,\n\nIn response to inventory levels in Lahore matching 92% capacity, we are introducing a temporary 15% discount on bulk logistics orders.\n\nCode: LAHORE-RESTOCK-Q2\nDuration: 14 Days.\n\nBest,\nAutonomous FinAgent System',
          ));
        }

        _simulationTimer?.cancel();
      }
      notifyListeners();
    });
  }

  void _mutateSystemState(ActionItem action) {
    double riskDelta = action.displayIsPositiveMetric ? -12.0 : 8.0;
    double currentRisk = _portfolioState.displayRiskScore;
    double newRisk = max(5.0, min(95.0, currentRisk + riskDelta));
    String newRiskLvl = newRisk < 30 ? 'Low' : (newRisk < 65 ? 'Medium' : 'High');

    double valDelta = action.id == 'act_sc_03' || action.id == 'act_03' ? 24500.0 : -8500.0;
    double newValue = _portfolioState.displayTotalValue + valDelta;

    List<ActiveCampaign> currentCampaigns = List.from(_portfolioState.displayActiveCampaigns);
    if (action.displayType == 'Campaign') {
      currentCampaigns.add(ActiveCampaign(
        name: action.displayTitle,
        status: 'Active',
        projectedReach: 5000 + (Random().nextInt(3000)),
      ));
    }

    Map<String, double> updatedPricing = Map.from(_portfolioState.displayPricingTable);
    if (action.displayType == 'Pricing Update') {
      // Surcharge adjustment standard SKU
      updatedPricing['Standard SKU-A'] = 54.99;
      updatedPricing['Logistics Tariff/km'] = 1.65;
    }

    // Adjust allocation percentages
    List<AssetRow> updatedAssets = _portfolioState.displayAssets.map((asset) {
      if (asset.displayName == 'Logistics Fleet') {
        return AssetRow(
          name: asset.name,
          allocationPercent: asset.allocationPercent,
          value: asset.value! + valDelta * 0.4,
          riskLevel: newRiskLvl,
        );
      }
      return asset;
    }).toList();

    _portfolioState = PortfolioState(
      totalValue: newValue,
      riskScore: newRisk,
      riskLevel: newRiskLvl,
      riskExplanation: 'State modified by simulation trace. Risk levels optimized: ${action.displayTitle} executed in sandbox.',
      assets: updatedAssets,
      activeCampaigns: currentCampaigns,
      pricingTable: updatedPricing,
    );
  }

  void resetPortfolio() {
    _portfolioState = MockData.getInitialPortfolioState();
    _actions = MockData.getInitialActions();
    _insights = MockData.getInitialInsights();
    notifyListeners();
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
    _pipelineTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
