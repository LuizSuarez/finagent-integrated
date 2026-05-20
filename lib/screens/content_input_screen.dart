import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../widgets/buttons.dart';
import '../widgets/inputs.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import 'pipeline_running_screen.dart';

class ContentInputScreen extends StatefulWidget {
  const ContentInputScreen({super.key});

  @override
  State<ContentInputScreen> createState() => _ContentInputScreenState();
}

class _ContentInputScreenState extends State<ContentInputScreen> {
  int _activeTab = 0; // 0=Text, 1=URL, 2=PDF, 3=RSS

  // Input controllers
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _rssController = TextEditingController();

  // Mock Upload states
  String? _uploadedFileName;
  bool _urlFetched = false;
  bool _rssFetched = false;

  @override
  void initState() {
    super.initState();
    // Default text pre-population if Custom or preset scenarios selected
    _textController.addListener(() {
      setState(() {}); // For character counter
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _rssController.dispose();
    super.dispose();
  }

  void _onScenarioChanged(String? val, ApiService apiState) {
    if (val == null) return;
    apiState.setScenario(val);

    if (val == 'Custom') {
      _textController.clear();
      apiState.setDomain('Business');
    } else {
      // Prepopulate
      _textController.text = apiState.allScenarios[val] ?? '';
      
      // Auto-set domains matching scenario
      if (val == 'Sales Decline') {
        apiState.setDomain('Business');
      } else if (val == 'Fuel Price Hike') {
        apiState.setDomain('Finance');
      } else if (val == 'Supply Chain Disruption') {
        apiState.setDomain('Logistics');
      } else if (val == 'Policy Change') {
        apiState.setDomain('Policy');
      }
    }
  }

  void _runPipeline(ApiService apiState) {
    final rawText = _textController.text;
    final selectedScenario = apiState.selectedScenario;

    // Check if input is empty in the current active tab
    String contentToAnalyze = '';
    if (_activeTab == 0) {
      contentToAnalyze = rawText;
    } else if (_activeTab == 1) {
      contentToAnalyze = _urlController.text;
    } else if (_activeTab == 2) {
      contentToAnalyze = _uploadedFileName ?? '';
    } else {
      contentToAnalyze = _rssController.text;
    }

    if (contentToAnalyze.trim().isEmpty) {
      ToastService.showError(context, 'Please enter or upload content to run pipeline.');
      return;
    }

    // Trigger state pipeline run
    apiState.runPipeline(selectedScenario, contentToAnalyze);

    // Navigate to Pipeline Running Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PipelineRunningScreen(rawContent: contentToAnalyze),
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
          style: AppTheme.headingLg(context, colors.textPrimary).copyWith(letterSpacing: 2.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scenario Selector Row
              _buildScenarioSelector(context, apiState),
              const SizedBox(height: 20),

              // Tab Selector (Text / URL / PDF / RSS)
              _buildTabSelector(context),
              const SizedBox(height: 16),

              // Dynamic Tab Body
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildActiveTabContent(context),
              ),
              const SizedBox(height: 24),

              // Domain Selector Section
              _buildDomainSelector(context, apiState),
              const SizedBox(height: 32),

              // Run Button
              PrimaryButton(
                text: 'RUN PIPELINE',
                width: double.infinity,
                icon: Icons.play_arrow,
                onPressed: () => _runPipeline(apiState),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioSelector(BuildContext context, ApiService apiState) {
    final colors = AppTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'USE A PRESET SCENARIO (OPTIONAL)',
          style: AppTheme.caption(context, colors.textSecondary).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: apiState.selectedScenario,
              dropdownColor: colors.bgSurface,
              icon: Icon(Icons.keyboard_arrow_down, color: colors.accentPrimary),
              style: AppTheme.bodyMd(context, colors.textPrimary),
              items: apiState.allScenarios.keys.map((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(key),
                );
              }).toList(),
              onChanged: (val) => _onScenarioChanged(val, apiState),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final colors = AppTheme.of(context);
    final tabLabels = ['TEXT', 'URL', 'PDF UPLOAD', 'RSS FEED'];

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isSelected = _activeTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colors.bgElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.accentPrimary.withOpacity(0.5)) : null,
                ),
                child: Text(
                  tabLabels[index],
                  style: AppTheme.caption(context, isSelected ? colors.accentPrimary : colors.textSecondary).copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent(BuildContext context) {
    final colors = AppTheme.of(context);

    switch (_activeTab) {
      case 0: // Text Input
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextArea(
              label: 'Paste Content to Ingest',
              placeholder: 'Type or paste raw operational reports, transportation logs, policy clauses, news articles...',
              controller: _textController,
              maxLines: 8,
              maxLength: 5000,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_textController.text.length} / 5000 characters',
                style: AppTheme.caption(context, colors.textSecondary),
              ),
            ),
          ],
        );
      case 1: // URL Input
        return Column(
          key: const ValueKey(1),
          children: [
            InputField(
              label: 'Enter Article or Report URL',
              placeholder: 'https://news.gazette.org/report/logistics-delay',
              controller: _urlController,
              suffixIcon: IconButton(
                icon: Icon(Icons.download, color: colors.accentPrimary),
                onPressed: () {
                  if (_urlController.text.trim().isNotEmpty) {
                    setState(() {
                      _urlFetched = true;
                    });
                  }
                },
              ),
            ),
            if (_urlFetched) ...[
              const SizedBox(height: 16),
              CustomCard(
                backgroundColor: colors.bgElevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCRAPED PREVIEW',
                      style: AppTheme.caption(context, colors.accentPrimary).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Regional Freight Congestion Peaks Amid Infrastructure Renovation',
                      style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Operational transit bottlenecks at Lahore bypass hubs are estimated to compound trucking delays by 45 minutes on outbound delivery grids...',
                      style: AppTheme.bodySm(context, colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ]
          ],
        );
      case 2: // PDF Upload
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF FILE INGESTION',
              style: AppTheme.caption(context, colors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  _uploadedFileName = 'Q2_Logistics_Operations_Brief.pdf';
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.borderColor,
                    style: BorderStyle.solid, // Note: standard dashed isn't in box decor
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.picture_as_pdf, color: colors.accentSecondary, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to Upload PDF Document',
                      style: AppTheme.bodyMd(context, colors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supported file size limits: up to 10MB',
                      style: AppTheme.caption(context, colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            if (_uploadedFileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.accentPrimary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description, color: colors.accentPrimary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _uploadedFileName!,
                      style: AppTheme.caption(context, colors.accentPrimary).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _uploadedFileName = null;
                        });
                      },
                      child: Icon(Icons.close, color: colors.accentPrimary, size: 14),
                    ),
                  ],
                ),
              ),
            ]
          ],
        );
      case 3: // RSS Feed
        return Column(
          key: const ValueKey(3),
          children: [
            InputField(
              label: 'Enter RSS Feed Endpoint',
              placeholder: 'https://gazette.ops/rss/logistics',
              controller: _rssController,
              suffixIcon: IconButton(
                icon: Icon(Icons.sync, color: colors.accentPrimary),
                onPressed: () {
                  if (_rssController.text.trim().isNotEmpty) {
                    setState(() {
                      _rssFetched = true;
                    });
                  }
                },
              ),
            ),
            if (_rssFetched) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECENT FEED RELEASES',
                    style: AppTheme.caption(context, colors.textSecondary).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildRSSChip('Transport Authority updates Punjab surcharge limits (+12%)'),
                  _buildRSSChip('Industrial diesel costs index re-calculated to 272 PKR/L'),
                  _buildRSSChip('Secondary highways declare toll exemptions for electric vans'),
                ],
              ),
            ]
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildRSSChip(String text) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: CustomCard(
        padding: const EdgeInsets.all(10),
        backgroundColor: colors.bgSurface,
        onTap: () {
          _textController.text = text;
          setState(() {
            _activeTab = 0; // jump back to edit tab
          });
        },
        child: Row(
          children: [
            Icon(Icons.rss_feed, color: colors.accentSecondary, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.caption(context, colors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainSelector(BuildContext context, ApiService apiState) {
    final colors = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALYSIS DOMAIN',
          style: AppTheme.caption(context, colors.textSecondary).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.domains.map((domain) {
            return CustomChip(
              label: domain.toUpperCase(),
              isSelected: apiState.selectedDomain == domain,
              onTap: () {
                apiState.setDomain(domain);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
