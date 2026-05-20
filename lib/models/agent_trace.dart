class AgentTrace {
  final String? agentName;
  final String? iconName; // e.g. 'search', 'bar_chart'
  final String? status; // waiting, running, done, error
  final String? inputReceived;
  final String? outputProduced;
  final String? reasoning;
  final DateTime? timestamp;
  final int? durationMs;

  const AgentTrace({
    this.agentName,
    this.iconName,
    this.status,
    this.inputReceived,
    this.outputProduced,
    this.reasoning,
    this.timestamp,
    this.durationMs,
  });

  // Getters with fallback strings
  String get displayAgentName => agentName ?? 'Agent Core';
  String get displayIconName => iconName ?? 'smart_toy';
  String get displayStatus => status ?? 'waiting';
  String get displayInputReceived => inputReceived ?? 'Awaiting predecessor agent payload...';
  String get displayOutputProduced => outputProduced ?? 'No output generated.';
  String get displayReasoning => reasoning ?? 'Reasoning flow trace not started.';
  DateTime get displayTimestamp => timestamp ?? DateTime.now();
  int get displayDurationMs => durationMs ?? 0;

  factory AgentTrace.fromJson(Map<String, dynamic> json) {
    return AgentTrace(
      agentName: json['agentName'] as String?,
      iconName: json['iconName'] as String?,
      status: json['status'] as String?,
      inputReceived: json['inputReceived'] as String?,
      outputProduced: json['outputProduced'] as String?,
      reasoning: json['reasoning'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) : null,
      durationMs: json['durationMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentName': agentName,
      'iconName': iconName,
      'status': status,
      'inputReceived': inputReceived,
      'outputProduced': outputProduced,
      'reasoning': reasoning,
      'timestamp': timestamp?.toIso8601String(),
      'durationMs': durationMs,
    };
  }
}
