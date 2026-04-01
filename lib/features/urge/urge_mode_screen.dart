import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../core/models/accountability_partner.dart';
import '../../core/models/stop_reason.dart';
import '../../core/models/urge_session_log.dart';
import '../../core/services/accountability_message_service.dart';
import '../../core/services/money_converter_service.dart';
import '../../core/services/urge_script_service.dart';
import '../../core/services/weekly_summary_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import 'urge_scripts_screen.dart';

class UrgeModeScreen extends StatefulWidget {
  final double averageSpend;
  final ValueChanged<UrgeSessionLog> onComplete;
  final VoidCallback onStartPremiumTrial;
  final bool shouldShowSuccessPremiumPrompt;
  final VoidCallback onAcknowledgeSuccessPremiumPrompt;
  final VoidCallback onOpenCopingStrategies;
  final VoidCallback onOpenNearMissEducation;
  final VoidCallback onOpenAccountability;
  final AccountabilityPartner accountabilityPartner;
  final WeeklySummary weeklySummary;
  final int currentStreakDays;
  final List<StopReason> reasons;

  const UrgeModeScreen({
    super.key,
    required this.averageSpend,
    required this.onComplete,
    required this.onStartPremiumTrial,
    required this.shouldShowSuccessPremiumPrompt,
    required this.onAcknowledgeSuccessPremiumPrompt,
    required this.onOpenCopingStrategies,
    required this.onOpenNearMissEducation,
    required this.onOpenAccountability,
    required this.accountabilityPartner,
    required this.weeklySummary,
    required this.currentStreakDays,
    required this.reasons,
  });

  @override
  State<UrgeModeScreen> createState() => _UrgeModeScreenState();
}

class _UrgeModeScreenState extends State<UrgeModeScreen> {
  final DateTime _openedAt = DateTime.now();
  int _secondsLeft = 20;
  bool _completed = false;
  String _selectedScriptId = UrgeScriptService.defaultScript.id;
  bool _openedFullUrgeScript = false;
  bool _usedCopingStrategies = false;
  bool _usedNearMissEducation = false;
  bool _usedAccountability = false;

  static const List<String> _starterReasons = <String>[
    'I want to keep more money for real life.',
    'I do not want one ticket to turn into a spiral.',
    'I want more peace than the urge gives me.',
  ];

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && _secondsLeft > 0) {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        return;
      }

      setState(() {
        _secondsLeft -= 1;
      });
    }
  }

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

  void _openUrgeScripts() {
    setState(() {
      _openedFullUrgeScript = true;
    });

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UrgeScriptsScreen(
          initialScriptId: _selectedScriptId,
        ),
      ),
    );
  }

  void _openCopingStrategies() {
    setState(() {
      _usedCopingStrategies = true;
    });
    widget.onOpenCopingStrategies();
  }

  void _openNearMissEducation() {
    setState(() {
      _usedNearMissEducation = true;
    });
    widget.onOpenNearMissEducation();
  }

  void _openAccountability() {
    setState(() {
      _usedAccountability = true;
    });
    widget.onOpenAccountability();
  }

  Future<void> _handleComplete() async {
    if (_completed) {
      return;
    }

    setState(() {
      _completed = true;
    });

    final completedAt = DateTime.now();

    widget.onComplete(
      UrgeSessionLog(
        startedAt: _openedAt,
        completedAt: completedAt,
        selectedScriptId: _selectedScriptId,
        openedFullUrgeScript: _openedFullUrgeScript,
        usedCopingStrategies: _usedCopingStrategies,
        usedNearMissEducation: _usedNearMissEducation,
        usedAccountability: _usedAccountability,
      ),
    );

    if (!widget.shouldShowSuccessPremiumPrompt || !mounted) {
      Navigator.of(context).pop(true);
      return;
    }

    final wantsPremium = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Nice save. Build on it.'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium helps you keep momentum with custom urge plans, smarter reminders, and deeper trigger tracking.',
                  ),
                  SizedBox(height: 12),
                  Text('• Custom urge plans'),
                  Text('• Smarter reminders'),
                  Text('• Deeper trigger tracking'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Keep Going Free'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Unlock Premium'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted) {
      return;
    }

    widget.onAcknowledgeSuccessPremiumPrompt();

    if (wantsPremium) {
      widget.onStartPremiumTrial();
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayReasons = widget.reasons.isEmpty
        ? _starterReasons
        : widget.reasons.take(3).map((reason) => reason.text).toList();

    final converterReport = MoneyConverterService.build(widget.averageSpend);
    final previewComparisons = converterReport.comparisons.take(3).toList();

    final supportNowMessage =
        AccountabilityMessageService.buildSupportNowMessage(
      partnerName: widget.accountabilityPartner.name,
    );

    final quickCheckInMessage =
        AccountabilityMessageService.buildCheckInMessage(
      partnerName: widget.accountabilityPartner.name,
      weeklySummary: widget.weeklySummary,
      currentStreakDays: widget.currentStreakDays,
    );

    final hasTrustedPerson = widget.accountabilityPartner.hasName;
    final hasPhone = widget.accountabilityPartner.hasPhone;
    final partnerName = widget.accountabilityPartner.name.trim();

    final script = UrgeScriptService.byId(_selectedScriptId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urge mode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                const Text(
                  'Pause first',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_secondsLeft',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _secondsLeft > 0
                      ? 'You do not have to decide in the next few seconds.'
                      : 'The first wave passed. That matters.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 16,
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
                  'What this ticket really risks',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${widget.averageSpend.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'That amount can stay yours if you get through this urge without buying.',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What that money could buy instead',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (previewComparisons.isEmpty)
                  const Text(
                    'No comparison available yet.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  )
                else
                  ...previewComparisons.map((comparison) {
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
                              '${comparison.valueText} ${comparison.label}',
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trusted-person quick check-in',
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
                    'Set one trusted person so urge mode can help you reach out faster when the risk spikes.',
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
                    onPressed: _openAccountability,
                  ),
                ] else ...[
                  Text(
                    partnerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasPhone
                        ? 'Reach out before buying. Fast contact is better than waiting for the urge to get louder.'
                        : 'No phone is saved yet, but you can still copy a message and send it however you want.',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: hasPhone
                        ? 'Text support request'
                        : 'Copy support request',
                    icon: Icons.support_agent_rounded,
                    onPressed: () {
                      setState(() {
                        _usedAccountability = true;
                      });
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
                  const SizedBox(height: 10),
                  AppButton(
                    label: hasPhone ? 'Text quick check-in' : 'Copy check-in',
                    icon: Icons.sms_rounded,
                    isPrimary: false,
                    onPressed: () {
                      setState(() {
                        _usedAccountability = true;
                      });
                      if (hasPhone) {
                        _sendSmsOrCopy(
                          phone: widget.accountabilityPartner.phone!,
                          body: quickCheckInMessage,
                          copiedMessage:
                              'Could not open texting. Check-in copied.',
                        );
                      } else {
                        _copyText(
                          quickCheckInMessage,
                          'Check-in copied',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _openAccountability,
                      child: const Text('Open full accountability tools'),
                    ),
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
                  'Which scratch-off pull is this?',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: UrgeScriptService.all.map((item) {
                    return ChoiceChip(
                      label: Text(item.chipLabel),
                      selected: _selectedScriptId == item.id,
                      onSelected: (_) {
                        setState(() {
                          _selectedScriptId = item.id;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  script.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  script.summary,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  script.realityCheck,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...script.steps.take(2).map((step) {
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
                AppButton(
                  label: 'Open full urge script',
                  icon: Icons.menu_book_rounded,
                  isPrimary: false,
                  onPressed: _openUrgeScripts,
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
                  'Near-miss psychology',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If an almost-win is pulling you back in, open the explainer and break the spell a little.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open near-miss explainer',
                  icon: Icons.lightbulb_rounded,
                  isPrimary: false,
                  onPressed: _openNearMissEducation,
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
                  'Coping strategies',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Need a next move? Open short strategies for what to do during the urge.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open coping strategies',
                  icon: Icons.psychology_rounded,
                  isPrimary: false,
                  onPressed: _openCopingStrategies,
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
                  'Reasons to stop right now',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...displayReasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: _completed ? 'Urge already interrupted' : 'I got through this urge',
            icon: Icons.check_circle_rounded,
            onPressed: _completed ? null : _handleComplete,
          ),
        ],
      ),
    );
  }
}
