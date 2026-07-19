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
  bool _leavingConfirmed = false;
  String? _actionFeedbackTitle;
  String? _actionFeedbackBody;

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

  void _showFeedback(String message) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  void _setActionFeedback({
    required String title,
    required String body,
    bool showSnackBar = true,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _actionFeedbackTitle = title;
      _actionFeedbackBody = body;
    });

    if (showSnackBar) {
      _showFeedback(body);
    }
  }

  Future<void> _clearPauseWhenFinished(
    DateTime waitUntil,
  ) async {
    final delay = waitUntil.difference(DateTime.now());

    if (delay.isNegative) {
      return;
    }

    await Future<void>.delayed(delay);

    if (!mounted || _waitUntil != waitUntil) {
      return;
    }

    final pauseWasLatestFeedback =
        _actionFeedbackTitle == '10-minute pause active';

    setState(() {
      _waitUntil = null;

      if (pauseWasLatestFeedback) {
        _actionFeedbackTitle = '10-minute pause complete';
        _actionFeedbackBody =
            'You created real distance from the automatic decision. Choose what protects you next.';
      }
    });
  }

  Future<void> _copyText(
    String text,
    String confirmation,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showFeedback(confirmation);
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

    if (mounted) {
      setState(() {
        _usedSupport = true;
      });
    }

    var opened = false;

    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }

    if (!mounted) {
      return;
    }

    if (opened) {
      _setActionFeedback(
        title: 'Text message opened',
        body:
            'Send the message now so someone knows you need support.',
      );
      return;
    }

    await _copyText(body, copiedMessage);

    _setActionFeedback(
      title: 'Support message copied',
      body: copiedMessage,
      showSnackBar: false,
    );
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

    if (mounted) {
      setState(() {
        _usedSupport = true;
      });
    }

    var opened = false;

    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }

    if (!mounted) {
      return;
    }

    if (opened) {
      _setActionFeedback(
        title: 'Email draft opened',
        body:
            'Send the email now so someone knows you need support.',
      );
      return;
    }

    await _copyText(body, copiedMessage);

    _setActionFeedback(
      title: 'Support message copied',
      body: copiedMessage,
      showSnackBar: false,
    );
  }

  void _startTenMinutePause({
    bool showSnackBar = true,
  }) {
    final now = DateTime.now();
    final activeUntil = _waitUntil;

    if (activeUntil != null &&
        activeUntil.isAfter(now)) {
      if (showSnackBar) {
        _showFeedback(
          'Pause already running until ${_timeLabel(activeUntil)}. Stay outside and keep moving away.',
        );
      }
      return;
    }

    final waitUntil =
        now.add(const Duration(minutes: 10));

    setState(() {
      _usedWait = true;
      _waitUntil = waitUntil;
      _actionFeedbackTitle = '10-minute pause active';
      _actionFeedbackBody =
          'Stay outside and use another rescue tool while time works in your favor.';
    });

    _clearPauseWhenFinished(waitUntil);

    if (showSnackBar) {
      _showFeedback(
        'Ten-minute pause started. Stay outside and give the urge time to weaken.',
      );
    }
  }

  void _leaveNow() {
    if (_leavingConfirmed) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _leavingConfirmed = true;
      _actionFeedbackTitle = 'You chose to leave';
      _actionFeedbackBody =
          'Nice work. Put distance between you and the stop.';
    });

    _showFeedback(
      'Nice work. Put distance between you and the stop.',
    );
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
                    await _sendSmsOrCopy(
                      phone: partner.phone!,
                      body: supportMessage,
                      copiedMessage:
                          'Text app was unavailable. Support message copied instead.',
                    );
                  },
                )
              else if (partner.hasEmail)
                AppButton(
                  label: 'Email ${partner.name.trim().isEmpty ? 'support' : partner.name}',
                  icon: Icons.mail_outline_rounded,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _sendEmailOrCopy(
                      email: partner.email!,
                      body: supportMessage,
                      copiedMessage:
                          'Email app was unavailable. Support message copied instead.',
                    );
                  },
                )
              else
                AppButton(
                  label: 'Copy support message',
                  icon: Icons.copy_rounded,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();

                    if (mounted) {
                      setState(() {
                        _usedSupport = true;
                      });
                    }

                    const copiedMessage =
                        'Support message copied. Paste and send it now.';

                    await _copyText(
                      supportMessage,
                      copiedMessage,
                    );

                    _setActionFeedback(
                      title: 'Support message copied',
                      body: copiedMessage,
                      showSnackBar: false,
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
          if (_actionFeedbackTitle != null &&
              _actionFeedbackBody != null) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _actionFeedbackTitle!,
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _actionFeedbackBody!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                    '10-minute pause active until ${_timeLabel(_waitUntil!)}',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stay outside and use another rescue tool while time works in your favor.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: _waitUntil == null
                ? 'Give me 10 minutes'
                : 'Pause running',
            icon: _waitUntil == null
                ? Icons.timer_outlined
                : Icons.hourglass_top_rounded,
            onPressed: _startTenMinutePause,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: _leavingConfirmed
                ? 'Done — keep moving'
                : 'I’m leaving now',
            icon: _leavingConfirmed
                ? Icons.directions_walk_rounded
                : Icons.arrow_back_rounded,
            isPrimary: _leavingConfirmed,
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
