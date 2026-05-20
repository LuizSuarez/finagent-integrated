class ImplicationItem {
  final String? icon;
  final String? text;

  const ImplicationItem({this.icon, this.text});

  String get displayIcon => icon ?? 'info_outline';
  String get displayText => text ?? 'No implication details provided.';
}

class Insight {
  final String? id;
  final String? title;
  final String? domain;
  final String? severity; // Low, Medium, High, Critical
  final DateTime? timestamp;
  final String? source;
  final List<String>? facts;
  final String? impactText;
  final List<ImplicationItem>? implications;
  final List<String>? associatedActionIds;
  final List<String>? agentsAttributed;

  const Insight({
    this.id,
    this.title,
    this.domain,
    this.severity,
    this.timestamp,
    this.source,
    this.facts,
    this.impactText,
    this.implications,
    this.associatedActionIds,
    this.agentsAttributed,
  });

  // Getter fallbacks (React-style defaults)
  String get displayTitle => title ?? 'Analysis in Progress';
  String get displayDomain => domain ?? 'General';
  String get displaySeverity => severity ?? 'Medium';
  String get displaySource => source ?? 'System Feed';
  List<String> get displayFacts => facts ?? const ['No critical facts extracted.'];
  String get displayImpactText => impactText ?? 'Analyzing structural and system impacts...';
  List<ImplicationItem> get displayImplications => implications ?? const [];
  List<String> get displayAssociatedActionIds => associatedActionIds ?? const [];
  List<String> get displayAgentsAttributed => agentsAttributed ?? const ['Decision Agent'];
  DateTime get displayTimestamp => timestamp ?? DateTime.now();

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as String?,
      title: json['title'] as String?,
      domain: json['domain'] as String?,
      severity: json['severity'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) : null,
      source: json['source'] as String?,
      facts: (json['facts'] as List<dynamic>?)?.map((e) => e as String).toList(),
      impactText: json['impactText'] as String?,
      implications: (json['implications'] as List<dynamic>?)
          ?.map((e) => ImplicationItem(
                icon: e['icon'] as String?,
                text: e['text'] as String?,
              ))
          .toList(),
      associatedActionIds: (json['associatedActionIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      agentsAttributed: (json['agentsAttributed'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'domain': domain,
      'severity': severity,
      'timestamp': timestamp?.toIso8601String(),
      'source': source,
      'facts': facts,
      'impactText': impactText,
      'implications': implications?.map((e) => {'icon': e.icon, 'text': e.text}).toList(),
      'associatedActionIds': associatedActionIds,
      'agentsAttributed': agentsAttributed,
    };
  }
}
