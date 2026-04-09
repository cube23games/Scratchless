import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class LiveAlertRescueScreen extends StatefulWidget {
  final String placeLabel;

  const LiveAlertRescueScreen({
    super.key,
    required this.placeLabel,
  });

  @override
  State<LiveAlertRescueScreen> createState() => _LiveAlertRescueScreenState();
}

class _LiveAlertRescueScreenState extends State<LiveAlertRescueScreen> {
  DateTime? _waitUntil;

  String get _headline =>
      widget.placeLabel.trim().isEmpty ? 'Pause before you go in' : 'Pause before ${widget.placeLabel}';

  String get _body =>
      widget.placeLabel.trim().isEmpty
          ? 'This stop has been risky before. Give yourself one more pause before you decide.'
          : '${widget.placeLabel} has been risky before. Give yourself one more pause before you decide.';

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _startTenMinutePause() {
    setState(() {
      _waitUntil = DateTime.now().add(const Duration(minutes: 10));
    });

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
                  'The goal right now is simple: add a little time and distance before the usual stop turns automatic.',
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
