import '../models/insight.dart';
import '../models/action_item.dart';
import '../models/agent_trace.dart';
import '../models/portfolio.dart';
import '../models/notification.dart';

class MockData {
  // Initial system baseline portfolio state
  static PortfolioState getInitialPortfolioState() {
    return PortfolioState(
      totalValue: 1245600.0,
      riskScore: 34.0,
      riskLevel: 'Medium',
      riskExplanation: 'Nominal operational status. All supply lines functioning.',
      assets: [
        const AssetRow(name: 'Electronics Division', allocationPercent: 45.0, value: 560520.0, riskLevel: 'Medium'),
        const AssetRow(name: 'Logistics Fleet', allocationPercent: 25.0, value: 311400.0, riskLevel: 'Low'),
        const AssetRow(name: 'Retail Holdings', allocationPercent: 20.0, value: 249120.0, riskLevel: 'Low'),
        const AssetRow(name: 'Cash Reserves', allocationPercent: 10.0, value: 124560.0, riskLevel: 'Low'),
      ],
      activeCampaigns: [
        const ActiveCampaign(name: 'Standard Retargeting Q2', status: 'Active', projectedReach: 12500),
      ],
      pricingTable: {
        'Standard SKU-A': 49.99,
        'Premium SKU-B': 99.99,
        'Logistics Tariff/km': 1.50,
      },
    );
  }

  // Pre-configured mock lists
  static List<Insight> getInitialInsights() {
    return [
      Insight(
        id: 'ins_01',
        title: 'Q2 Retail Orders Decreased by 25% in Lahore',
        domain: 'Business',
        severity: 'High',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        source: 'Q2_Retail_Logistics.pdf',
        facts: const [
          'Lahore hub volume fell from 8.5k to 6.3k units.',
          'Last-mile delivery latency rose by 34 minutes.',
          'Customer satisfaction score (CSAT) fell to 3.9.'
        ],
        impactText: 'Volume drop compresses cash flow and reveals distribution friction. Fixed costs accrue despite lower throughput.',
        implications: const [
          ImplicationItem(icon: 'trending_down', text: '-5.4% regional gross revenue contraction projected.'),
          ImplicationItem(icon: 'schedule', text: 'Depot inventory capacity limit warning.'),
        ],
        associatedActionIds: const ['act_01', 'act_02'],
        agentsAttributed: const ['Input Intelligence Agent', 'Insight Extraction Agent', 'Decision Agent'],
      ),
      Insight(
        id: 'ins_02',
        title: 'Fuel Tariffs Escalated by 18% in Punjab Region',
        domain: 'Logistics',
        severity: 'Critical',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        source: 'Punjab Transport Gazette',
        facts: const [
          'Diesel price hiked to 272 PKR/liter.',
          'Partners demand 15% surcharge renegotiation.',
          'Highway toll taxation increased by 5%.'
        ],
        impactText: 'Logistics margins contract by 22% in 30 days without immediate rate adjustments or fleet rerouting.',
        implications: const [
          ImplicationItem(icon: 'money_off', text: 'Monthly transport costs rise by \$45k.'),
          ImplicationItem(icon: 'swap_horiz', text: 'Partner SLA default risk increases.'),
        ],
        associatedActionIds: const ['act_03'],
        agentsAttributed: const ['News Intelligence Agent', 'Portfolio Risk Agent', 'Decision Agent'],
      ),
      Insight(
        id: 'ins_03',
        title: 'Carbon Surcharge Guidelines Enforced',
        domain: 'Policy',
        severity: 'Medium',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        source: 'Environmental Policy Act 2026',
        facts: const [
          'Fossil fleet penalized at \$2.4 per carbon ton.',
          'Green logistics incentives unlocked for EV conversion.'
        ],
        impactText: 'Compliance directive. Actions needed on offsets to prevent regulatory flags.',
        implications: const [
          ImplicationItem(icon: 'verified_user', text: 'Q3 audit reports required.'),
        ],
        associatedActionIds: const ['act_04'],
        agentsAttributed: const ['Sentiment Analysis Agent', 'Decision Agent'],
      ),
    ];
  }

  static List<ActionItem> getInitialActions() {
    return [
      const ActionItem(
        id: 'act_01',
        title: 'Initiate Regional Discount Campaign',
        type: 'Campaign',
        domain: 'Business',
        description: 'Deploy automated 15% CRM discount on bulk orders (>150 units) to clear warehouse buffer stock.',
        targetSystem: 'CRM & Marketing Engine',
        beforeState: {
          'Campaign Status': 'Inactive',
          'Standard Volume / Day': '212 units',
          'Warehouse Inventory': '89% capacity',
        },
        afterState: {
          'Campaign Status': 'Active',
          'Standard Volume / Day': '265 units (Projected)',
          'Warehouse Inventory': '72% capacity (Projected)',
        },
        simulationSteps: [
          'Authenticating CRM credentials...',
          'Querying Lahore user cohort (N=1,420)...',
          'Deploying discount logic matrix (15% cap)...',
          'Testing API webhooks for email notifications...',
          'Drafting newsletter assets...',
          'Simulation complete. Ready for deployment.'
        ],
        metricName: 'Projected Inventory Reduction',
        metricValue: '-17.0%',
        isPositiveMetric: true,
        status: 'pending',
      ),
      const ActionItem(
        id: 'act_02',
        title: 'Re-route Lahore Fleet to Secondary Hub',
        type: 'Workflow Trigger',
        domain: 'Logistics',
        description: 'Reroute 30% of long-haul logistics fleet to suburban hubs to bypass primary terminal congestion.',
        targetSystem: 'Fleet Logistics Router',
        beforeState: {
          'Average Transit Latency': '124 min',
          'Fuel Waste / Route': '18.4L',
        },
        afterState: {
          'Average Transit Latency': '95 min (Projected)',
          'Fuel Waste / Route': '14.2L (Projected)',
        },
        simulationSteps: [
          'Fetching active vehicle telemetry...',
          'Simulating route alternate pipelines (N=4 options)...',
          'Calculating fuel consumption vectors...',
          'Drafting dispatcher guidelines notification...',
          'Simulation complete.'
        ],
        metricName: 'Latency Reduction',
        metricValue: '-23.4%',
        isPositiveMetric: true,
        status: 'pending',
      ),
      const ActionItem(
        id: 'act_03',
        title: 'Adjust Freight Logistics Tariffs',
        type: 'Pricing Update',
        domain: 'Finance',
        description: 'Apply 10% commercial tariff surcharge to offset diesel inflation and protect operational margins.',
        targetSystem: 'Pricing Engine Module',
        beforeState: {
          'Base Freight Rate / km': '1.50 USD',
          'Estimated Monthly Margin': '16.5%',
        },
        afterState: {
          'Base Freight Rate / km': '1.65 USD',
          'Estimated Monthly Margin': '16.2% (Defended)',
        },
        simulationSteps: [
          'Querying billing catalog tables...',
          'Simulating client elasticity (predicted churn: <1.2%)...',
          'Calculating contract amendment formulas...',
          'Simulation completed with margin safeguards.'
        ],
        metricName: 'Margin Preservation',
        metricValue: '98.2%',
        isPositiveMetric: true,
        status: 'pending',
      ),
    ];
  }

  static List<AppNotification> getInitialNotifications() {
    return [
      AppNotification(
        id: 'not_01',
        title: 'Analysis Pipeline Completed',
        body: 'Decision Agent finished evaluation on scenario: Sales Decline.',
        category: 'pipeline',
        isRead: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AppNotification(
        id: 'not_02',
        title: 'Critical Insight Generated',
        body: 'Fuel Tariffs Escalated by 18% in Punjab Region - high risk.',
        category: 'insight',
        isRead: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'not_03',
        title: 'Auto-Draft Available',
        body: 'Email draft to Lahore Fleet dispatcher prepared during Route Simulation.',
        category: 'draft',
        isRead: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        draftRecipient: 'dispatcher.lahore@fleetops.com',
        draftSubject: '[ACTION PROPOSED] Regional Fleet Re-Routing Allocation',
        draftBody: 'Hello Operations,\n\nFollowing autonomous analytics on local transit latencies, we recommend immediate diversion of 30% of long-haul vehicles. \n\nProposed Action: Divert to Suburban Terminal B.\nProjected Latency Reduction: 23%.\n\nPlease review simulation logs in FinAgent Dashboard to authorize.\n\nBest regards,\nAutonomous FinAgent system',
      ),
    ];
  }

  // Pre-configured agent steps for pipeline running simulation
  static List<AgentTrace> getAgentStepsForScenario(String scenarioTitle) {
    return [
      AgentTrace(
        agentName: 'Input Intelligence Agent',
        iconName: 'edit_note',
        status: 'waiting',
        inputReceived: 'Raw user document input stream.',
        outputProduced: 'Parsed lexical token payload.',
        reasoning: 'Filtering format tags, identifying financial and logistical entities.',
        durationMs: 420,
      ),
      AgentTrace(
        agentName: 'News Intelligence Agent',
        iconName: 'newspaper',
        status: 'waiting',
        inputReceived: 'Parsed token payload.',
        outputProduced: 'Cross-referenced transport publications.',
        reasoning: 'Searching database indices for matching news inflation factors.',
        durationMs: 780,
      ),
      AgentTrace(
        agentName: 'Sentiment Analysis Agent',
        iconName: 'psychology',
        status: 'waiting',
        inputReceived: 'Cross-referenced publications.',
        outputProduced: 'Sentiment Index Score: -0.42.',
        reasoning: 'Evaluating customer feedback logs for regional transit sentiment.',
        durationMs: 650,
      ),
      AgentTrace(
        agentName: 'Insight Extraction Agent',
        iconName: 'auto_graph',
        status: 'waiting',
        inputReceived: 'Sentiment Index Score.',
        outputProduced: 'Facts list and severity grades.',
        reasoning: 'Filtering noise, calculating threshold-based impact severities.',
        durationMs: 980,
      ),
      AgentTrace(
        agentName: 'Market Context Agent',
        iconName: 'pie_chart',
        status: 'waiting',
        inputReceived: 'Facts and severity grades.',
        outputProduced: 'Core index correlation maps.',
        reasoning: 'Retrieving logistics indexes to calculate margin impact.',
        durationMs: 820,
      ),
      AgentTrace(
        agentName: 'Portfolio Risk Agent',
        iconName: 'security',
        status: 'waiting',
        inputReceived: 'Index correlation maps.',
        outputProduced: 'Logistics fleet risk score shifts.',
        reasoning: 'Running Monte Carlo risk iterations on asset configurations.',
        durationMs: 1120,
      ),
      AgentTrace(
        agentName: 'Decision Agent',
        iconName: 'gavel',
        status: 'waiting',
        inputReceived: 'Logistics fleet risk shift.',
        outputProduced: 'Ranked mitigation recommendations.',
        reasoning: 'Performing cost-benefit analyses on route and pricing targets.',
        durationMs: 1350,
      ),
      AgentTrace(
        agentName: 'Trade Simulation Agent',
        iconName: 'insights',
        status: 'waiting',
        inputReceived: 'Ranked recommendations.',
        outputProduced: 'Simulated allocation metrics.',
        reasoning: 'Applying mock adjustments to routing and CRM pricing tables.',
        durationMs: 910,
      ),
    ];
  }

  // Returns full results package when a scenario pipeline completes
  static Map<String, dynamic> getPipelineResults(String scenarioTitle) {
    if (scenarioTitle == 'Sales Decline') {
      return {
        'insight': Insight(
          id: 'ins_sc_01',
          title: 'Lahore Hub Retail Transactions Dropped by 25%',
          domain: 'Business',
          severity: 'High',
          timestamp: DateTime.now(),
          source: 'Ingested Document Analysis',
          facts: const [
            'Depot inventory capacity has spiked to 92%.',
            'Transit SLA failure rose by 34 minutes.',
            'Retail purchase volume contracted by 12%.'
          ],
          impactText: 'Immediate cash flow threat. Warehouse capacity is at 92%. Liquidating excess inventory prevents wholesale receipt halts.',
          implications: const [
            ImplicationItem(icon: 'warning', text: 'Depot overflow requires renting storage.'),
            ImplicationItem(icon: 'trending_down', text: '-6.8% regional profit margin impact.'),
          ],
          associatedActionIds: const ['act_sc_01', 'act_sc_02'],
          agentsAttributed: const ['Input Intelligence Agent', 'Insight Extraction Agent', 'Decision Agent'],
        ),
        'actions': [
          const ActionItem(
            id: 'act_sc_01',
            title: 'Deploy Q2 Lahore Retail Promotion',
            type: 'Campaign',
            domain: 'Business',
            description: 'Trigger 15% retail bulk discount via CRM with free shipping to liquidate excess stock.',
            targetSystem: 'CRM & Marketing Console',
            beforeState: {
              'Active Campaign': 'None',
              'Inventory Overflow': '92%',
              'Daily Units Moved': '180 units',
            },
            afterState: {
              'Active Campaign': 'Q2 Lahore Discount (Active)',
              'Inventory Overflow': '70% (Simulated)',
              'Daily Units Moved': '240 units (Simulated)',
            },
            simulationSteps: [
              'Analyzing local retail catalog tables...',
              'Targeting low frequency cohorts...',
              'Drafting marketing assets...',
              'Simulating mock checkouts (+3.2% conversion)...',
              'Campaign script successfully verified.'
            ],
            metricName: 'Projected Inventory Reduction',
            metricValue: '-22.0%',
            isPositiveMetric: true,
            status: 'pending',
          ),
          const ActionItem(
            id: 'act_sc_02',
            title: 'Transition to Secondary Hub Depot B',
            type: 'Workflow Trigger',
            domain: 'Logistics',
            description: 'Reroute incoming freight containers to Depot B to mitigate primary warehouse constraints.',
            targetSystem: 'Fleet Logistics Router',
            beforeState: {
              'Primary Warehouse Load': '92%',
              'Secondary Depot Load': '14%',
            },
            afterState: {
              'Primary Warehouse Load': '80% (Projected)',
              'Secondary Depot Load': '38% (Projected)',
            },
            simulationSteps: [
              'Connecting to fleet router...',
              'Simulating fuel difference cost (+120 USD/route)...',
              'Confirming Depot B storage readiness...',
              'Drafting dispatcher notices.'
            ],
            metricName: 'Load Balance Improvement',
            metricValue: '+40.0%',
            isPositiveMetric: true,
            status: 'pending',
          ),
        ],
      };
    } else if (scenarioTitle == 'Fuel Price Hike') {
      return {
        'insight': Insight(
          id: 'ins_sc_02',
          title: 'Regional Diesel Tariff Surcharge Increased by 18%',
          domain: 'Finance',
          severity: 'Critical',
          timestamp: DateTime.now(),
          source: 'Automated RSS Feed Scraper',
          facts: const [
            'Fuel rate increased to 272 PKR/liter.',
            'Contractors refuse standard shipping rates.',
            'Monthly transport costs increased by \$45,000.'
          ],
          impactText: 'Compresses logistics fleet margins. Net profits contract by 22% in 30 days without pricing adjustments.',
          implications: const [
            ImplicationItem(icon: 'money_off', text: '+15% transport budget increase.'),
            ImplicationItem(icon: 'error_outline', text: 'SLA breach risks on cargo timelines.'),
          ],
          associatedActionIds: const ['act_sc_03'],
          agentsAttributed: const ['News Intelligence Agent', 'Portfolio Risk Agent', 'Decision Agent'],
        ),
        'actions': [
          const ActionItem(
            id: 'act_sc_03',
            title: 'Implement 10% Fuel Tariff Surcharge',
            type: 'Pricing Update',
            domain: 'Finance',
            description: 'Apply 10% invoice surcharge to client accounts to recover fuel cost overhead.',
            targetSystem: 'Contract Billing Engine',
            beforeState: {
              'Logistics Surcharge Rate': '0.0%',
              'Net Profit Margin': '16.5%',
            },
            afterState: {
              'Logistics Surcharge Rate': '10.0%',
              'Net Profit Margin': '16.1% (Stabilized)',
            },
            simulationSteps: [
              'Querying active client accounts list...',
              'Filtering client accounts by billing elasticity parameters...',
              'Drafting automatic pricing update notification letters...',
              'Simulating billing cycle billing output changes...',
              'Surcharge simulation validated successfully.'
            ],
            metricName: 'Margin Defense Delta',
            metricValue: '+97.5%',
            isPositiveMetric: true,
            status: 'pending',
          )
        ],
      };
    } else {
      // General custom or fallback
      return {
        'insight': Insight(
          id: 'ins_sc_gen',
          title: 'Autonomous System State Shift Detected',
          domain: 'News',
          severity: 'Medium',
          timestamp: DateTime.now(),
          source: 'Manual Content Analysis',
          facts: const [
            'Ingested user-submitted document structure.',
            'Operational variables registered minor changes.'
          ],
          impactText: 'Normal baseline operations. Optimization opportunities detected in asset allocations.',
          implications: const [
            ImplicationItem(icon: 'info', text: 'Performance within standard error margins.'),
          ],
          associatedActionIds: const ['act_sc_gen_01'],
          agentsAttributed: const ['Decision Agent'],
        ),
        'actions': [
          const ActionItem(
            id: 'act_sc_gen_01',
            title: 'Schedule System Health Check',
            type: 'Workflow Trigger',
            domain: 'Urban',
            description: 'Execute diagnostics across CRM, billing, and fleet routing APIs.',
            targetSystem: 'System Admin Console',
            beforeState: {
              'Diagnostic Status': 'Idle',
              'API Query Latency': '12ms',
            },
            afterState: {
              'Diagnostic Status': 'Executed',
              'API Query Latency': '14ms',
            },
            simulationSteps: [
              'Testing Google Antigravity connector...',
              'Testing Firebase database read/writes...',
              'Testing News API access endpoints...',
              'Diagnostics finished.'
            ],
            metricName: 'API Health Score',
            metricValue: '100%',
            isPositiveMetric: true,
            status: 'pending',
          )
        ],
      };
    }
  }
}
