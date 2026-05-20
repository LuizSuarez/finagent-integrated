import '../core/constants.dart';

class AppSettings {
  final bool? autoRun;
  final bool? enableWebsocket;
  final bool? mockMode;
  final String? backendUrl;
  final List<String>? preferredDomains;

  const AppSettings({
    this.autoRun,
    this.enableWebsocket,
    this.mockMode,
    this.backendUrl,
    this.preferredDomains,
  });

  // Getters with fallbacks
  bool get displayAutoRun => autoRun ?? true;
  bool get displayEnableWebsocket => enableWebsocket ?? true;
  bool get displayMockMode => mockMode ?? true;
  String get displayBackendUrl => backendUrl ?? AppConstants.defaultBackendUrl;
  List<String> get displayPreferredDomains => preferredDomains ?? const ['Business', 'Policy', 'Finance'];

  AppSettings copyWith({
    bool? autoRun,
    bool? enableWebsocket,
    bool? mockMode,
    String? backendUrl,
    List<String>? preferredDomains,
  }) {
    return AppSettings(
      autoRun: autoRun ?? this.autoRun,
      enableWebsocket: enableWebsocket ?? this.enableWebsocket,
      mockMode: mockMode ?? this.mockMode,
      backendUrl: backendUrl ?? this.backendUrl,
      preferredDomains: preferredDomains ?? this.preferredDomains,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      autoRun: json['autoRun'] as bool?,
      enableWebsocket: json['enableWebsocket'] as bool?,
      mockMode: json['mockMode'] as bool?,
      backendUrl: json['backendUrl'] as String?,
      preferredDomains: (json['preferredDomains'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoRun': autoRun,
      'enableWebsocket': enableWebsocket,
      'mockMode': mockMode,
      'backendUrl': backendUrl,
      'preferredDomains': preferredDomains,
    };
  }
}
