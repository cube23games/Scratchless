import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/models/premium_state.dart';
import '../../core/services/feature_gate_service.dart';
import '../../core/services/location_permission_plan_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class PremiumScreen extends StatelessWidget {
  final PremiumState premiumState;
  final VoidCallback onStartTrial;
  final Future<String> Function()? onEnableLivePlaceAlertsForeground;
  final Future<String> Function()? onEnableLivePlaceAlertsBackground;

  const PremiumScreen({
    super.key,
    required this.premiumState,
    required this.onStartTrial,
    this.onEnableLivePlaceAlertsForeground,
    this.onEnableLivePlaceAlertsBackground,
  });

  String _livePlaceAlertHeadline() {
    switch (premiumState.livePlaceAlertAccess) {
      case 'fullBackground':
        return 'Persistent live alerts ready';
      case 'foregroundOnly':
        return 'Foreground access ready';
      default:
        return 'Live place alerts are off';
    }
  }

  String _livePlaceAlertBody() {
    switch (premiumState.livePlaceAlertAccess) {
      case 'fullBackground':
        return 'ScratchLess has the background access needed for persistent live place alerts.';
      case 'foregroundOnly':
        return 'Foreground location is granted. One Android background step remains before persistent live alerts can run.';
      default:
        return 'Enable location from this screen when you are ready to start the live place-alert setup.';
    }
  }

  Future<void> _handleEnableLivePlaceAlerts(BuildContext context) async {
    if (onEnableLivePlaceAlertsForeground == null) {
      return;
    }

    final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Enable live place alerts?'),
              content: const Text(
                'ScratchLess uses location only for your saved risky places so it can warn you before a stop turns automatic. This first step asks for foreground location only.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Not now'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!proceed || !context.mounted) {
      return;
    }

    final nextAccess = await onEnableLivePlaceAlertsForeground!();

    if (!context.mounted) {
      return;
    }

    final message = nextAccess == 'foregroundOnly'
        ? 'Foreground location is ready. Background access comes next.'
        : 'Location permission was not granted.';

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _handleFinishLivePlaceAlerts(BuildContext context) async {
    if (onEnableLivePlaceAlertsBackground == null) {
      return;
    }

    final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Finish live place alerts?'),
              content: const Text(
                'To keep live place alerts working when ScratchLess is not open, Android needs one more background location step. ScratchLess will send you to the app settings if Android requires it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Not now'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!proceed || !context.mounted) {
      return;
    }

    final nextAccess = await onEnableLivePlaceAlertsBackground!();

    if (!context.mounted) {
      return;
    }

    final message = nextAccess == 'fullBackground'
        ? 'Persistent live place alerts are ready.'
        : 'Background access is still not enabled. You can finish it later from this screen.';

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = premiumState.isPremium;
    final placeAlertsPlan =
        LocationPermissionPlanService.premiumPlaceAlertsPlan();

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
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live place-alert permission plan',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  placeAlertsPlan.headline,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  placeAlertsPlan.body,
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
                  'Live place-alert status',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _livePlaceAlertHeadline(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _livePlaceAlertBody(),
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Enable live place alerts',
                  icon: Icons.location_on_rounded,
                  onPressed: isPremium &&
                          premiumState.livePlaceAlertAccess == 'off' &&
                          onEnableLivePlaceAlertsForeground != null
                      ? () => _handleEnableLivePlaceAlerts(context)
                      : null,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Finish live place alerts',
                  icon: Icons.settings_rounded,
                  isPrimary: false,
                  onPressed: isPremium &&
                          premiumState.livePlaceAlertAccess == 'foregroundOnly' &&
                          onEnableLivePlaceAlertsBackground != null
                      ? () => _handleFinishLivePlaceAlerts(context)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  !isPremium
                      ? 'Start Premium first to unlock the live place-alert setup.'
                      : premiumState.livePlaceAlertAccess == 'off'
                          ? 'This first step asks for foreground location only.'
                          : premiumState.livePlaceAlertAccess == 'foregroundOnly'
                              ? 'Foreground access is saved. The Android background/settings step is next.'
                              : 'Persistent live place alerts are ready for your coordinate-based risky places.',
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
