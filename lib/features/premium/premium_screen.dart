import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/models/premium_state.dart';
import '../../core/services/feature_gate_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class PremiumScreen extends StatelessWidget {
  final PremiumState premiumState;
  final VoidCallback onStartTrial;

  const PremiumScreen({
    super.key,
    required this.premiumState,
    required this.onStartTrial,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = premiumState.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScratchLess Premium'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FeatureGateService.premiumStatusLabel(premiumState),
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Deeper insights. More support. More clarity.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ScratchLess Premium is for users who want a clearer picture of their patterns and more support tools over time.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: FeatureGateService.premiumCtaLabel(premiumState),
                  icon: Icons.workspace_premium_rounded,
                  onPressed: isPremium
                      ? null
                      : () {
                          onStartTrial();
                          Navigator.of(context).pop();
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  isPremium
                      ? 'Premium is active on this device.'
                      : 'Billing is not wired yet in this build. This is the soft upgrade scaffold.',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
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
                  'What stays free',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                _BulletLine('Purchase logging'),
                _BulletLine('Edit and delete mistakes'),
                _BulletLine('Urge mode'),
                _BulletLine('Basic streaks'),
                _BulletLine('Core reminders'),
                _BulletLine('Basic weekly snapshot'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium unlocks',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                _BulletLine('30-day trigger breakdown'),
                _BulletLine('Longer history view'),
                _BulletLine('Weekly reflection summaries'),
                _BulletLine('Custom reminder schedules'),
                _BulletLine('Exportable progress reports'),
                _BulletLine('Future live place alerts'),
                _BulletLine('Future accountability tools'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
