import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../../core/services/support_link_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static Future<void> _launchOrFallback({
    required BuildContext context,
    required Future<bool> Function() action,
    required String fallbackText,
    required String failureMessage,
  }) async {
    final ok = await action();

    if (!context.mounted) {
      return;
    }

    if (ok) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: fallbackText),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failureMessage),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get help now'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support without shame',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Reach a person when your own tools are not enough.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Scratch-off and lottery problems count as gambling problems. You can ask for support before things get worse.',
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
                  'Gambling support',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'National Problem Gambling Helpline',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Call, text, or chat 24/7/365 for gambling-related support, information, and local referrals.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helpline is for gambling support. It is not an emergency crisis line.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Call 1-800-MY-RESET',
                  icon: Icons.call_rounded,
                  onPressed: () {
                    _launchOrFallback(
                      context: context,
                      action: SupportLinkService.launchCall,
                      fallbackText:
                          SupportLinkService.gamblingDisplayNumber,
                      failureMessage:
                          'Could not open the dialer. Copied 1-800-MY-RESET.',
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Text 1-800-MY-RESET',
                  icon: Icons.sms_rounded,
                  isPrimary: false,
                  onPressed: () {
                    _launchOrFallback(
                      context: context,
                      action: SupportLinkService.launchText,
                      fallbackText:
                          SupportLinkService.gamblingDisplayNumber,
                      failureMessage:
                          'Could not open messaging. Copied 1-800-MY-RESET.',
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Open live chat',
                  icon: Icons.chat_bubble_rounded,
                  isPrimary: false,
                  onPressed: () {
                    _launchOrFallback(
                      context: context,
                      action: SupportLinkService.launchChat,
                      fallbackText: SupportLinkService.chatUri.toString(),
                      failureMessage:
                          'Could not open chat. Copied the chat link.',
                    );
                  },
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
                  'Crisis or immediate danger',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use crisis support when this is bigger than a gambling urge.',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you are in emotional distress, thinking about suicide, or need someone to talk with right now, call or text 988.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you or someone else is in immediate physical danger or has a medical emergency, call 911.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Call 988',
                  icon: Icons.health_and_safety_rounded,
                  isPrimary: false,
                  onPressed: () {
                    _launchOrFallback(
                      context: context,
                      action: SupportLinkService.launch988Call,
                      fallbackText: SupportLinkService.crisis988Display,
                      failureMessage:
                          'Could not open the dialer. Copied 988.',
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Text 988',
                  icon: Icons.sms_rounded,
                  isPrimary: false,
                  onPressed: () {
                    _launchOrFallback(
                      context: context,
                      action: SupportLinkService.launch988Text,
                      fallbackText: SupportLinkService.crisis988Display,
                      failureMessage:
                          'Could not open messaging. Copied 988.',
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Call 911',
                  icon: Icons.emergency_rounded,
                  isPrimary: false,
                  onPressed: () {
                    _launchOrFallback(
                      context: context,
                      action: SupportLinkService.launch911Call,
                      fallbackText: SupportLinkService.emergency911Display,
                      failureMessage:
                          'Could not open the dialer. Copied 911.',
                    );
                  },
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
                  'More gambling-support resources',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Find help by state',
                  icon: Icons.map_rounded,
                  isPrimary: false,
                  onPressed: () {
                    _launchOrFallback(
                      context: context,
                      action: SupportLinkService.launchHelpByState,
                      fallbackText:
                          SupportLinkService.helpByStateUri.toString(),
                      failureMessage:
                          'Could not open state help. Copied the state help link.',
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Open help resources',
                  icon: Icons.open_in_browser_rounded,
                  isPrimary: false,
                  onPressed: () {
                    _launchOrFallback(
                      context: context,
                      action: SupportLinkService.launchHelpHome,
                      fallbackText:
                          SupportLinkService.helpHomeUri.toString(),
                      failureMessage:
                          'Could not open help resources. Copied the help link.',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
