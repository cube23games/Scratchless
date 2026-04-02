import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../core/models/accountability_partner.dart';
import '../../core/models/risky_place.dart';
import '../../core/services/accountability_message_service.dart';
import '../../core/services/pre_store_intervention_service.dart';
import '../../core/services/weekly_summary_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../urge/urge_scripts_screen.dart';

class PreStoreModeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onOpenCopingStrategies;
  final VoidCallback onOpenAccountability;
  final VoidCallback onOpenRiskyPlaces;
  final AccountabilityPartner accountabilityPartner;
  final List<RiskyPlace> riskyPlaces;
  final WeeklySummary weeklySummary;
  final int currentStreakDays;

  const PreStoreModeScreen({
    super.key,
    required this.onComplete,
    required this.onOpenCopingStrategies,
    required this.onOpenAccountability,
    required this.onOpenRiskyPlaces,
    required this.accountabilityPartner,
    required this.riskyPlaces,
    required this.weeklySummary,
    required this.currentStreakDays,
  });

  @override
  State<PreStoreModeScreen> createState() => _PreStoreModeScreenState();
}

class _PreStoreModeScreenState extends State<PreStoreModeScreen> {
  String _selectedScenarioId = PreStoreInterventionService.defaultScenario.id;
  bool _completed = false;

  Future<void> _copyText(String text, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(confirmation),
      ),
    );
  }

  Future<void> _sendSmsOrCopy({
    required String phone,
    required String body,
    required String copiedMessage,
  }) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{
        'body': body,
      },
    );

    final ok = await launchUrl(uri);

    if (!ok && mounted) {
      await _copyText(body, copiedMessage);
    }
  }

  void _openLinkedUrgeScript(String urgeScriptId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UrgeScriptsScreen(
          initialScriptId: urgeScriptId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenario =
        PreStoreInterventionService.byId(_selectedScenarioId);

    final hasTrustedPerson = widget.accountabilityPartner.hasName;
    final hasPhone = widget.accountabilityPartner.hasPhone;
    final highlightedPlaces = [
      ...widget.riskyPlaces.where((place) => place.isTopRisk),
      ...widget.riskyPlaces.where((place) => !place.isTopRisk),
    ].take(3).toList();
    final topRiskPlaces = widget.riskyPlaces.where((place) => place.isTopRisk).toList();
    final topRiskPlace = topRiskPlaces.isEmpty ? null : topRiskPlaces.first;
    final previewPlaces = topRiskPlace == null
        ? highlightedPlaces
        : highlightedPlaces.where((place) => place.id != topRiskPlace.id).toList();

    final supportNowMessage =
        AccountabilityMessageService.buildSupportNowMessage(
      partnerName: widget.accountabilityPartner.name,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-store mode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catch it before the counter',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This mode is for the moment before a stop turns into a ticket.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'The goal is simple: help you stay out before the friction disappears.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: PreStoreInterventionService.all.map((item) {
                return ChoiceChip(
                  label: Text(item.chipLabel),
                  selected: _selectedScenarioId == item.id,
                  onSelected: (_) {
                    setState(() {
                      _selectedScenarioId = item.id;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scenario.summary,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'What to do next',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...scenario.steps.map((step) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Text(
                  scenario.resetLine,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trusted-person support',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (!hasTrustedPerson) ...[
                  const Text(
                    'No trusted person set yet.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set one trusted person so pre-store mode can help you reach out before stopping.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Set up accountability',
                    icon: Icons.person_add_alt_1_rounded,
                    isPrimary: false,
                    onPressed: widget.onOpenAccountability,
                  ),
                ] else ...[
                  Text(
                    widget.accountabilityPartner.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reach out before you stop, not after the purchase.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: hasPhone
                        ? 'Text support before stopping'
                        : 'Copy support request',
                    icon: Icons.support_agent_rounded,
                    onPressed: () {
                      if (hasPhone) {
                        _sendSmsOrCopy(
                          phone: widget.accountabilityPartner.phone!,
                          body: supportNowMessage,
                          copiedMessage:
                              'Could not open texting. Support request copied.',
                        );
                      } else {
                        _copyText(
                          supportNowMessage,
                          'Support request copied',
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risky places watchlist',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (topRiskPlace != null) ...[
                  const Text(
                    'Top risk place on your watchlist',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topRiskPlace.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topRiskPlace.note.trim().isNotEmpty
                        ? topRiskPlace.note
                        : 'Keep this stop visible before it turns automatic.',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  if (previewPlaces.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Other saved risky stops',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ] else if (highlightedPlaces.isEmpty) ...[
                  const Text(
                    'No risky places saved yet. Add the stops that most often turn into ticket purchases.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (topRiskPlace == null && highlightedPlaces.isNotEmpty) ...[
                  const Text(
                    'Keep these stops visible before they turn automatic.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ...(topRiskPlace == null ? highlightedPlaces : previewPlaces).take(3).map((place) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Icon(
                            place.isTopRisk
                                ? Icons.priority_high_rounded
                                : Icons.place_rounded,
                            size: 16,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (place.note.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  place.note,
                                  style: const TextStyle(
                                    color: AppTheme.mutedText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                AppButton(
                  label: 'Open risky places',
                  icon: Icons.place_rounded,
                  isPrimary: false,
                  onPressed: widget.onOpenRiskyPlaces,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'More help',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open matching urge script',
                  icon: Icons.menu_book_rounded,
                  isPrimary: false,
                  onPressed: () {
                    _openLinkedUrgeScript(scenario.linkedUrgeScriptId);
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Open coping strategies',
                  icon: Icons.psychology_rounded,
                  isPrimary: false,
                  onPressed: widget.onOpenCopingStrategies,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: _completed
                ? 'You stayed out this time'
                : 'I drove past without stopping',
            icon: Icons.directions_car_filled_rounded,
            onPressed: _completed
                ? null
                : () {
                    setState(() {
                      _completed = true;
                    });
                    widget.onComplete();
                  },
          ),
        ],
      ),
    );
  }
}
