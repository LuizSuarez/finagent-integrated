import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../widgets/buttons.dart';
import 'pipeline_running_screen.dart';

class ContentInputScreen extends StatefulWidget {
  const ContentInputScreen({super.key});

  @override
  State<ContentInputScreen> createState() => _ContentInputScreenState();
}

class _ContentInputScreenState extends State<ContentInputScreen> {
  String _selectedMode = 'Live Market Data';
  String _selectedDomain = 'Business';

  static const Map<String, String> _executionModes = {
    'Live Market Data': '__live__',
    'Oil Shock': 'oil_shock',
    'Rate Hike': 'rate_hike',
    'Earnings Beat': 'earnings_beat',
  };

  void _runPipeline(ApiService apiState) {
    final scenarioId = _executionModes[_selectedMode] ?? '__live__';
    apiState.setDomain(_selectedDomain);
    apiState.runScenario(scenarioId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PipelineRunningScreen(
          rawContent: _selectedMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final apiState = Provider.of<ApiService>(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'NEW ANALYSIS',
          style: AppTheme.headingLg(context, colors.textPrimary)
              .copyWith(letterSpacing: 2.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SELECT EXECUTION MODE label
            Text(
              'SELECT EXECUTION MODE',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Dropdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMode,
                  dropdownColor: colors.bgElevated,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: colors.accentPrimary),
                  style: AppTheme.bodyMd(context, colors.textPrimary),
                  items: _executionModes.keys.map((String label) {
                    return DropdownMenuItem<String>(
                      value: label,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMode = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ANALYSIS DOMAIN label
            Text(
              'ANALYSIS DOMAIN',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Domain chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.domains.map((domain) {
                final isSelected = _selectedDomain == domain;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDomain = domain),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.accentPrimary
                          : colors.bgSurface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? colors.accentPrimary
                            : colors.borderColor,
                      ),
                    ),
                    child: Text(
                      domain.toUpperCase(),
                      style: AppTheme.caption(
                        context,
                        isSelected ? Colors.black : colors.textSecondary,
                      ).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // RUN PIPELINE button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: apiState.isPipelineRunning
                    ? null
                    : () => _runPipeline(apiState),
                icon: const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                label: Text(
                  apiState.isPipelineRunning
                      ? 'PIPELINE RUNNING...'
                      : 'RUN PIPELINE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF00D4AA).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
