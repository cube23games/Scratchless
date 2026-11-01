import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/config/app_build_config.dart';
import '../../core/models/accountability_partner.dart';
import '../../core/models/premium_state.dart';
import '../../core/models/reminder_settings.dart';
import '../../core/models/starting_plan.dart';
import '../../core/services/risky_time_service.dart';
import '../../features/premium/premium_screen.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../urge/urge_scripts_screen.dart';
import 'starting_plan_editor_screen.dart';

class ProfileScreen extends StatelessWidget {
  final StartingPlan startingPlan;
  final int currentStreakDays;
  final int bestStreakDays;
  final ReminderSettings reminderSettings;
  final RiskyTimeInsight riskyTimeInsight;
  final PremiumState premiumState;
  final AccountabilityPartner accountabilityPartner;
  final ValueChanged<ReminderSettings> onUpdateReminderSettings;
  final VoidCallback onStartPremiumTrial;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenAccountability;
  final VoidCallback onOpenReasons;
  final VoidCallback onOpenCopingStrategies;
  final VoidCallback onOpenNearMissEducation;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenMilestones;
  final VoidCallback onOpenPreStoreMode;
  final VoidCallback onOpenRiskyPlaces;
  final VoidCallback onOpenLiveAlertRescueTest;
  final ValueChanged<StartingPlan> onUpdateStartingPlan;

  const ProfileScreen({
    super.key,
    required this.startingPlan,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.reminderSettings,
    required this.riskyTimeInsight,
    required this.premiumState,
    required this.accountabilityPartner,
    required this.onUpdateReminderSettings,
    required this.onStartPremiumTrial,
    required this.onOpenHelp,
    required this.onOpenAccountability,
    required this.onOpenReasons,
    required this.onOpenCopingStrategies,
    required this.onOpenNearMissEducation,
    required this.onOpenGoals,
    required this.onOpenMilestones,
    required this.onOpenPreStoreMode,
    required this.onOpenRiskyPlaces,
    required this.onOpenLiveAlertRescueTest,
    required this.onUpdateStartingPlan,
  });

  void _openUrgeScriptsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const UrgeScriptsScreen(),
      ),
    );
  }

  Future<void> _openStartingPlanEditor(BuildContext context) async {
    final result = await Navigator.of(context).push<StartingPlan>(
      MaterialPageRoute<StartingPlan>(
        builder: (_) => StartingPlanEditorScreen(plan: startingPlan),
        fullscreenDialog: true,
      ),
    );

    if (result == null) {
      return;
    }

    onUpdateStartingPlan(result);

    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Starting Plan updated'),
        ),
      );
    }
  }

  void _openPremiumScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PremiumScreen(
          premiumState: premiumState,
          onStartTrial: onStartPremiumTrial,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskyWindowTitle = riskyTimeInsight.hasEnoughData
        ? 'Detected window: ${riskyTimeInsight.windowLabel} (${riskyTimeInsight.anchorLabel})'
        : 'Not enough log data yet';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            onTap: onOpenMilestones,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestones',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Celebrate progress on purpose',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Open your milestone list and reinforce the wins you have actually earned.',
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
            onTap: onOpenPreStoreMode,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pre-store mode',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Interrupt it before the stop',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Use a fast intervention mode before the parking lot becomes a purchase.',
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
            onTap: onOpenRiskyPlaces,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risky places watchlist',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Save your danger-zone stops',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Keep a manual list of the stores and routes that tend to pull you toward tickets.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (AppBuildConfig.qaToolsEnabled) ...[
            const SizedBox(height: 12),
            AppCard(
              onTap: onOpenLiveAlertRescueTest,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Internal testing',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Test live alert rescue',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ScratchLess QA only. Opens the real rescue screen with your saved reasons, accountability contact, and risky-place data.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppCard(
            onTap: onOpenGoals,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals & spend caps',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Plan spending ahead of time',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Set optional daily and weekly caps so the app can help you spot when things are drifting.',
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
                  'Risky-time nudges',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  riskyWindowTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  riskyTimeInsight.profileSummary,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show habit-time warnings on Home'),
                  subtitle: const Text(
                    'Surface a warning card near your harder hours.',
                  ),
                  value: reminderSettings.habitTimeWarningsEnabled,
                  onChanged: (value) {
                    onUpdateReminderSettings(
                      reminderSettings.copyWith(
                        habitTimeWarningsEnabled: value,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: onOpenHelp,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get help now',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Open support options',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Call, text, or chat help when an urge feels too big to handle alone.',
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
            onTap: onOpenCopingStrategies,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coping strategies',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'What to do during the urge',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Open short, practical strategies for slowing the urge down and choosing something else.',
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
            onTap: () => _openUrgeScriptsScreen(context),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scratch-off urge scripts',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Use situation-based urge scripts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Open short scripts for payday urges, seeing a display, recent wins, passing a store, and the “only one” trap.',
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
            onTap: onOpenNearMissEducation,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Near-miss psychology',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Why almost winning can pull you back in',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Open a calm explanation of why near misses can feel powerful even when they still cost you money.',
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
            onTap: onOpenReasons,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reasons to stop',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Keep your reasons close',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Save the words you want to hear when the urge gets loud.',
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
            onTap: onOpenAccountability,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accountability partner',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  accountabilityPartner.hasName
                      ? accountabilityPartner.name
                      : startingPlan.prefersPrivateSupport
                          ? 'Private for now'
                          : 'Set up accountability',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  accountabilityPartner.hasName
                      ? 'Save quick check-in, support, and progress-sharing messages for a trusted person.'
                      : startingPlan.prefersPrivateSupport
                          ? 'Your Starting Plan says to keep support private for now. You can still add someone anytime.'
                          : 'Save one trusted person and use ready-to-send support and accountability messages.',
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
            onTap: () => _openPremiumScreen(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ScratchLess Premium',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  premiumState.isPremium ? 'Premium active' : 'Premium available',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  premiumState.isPremium
                      ? 'You have access to premium scaffolding and deeper tools.'
                      : 'Unlock deeper insights, longer history, custom reminders, and more support tools.',
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
            onTap: () => _openStartingPlanEditor(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Starting Plan',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  startingPlan.goal,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${startingPlan.frequencyPerWeek} purchase periods/week • about \$${startingPlan.averageSpend.toStringAsFixed(0)} each time',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Starting estimate: \$${startingPlan.estimatedMonthlySpend.toStringAsFixed(0)} per month',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                if (startingPlan.triggers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pull-ins: ${startingPlan.triggers.join(', ')}',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Tap to review or change your baseline, triggers, first rescue move, and support preference.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
                  'Streak summary',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current: $currentStreakDays day${currentStreakDays == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Best: $bestStreakDays day${bestStreakDays == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.mutedText,
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
                  'Reminders',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'These are separate from risky-time warnings. They drive your actual support reminder settings.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily check-in reminder'),
                  subtitle: const Text('Gentle nudge to log how the day went.'),
                  value: reminderSettings.dailyCheckInEnabled,
                  onChanged: (value) {
                    onUpdateReminderSettings(
                      reminderSettings.copyWith(
                        dailyCheckInEnabled: value,
                      ),
                    );
                  },
                ),
                if (reminderSettings.dailyCheckInEnabled) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Preferred hour',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [17, 19, 20, 21].map((hour) {
                      final selected =
                          reminderSettings.dailyCheckInHour == hour;
                      final suffix = hour >= 12 ? 'PM' : 'AM';
                      final displayHour = hour > 12 ? hour - 12 : hour;
                      final label = '$displayHour:00 $suffix';

                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) {
                          onUpdateReminderSettings(
                            reminderSettings.copyWith(
                              dailyCheckInHour: hour,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Evening support reminder'),
                  subtitle: const Text(
                    'Daily 7:00 PM pause-first reminder.',
                  ),
                  value: reminderSettings.eveningSupportEnabled,
                  onChanged: (value) {
                    onUpdateReminderSettings(
                      reminderSettings.copyWith(
                        eveningSupportEnabled: value,
                      ),
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
