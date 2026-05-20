class AssetRow {
  final String? name;
  final double? allocationPercent;
  final double? value;
  final String? riskLevel; // Low, Medium, High

  const AssetRow({this.name, this.allocationPercent, this.value, this.riskLevel});

  String get displayName => name ?? 'Asset';
  double get displayAllocationPercent => allocationPercent ?? 0.0;
  double get displayValue => value ?? 0.0;
  String get displayRiskLevel => riskLevel ?? 'Low';
}

class ActiveCampaign {
  final String? name;
  final String? status; // Active, Paused, Scheduled
  final int? projectedReach;

  const ActiveCampaign({this.name, this.status, this.projectedReach});

  String get displayName => name ?? 'Campaign';
  String get displayStatus => status ?? 'Active';
  int get displayProjectedReach => projectedReach ?? 0;
}

class PortfolioState {
  final double? totalValue;
  final List<AssetRow>? assets;
  final List<ActiveCampaign>? activeCampaigns;
  final Map<String, double>? pricingTable;
  final double? riskScore; // 0 to 100
  final String? riskLevel; // Low, Medium, High
  final String? riskExplanation;

  const PortfolioState({
    this.totalValue,
    this.assets,
    this.activeCampaigns,
    this.pricingTable,
    this.riskScore,
    this.riskLevel,
    this.riskExplanation,
  });

  // Getters with fallbacks
  double get displayTotalValue => totalValue ?? 1000000.0;
  List<AssetRow> get displayAssets => assets ?? const [];
  List<ActiveCampaign> get displayActiveCampaigns => activeCampaigns ?? const [];
  Map<String, double> get displayPricingTable => pricingTable ?? const {'Standard SKU': 49.99};
  double get displayRiskScore => riskScore ?? 35.0;
  String get displayRiskLevel => riskLevel ?? 'Medium';
  String get displayRiskExplanation => riskExplanation ?? 'System baseline at nominal operating conditions.';

  factory PortfolioState.fromJson(Map<String, dynamic> json) {
    return PortfolioState(
      totalValue: (json['totalValue'] as num?)?.toDouble(),
      assets: (json['assets'] as List<dynamic>?)
          ?.map((e) => AssetRow(
                name: e['name'] as String?,
                allocationPercent: (e['allocationPercent'] as num?)?.toDouble(),
                value: (e['value'] as num?)?.toDouble(),
                riskLevel: e['riskLevel'] as String?,
              ))
          .toList(),
      activeCampaigns: (json['activeCampaigns'] as List<dynamic>?)
          ?.map((e) => ActiveCampaign(
                name: e['name'] as String?,
                status: e['status'] as String?,
                projectedReach: e['projectedReach'] as int?,
              ))
          .toList(),
      pricingTable: (json['pricingTable'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      riskScore: (json['riskScore'] as num?)?.toDouble(),
      riskLevel: json['riskLevel'] as String?,
      riskExplanation: json['riskExplanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalValue': totalValue,
      'assets': assets?.map((e) => {
        'name': e.name,
        'allocationPercent': e.allocationPercent,
        'value': e.value,
        'riskLevel': e.riskLevel,
      }).toList(),
      'activeCampaigns': activeCampaigns?.map((e) => {
        'name': e.name,
        'status': e.status,
        'projectedReach': e.projectedReach,
      }).toList(),
      'pricingTable': pricingTable,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'riskExplanation': riskExplanation,
    };
  }
}
