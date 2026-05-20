class ActionItem {
  final String? id;
  final String? title;
  final String? type; // Campaign, Pricing Update, Notification, Workflow Trigger
  final String? domain;
  final String? description;
  final String? targetSystem; // CRM, Pricing Table, Email Notifier, Dashboard
  final Map<String, String>? beforeState;
  final Map<String, String>? afterState;
  final List<String>? simulationSteps;
  final String? metricName;
  final String? metricValue;
  final bool? isPositiveMetric; // true = green, false = red/amber
  final String? status; // pending, simulated, execution_error
  final DateTime? simulatedAt;

  const ActionItem({
    this.id,
    this.title,
    this.type,
    this.domain,
    this.description,
    this.targetSystem,
    this.beforeState,
    this.afterState,
    this.simulationSteps,
    this.metricName,
    this.metricValue,
    this.isPositiveMetric,
    this.status,
    this.simulatedAt,
  });

  // Safe fallback accessors
  String get displayTitle => title ?? 'Unspecified Action';
  String get displayType => type ?? 'Adjustment';
  String get displayDomain => domain ?? 'General';
  String get displayDescription => description ?? 'No recommended action description available.';
  String get displayTargetSystem => targetSystem ?? 'System Admin';
  Map<String, String> get displayBeforeState => beforeState ?? const {'Status': 'Inactive'};
  Map<String, String> get displayAfterState => afterState ?? const {'Status': 'Modified'};
  List<String> get displaySimulationSteps => simulationSteps ?? const ['Initiating simulation environment...'];
  String get displayMetricName => metricName ?? 'Impact Rate';
  String get displayMetricValue => metricValue ?? '0.0%';
  bool get displayIsPositiveMetric => isPositiveMetric ?? true;
  String get displayStatus => status ?? 'pending';

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id'] as String?,
      title: json['title'] as String?,
      type: json['type'] as String?,
      domain: json['domain'] as String?,
      description: json['description'] as String?,
      targetSystem: json['targetSystem'] as String?,
      beforeState: (json['beforeState'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v.toString())),
      afterState: (json['afterState'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v.toString())),
      simulationSteps: (json['simulationSteps'] as List<dynamic>?)?.map((e) => e as String).toList(),
      metricName: json['metricName'] as String?,
      metricValue: json['metricValue'] as String?,
      isPositiveMetric: json['isPositiveMetric'] as bool?,
      status: json['status'] as String?,
      simulatedAt: json['simulatedAt'] != null ? DateTime.tryParse(json['simulatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'domain': domain,
      'description': description,
      'targetSystem': targetSystem,
      'beforeState': beforeState,
      'afterState': afterState,
      'simulationSteps': simulationSteps,
      'metricName': metricName,
      'metricValue': metricValue,
      'isPositiveMetric': isPositiveMetric,
      'status': status,
      'simulatedAt': simulatedAt?.toIso8601String(),
    };
  }
}
