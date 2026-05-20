class AppConstants {
  static const String appName = 'FinAgent';
  static const String appTagline = 'From Information to Action';
  static const String defaultBackendUrl = 'https://api.finagent.ai/v1';

  // Analysis Domains
  static const List<String> domains = [
    'Business',
    'Policy',
    'Logistics',
    'Finance',
    'News',
    'Urban',
  ];

  // Preset Scenarios
  static const Map<String, String> scenarios = {
    'Custom': 'Enter or paste custom content for ad-hoc analysis.',
    'Sales Decline': 'Orders declined by 25% due to regional market stagnation and logistics delays in primary hubs.',
    'Fuel Price Hike': 'Domestic fuel price surged by 18%, increasing logistics overhead and raw material delivery costs.',
    'Supply Chain Disruption': 'Major port shutdown has delayed raw electronics shipments by 4 weeks, affecting production runs.',
    'Policy Change': 'New environmental compliance regulations introduced, placing a carbon penalty on high-emission shipments.',
  };
}
