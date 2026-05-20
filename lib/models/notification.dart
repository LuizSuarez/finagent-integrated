class AppNotification {
  final String? id;
  final String? title;
  final String? body;
  final String? category; // pipeline, insight, action, system, draft
  final bool? isRead;
  final DateTime? timestamp;
  
  // For AI-drafted communications (DraftedCommsSection)
  final String? draftSubject;
  final String? draftRecipient;
  final String? draftBody;

  const AppNotification({
    this.id,
    this.title,
    this.body,
    this.category,
    this.isRead,
    this.timestamp,
    this.draftSubject,
    this.draftRecipient,
    this.draftBody,
  });

  // Getters with fallbacks
  String get displayTitle => title ?? 'Alert Notification';
  String get displayBody => body ?? 'A system update occurred.';
  String get displayCategory => category ?? 'system';
  bool get displayIsRead => isRead ?? false;
  DateTime get displayTimestamp => timestamp ?? DateTime.now();
  String get displayDraftSubject => draftSubject ?? 'AI Drafted Communication';
  String get displayDraftRecipient => draftRecipient ?? 'analyst@finagent.ai';
  String get displayDraftBody => draftBody ?? 'No draft content generated.';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      category: json['category'] as String?,
      isRead: json['isRead'] as bool?,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) : null,
      draftSubject: json['draftSubject'] as String?,
      draftRecipient: json['draftRecipient'] as String?,
      draftBody: json['draftBody'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'isRead': isRead,
      'timestamp': timestamp?.toIso8601String(),
      'draftSubject': draftSubject,
      'draftRecipient': draftRecipient,
      'draftBody': draftBody,
    };
  }
}
