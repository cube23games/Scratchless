import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../core/models/accountability_partner.dart';
import '../../core/models/stop_reason.dart';
import '../../core/models/urge_session_log.dart';
import '../../core/services/accountability_message_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class LiveAlertRescueScreen extends StatefulWidget {
  final String placeLabel;
  final bool autoStartTenMinutePause;
  final List<StopReason> stopReasons;
  final AccountabilityPartner accountabilityPartner;
  final ValueChanged<UrgeSessionLog> onLogUrge;

  const LiveAlertRescueScreen({
    super.key,
    required this.placeLabel,
    this.autoStartTenMinutePause = false,
    required this.stopReasons,
    required this.accountabilityPartner,
    required this.onLogUrge,
  });

  @override
  State<LiveAlertRescueScreen> createState() => _LiveAlertRescueScreenState();
}

class _LiveAlertRescueScreenState extends State<LiveAlertRescueScreen> {
  DateTime? _waitUntil;
  bool _autoStarted = false;
  bool _usedReasons = false;
  bool _usedSupport = false;
  bool _usedWait = false;

  String get _headline => widget.placeLabel.trim().isEmpty
      ? 'Pause before you go in'
      : 'Pause before ${widget.placeLabel}';

  String get _body => widget.placeLabel.trim().isEmpty
      ? 'This stop has been risky before. Give yourself one more pause before you decide.'
      : '${widget.placeLabel} has been risky before. Give yourself one more pause before you decide.';

  @override
  void initState() {
    super.initState();
    if (widget.autoStartTenMinutePause) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _autoStarted) {
          return;
        }
        _autoStarted = true;
        _startTenMinutePause(showSnackBar: false);
      });
    }
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _reasonLabel(StopReason reason) {
    final map = reason.toJson();
    const preferredKeys = <String>['text', 'reason', 'title', 'label', 'body'];

    for (final key in preferredKeys) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != map['id']?.toString()) {
        return value;
      }
    }

    for (final entry in map.entries) {
      if (entry.key == 'id') {
        continue;
      }
      final value = entry.value?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'Saved reason';
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

  Future<void> _sendEmailOrCopy({
    required String email,
    required String body,
    required String copiedMessage,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: <String, String>{
        'subject': 'ScratchLess support check-in',
        'body': body,
      },
    );

    final ok = await launchUrl(uri);

    if (!ok && mounted) {
      await _copyText(body, copiedMessage);
    }
  }

  void _startTenMinutePause({bool showSnackBar = true}) {
    setState(() {
      _usedWait = true;
      _waitUntil = DateTime.now().add(const Duration(minutes: 10));
    });

    if (!showSnackBar || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ten-minute pause started. Stay out of the store and let the urge pass a little.',
        ),
      ),
    );
  }

  void _leaveNow() {
    Navigator.of(context).maybePop();
  }

  void _openReasonsSheet() {
    setState(() {
      _usedReasons = true;
    });

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final reasons = widget.stopReasons;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Read your reasons',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use one strong reason to slow this moment down.',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              if (reasons.isEmpty)
                const AppCard(
                  child: Text(
                    'You do not have saved reasons yet. Add a few later so they are ready the next time a live alert hits.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ...reasons.take(5).map((reason) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Text(
                        '• ${_reasonLabel(reason)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _openSupportSheet() {
    final partner = widget.accountabilityPartner;
    final supportMessage = AccountabilityMessageService.buildSupportNowMessage(
      partnerName: partner.name,
    );

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Message support',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                partner.hasName
                    ? 'Reach out to ${partner.name} right now.'
                    : 'Use this support draft right now.',
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Text(
                  supportMessage,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (partner.hasPhone)
                AppButton(
                  label: 'Text ${partner.name.trim().isEmpty ? 'support' : partner.name}',
                  icon: Icons.sms_outlined,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    setState(() {
                      _usedSupport = true;
                    });
                    await _sendSmsOrCopy(
                      phone: partner.phone!,
                      body: supportMessage,
                      copiedMessage: 'Support message copied.',
                    );
                  },
                )
              else if (partner.hasEmail)
                AppButton(
                  label: 'Email ${partner.name.trim().isEmpty ? 'support' : partner.name}',
                  icon: Icons.mail_outline_rounded,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    setState(() {
                      _usedSupport = true;
                    });
                    await _sendEmailOrCopy(
                      email: partner.email!,
                      body: supportMessage,
                      copiedMessage: 'Support message copied.',
                    );
                  },
                )
              else
                AppButton(
                  label: 'Copy support message',
                  icon: Icons.copy_rounded,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _copyText(
                      supportMessage,
                      'Support message copied.',
                    );
                  },
                ),
              if (!partner.hasPhone && !partner.hasEmail) ...[
                const SizedBox(height: 8),
                const Text(
                  'No support contact is set yet. Add one in Accountability so this button can message someone directly next time.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openRealLogSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Log the urge',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save a real urge entry from this live alert moment.',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'I paused and stayed out',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () {
                  final now = DateTime.now();
                  widget.onLogUrge(
                    UrgeSessionLog(
                      startedAt: now,
                      completedAt: now,
                      selectedScriptId: 'live_alert_rescue_paused',
                      openedFullUrgeScript: false,
                      usedCopingStrategies: _usedWait || _usedReasons,
                      usedNearMissEducation: false,
                      usedAccountability: _usedSupport,
                    ),
                  );

                  Navigator.of(sheetContext).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Urge logged. Nice work slowing this moment down.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'I’m still deciding',
                icon: Icons.hourglass_bottom_rounded,
                isPrimary: false,
                onPressed: () {
                  final now = DateTime.now();
                  widget.onLogUrge(
                    UrgeSessionLog(
                      startedAt: now,
                      completedAt: now,
                      selectedScriptId: 'live_alert_rescue_deciding',
                      openedFullUrgeScript: false,
                      usedCopingStrategies: _usedWait || _usedReasons,
                      usedNearMissEducation: false,
                      usedAccountability: _usedSupport,
                    ),
                  );

                  Navigator.of(sheetContext).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Urge logged. Keep using the rescue tools before you decide.'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live alert rescue'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Near a risky place',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _headline,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _body,
                  style: const TextStyle(
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
                  'Do this first',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stay out of the store for one more minute.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The goal right now is simple: add time and distance before the usual stop turns automatic.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                if (_waitUntil != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Pause running until ${_timeLabel(_waitUntil!)}',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Give me 10 minutes',
            icon: Icons.timer_outlined,
            onPressed: _startTenMinutePause,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'I’m leaving now',
            icon: Icons.arrow_back_rounded,
            isPrimary: false,
            onPressed: _leaveNow,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'More support',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use one more tool before you decide anything.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Read my reasons',
                  icon: Icons.menu_book_rounded,
                  isPrimary: false,
                  onPressed: _openReasonsSheet,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Message support',
                  icon: Icons.sms_outlined,
                  isPrimary: false,
                  onPressed: _openSupportSheet,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Log the urge',
                  icon: Icons.edit_note_rounded,
                  isPrimary: false,
                  onPressed: _openRealLogSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick reset',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Put the phone down, breathe once, and move away from the counter or parking spot before you decide anything.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
