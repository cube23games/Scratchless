import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/models/accountability_partner.dart';
import '../../core/models/purchase_log.dart';
import '../../core/models/spend_cap_plan.dart';
import '../../core/models/stop_reason.dart';
import '../../core/services/milestone_service.dart';
import '../../core/services/spend_cap_service.dart';
import '../../core/services/risky_time_service.dart';
import '../../core/services/weekly_summary_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../logging/purchase_log_sheet.dart';
import '../urge/urge_mode_screen.dart';
import 'widgets/primary_urge_button.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  final int currentStreakDays;
  final int bestStreakDays;
  final int urgesDefeated;
  final double averageSpend;
  final double estimatedCashKept;
  final double totalSpent;
  final double monthlySpendEstimate;
  final List<PurchaseLog> logs;
  final List<StopReason> reasons;
  final WeeklySummary weeklySummary;
  final SpendCapPlan spendCapPlan;
  final SpendCapProgress spendCapProgress;
  final RiskyTimeInsight riskyTimeInsight;
  final bool showRiskyTimeWarningCard;
  final AccountabilityPartner accountabilityPartner;
  final MilestoneCardData? celebrationReady;
  final void Function(double amount, String? note, List<String> tags)
      onLogPurchase;
  final void Function(String id, double amount, String? note, List<String> tags)
      onEditPurchase;
  final void Function(String id) onDeletePurchase;
  final VoidCallback onCompleteUrgeSession;
  final VoidCallback onStartPremiumTrial;
  final bool shouldShowSuccessPremiumPrompt;
  final VoidCallback onAcknowledgeSuccessPremiumPrompt;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenCopingStrategies;
  final VoidCallback onOpenNearMissEducation;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenMilestones;
  final VoidCallback onOpenAccountability;
  final VoidCallback onOpenPreStoreMode;
  final ValueChanged<String> onCelebrateMilestone;

  const DashboardScreen({
    super.key,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.urgesDefeated,
    required this.averageSpend,
    required this.estimatedCashKept,
    required this.totalSpent,
    required this.monthlySpendEstimate,
    required this.logs,
    required this.reasons,
    required this.weeklySummary,
    required this.spendCapPlan,
    required this.spendCapProgress,
    required this.riskyTimeInsight,
    required this.showRiskyTimeWarningCard,
    required this.accountabilityPartner,
    required this.celebrationReady,
    required this.onLogPurchase,
    required this.onEditPurchase,
    required this.onDeletePurchase,
    required this.onCompleteUrgeSession,
    required this.onStartPremiumTrial,
    required this.shouldShowSuccessPremiumPrompt,
    required this.onAcknowledgeSuccessPremiumPrompt,
    required this.onOpenHelp,
    required this.onOpenCopingStrategies,
    required this.onOpenNearMissEducation,
    required this.onOpenGoals,
    required this.onOpenMilestones,
    required this.onOpenAccountability,
    required this.onOpenPreStoreMode,
    required this.onCelebrateMilestone,
  });

  void _showEditSheet(BuildContext context, PurchaseLog log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return PurchaseLogSheet(
          initialLog: log,
          onSave: (amount, note, tags) {
            onEditPurchase(log.id, amount, note, tags);
          },
          onDelete: () {
            onDeletePurchase(log.id);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastLog = logs.isEmpty ? null : logs.first;
    final showSpendCapPressureWarning = SpendCapService.hasPressureWarning(
      plan: spendCapPlan,
      progress: spendCapProgress,
    );
    final spendCapPressureHeadline = SpendCapService.pressureHeadline(
      plan: spendCapPlan,
      progress: spendCapProgress,
    );
    final spendCapPressureBody = SpendCapService.pressureBody(
      plan: spendCapPlan,
      progress: spendCapProgress,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScratchLess'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatCard(
            label: 'Ticket-free streak',
            value: '$currentStreakDays day${currentStreakDays == 1 ? '' : 's'}',
            icon: Icons.local_fire_department_rounded,
            subtitle:
                'Best streak: $bestStreakDays day${bestStreakDays == 1 ? '' : 's'}.',
          ),
          const SizedBox(height: 12),
          StatCard(
            label: 'Estimated cash kept',
            value: '\$${estimatedCashKept.toStringAsFixed(0)}',
            icon: Icons.savings_rounded,
            subtitle: 'Based on urge wins and your average spend.',
          ),
          const SizedBox(height: 12),
          StatCard(
            label: 'Urges interrupted',
            value: '$urgesDefeated',
            icon: Icons.shield_rounded,
            subtitle: 'Every interruption matters.',
          ),
          const SizedBox(height: 12),
          StatCard(
            label: 'Logged spend so far',
            value: '\$${totalSpent.toStringAsFixed(0)}',
            icon: Icons.receipt_long_rounded,
            subtitle: 'Track honestly. No shame.',
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: onOpenGoals,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spend cap preview',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  spendCapPlan.dailyCapEnabled
                      ? 'Today: \$${spendCapProgress.todaySpent.toStringAsFixed(0)} / \$${spendCapPlan.dailyCapAmount.toStringAsFixed(0)}'
                      : 'Daily cap is off',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spendCapPlan.weeklyCapEnabled
                      ? 'Week: \$${spendCapProgress.weekSpent.toStringAsFixed(0)} / \$${spendCapPlan.weeklyCapAmount.toStringAsFixed(0)}'
                      : 'Weekly cap is off',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                if (showSpendCapPressureWarning) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Pressure warning',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spendCapPressureHeadline,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    spendCapPressureBody,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open goals',
                  icon: Icons.flag_rounded,
                  isPrimary: false,
                  onPressed: onOpenGoals,
                ),
              ],
            ),
          ),
          if (showRiskyTimeWarningCard) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Risky-time warning',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    riskyTimeInsight.activeHeadline,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    riskyTimeInsight.activeBody,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Open pre-store mode',
                    icon: Icons.directions_car_rounded,
                    isPrimary: false,
                    onPressed: onOpenPreStoreMode,
                  ),
                ],
              ),
            ),
          ],
          if (celebrationReady != null) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Milestone celebration ready',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    celebrationReady!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    celebrationReady!.subtitle,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    celebrationReady!.progressLabel,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Celebrate this win',
                    icon: Icons.celebration_rounded,
                    onPressed: () {
                      onCelebrateMilestone(celebrationReady!.id);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onOpenMilestones,
                      child: const Text('Open milestones'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppCard(
            onTap: onOpenMilestones,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Milestones',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  celebrationReady != null
                      ? 'A new win is ready, and your progress keeps building.'
                      : 'Keep progress visible, not just problems.',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 18,
                  runSpacing: 10,
                  children: [
                    _metric(
                      label: 'Streak',
                      value: '${currentStreakDays}d',
                    ),
                    _metric(
                      label: 'Urge wins',
                      value: '$urgesDefeated',
                    ),
                    _metric(
                      label: 'Cash kept',
                      value: '\$${estimatedCashKept.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Open milestones anytime to review wins and what is coming next.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryUrgeButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UrgeModeScreen(
                    averageSpend: averageSpend,
                    onComplete: onCompleteUrgeSession,
                    onStartPremiumTrial: onStartPremiumTrial,
                    shouldShowSuccessPremiumPrompt:
                        shouldShowSuccessPremiumPrompt,
                    onAcknowledgeSuccessPremiumPrompt:
                        onAcknowledgeSuccessPremiumPrompt,
                    onOpenCopingStrategies: onOpenCopingStrategies,
                    onOpenNearMissEducation: onOpenNearMissEducation,
                    onOpenAccountability: onOpenAccountability,
                    accountabilityPartner: accountabilityPartner,
                    weeklySummary: weeklySummary,
                    currentStreakDays: currentStreakDays,
                    reasons: reasons,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Pre-store mode',
            isPrimary: false,
            icon: Icons.directions_car_rounded,
            onPressed: onOpenPreStoreMode,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Log a scratch-off',
            isPrimary: false,
            icon: Icons.edit_rounded,
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) {
                  return PurchaseLogSheet(
                    onSave: onLogPurchase,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Get help now',
            isPrimary: false,
            icon: Icons.support_agent_rounded,
            onPressed: onOpenHelp,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Coping strategies',
            isPrimary: false,
            icon: Icons.psychology_rounded,
            onPressed: onOpenCopingStrategies,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly snapshot',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _metric(
                      label: 'Spent',
                      value: '\$${weeklySummary.spentThisWeek.toStringAsFixed(0)}',
                    ),
                    _metric(
                      label: 'Kept',
                      value: '\$${weeklySummary.cashKeptThisWeek.toStringAsFixed(0)}',
                    ),
                    _metric(
                      label: 'Purchases',
                      value: '${weeklySummary.purchasesThisWeek}',
                    ),
                    _metric(
                      label: 'Urge wins',
                      value: '${weeklySummary.urgeWinsThisWeek}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  weeklySummary.comparisonMessage,
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
                  'Starting estimate',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${monthlySpendEstimate.toStringAsFixed(0)} per month',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'That estimate came from your onboarding answers. It becomes more useful as you log real behavior.',
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
            onTap: lastLog == null
                ? null
                : () {
                    _showEditSheet(context, lastLog);
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest check-in',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (lastLog == null)
                  const Text(
                    'No purchases logged yet. That is a good chance to start clean and honest.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${lastLog.amount.toStringAsFixed(0)} logged',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(lastLog.createdAt),
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap to edit or delete.',
                        style: TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 12,
                        ),
                      ),
                      if (lastLog.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: lastLog.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                      if (lastLog.note != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          lastLog.note!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _metric({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}  $hour:$minute $suffix';
  }
}
