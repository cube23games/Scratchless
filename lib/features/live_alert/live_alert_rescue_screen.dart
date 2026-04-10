import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class LiveAlertRescueScreen extends StatefulWidget {
  final String placeLabel;
  final bool autoStartTenMinutePause;

  const LiveAlertRescueScreen({
    super.key,
    required this.placeLabel,
    this.autoStartTenMinutePause = false,
  });

  @override
  State<LiveAlertRescueScreen> createState() => _LiveAlertRescueScreenState();
}

class _LiveAlertRescueScreenState extends State<LiveAlertRescueScreen> {
  DateTime? _waitUntil;
  bool _autoStarted = false;

  String get _headline => widget.placeLabel.trim().isEmpty
      ? 'Pause before you go in'
      : 'Pause before ${widget.placeLabel}';

  String get _body => widget.placeLabel.trim().isEmpty
      ? 'This stop has been risky before. Give yourself one more pause before you decide.'
      : '${widget.placeLabel} has been risky before. Give yourself one more pause before you decide.';

  String get _supportDraft => widget.placeLabel.trim().isEmpty
      ? 'I hit a ScratchLess live alert and I am trying not to go in. Can you check on me for the next 10 minutes?'
      : 'I hit a ScratchLess live alert near ${widget.placeLabel} and I am trying not to go in. Can you check on me for the next 10 minutes?';

  String _quickLogDraft() {
    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeLabel = '$hour:$minute';

    if (widget.placeLabel.trim().isEmpty) {
      return 'Live alert at $timeLabel. I paused instead of walking in.';
    }

    return 'Live alert near ${widget.placeLabel} at $timeLabel. I paused instead of walking in.';
  }

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

  void _startTenMinutePause({bool showSnackBar = true}) {
    setState(() {
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
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Text(
                'Read your reasons',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Use one strong reason to slow this moment down.',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• One ticket can turn into a spiral.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Real relief lasts longer than the urge.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Keeping my money helps real life more than this stop does.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• A short pause now protects the rest of the day.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSupportSheet() {
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
              const Text(
                'Use this draft to reach out fast.',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Text(
                  _supportDraft,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Copy support message',
                icon: Icons.copy_rounded,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _copyText(
                    _supportDraft,
                    'Support message copied.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openQuickLogSheet() {
    final draft = _quickLogDraft();

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
                'Capture this moment before the details blur together.',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Text(
                  draft,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Copy quick urge note',
                icon: Icons.copy_rounded,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _copyText(
                    draft,
                    'Quick urge note copied.',
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
                  onPressed: _openQuickLogSheet,
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
