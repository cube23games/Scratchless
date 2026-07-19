import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/models/accountability_partner.dart';
import '../../core/models/premium_state.dart';
import '../../core/models/purchase_log.dart';
import '../../core/models/risky_place.dart';
import '../../core/models/reminder_settings.dart';
import '../../core/models/spend_cap_plan.dart';
import '../../core/models/stop_reason.dart';
import '../../core/models/urge_session_log.dart';
import '../../core/models/weekly_reflection_archive_item.dart';
import '../../core/services/milestone_service.dart';
import '../../core/services/risky_time_service.dart';
import '../../core/services/spend_cap_service.dart';
import '../../core/services/weekly_summary_service.dart';
import '../accountability/accountability_screen.dart';
import '../coping/coping_strategies_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../education/near_miss_screen.dart';
import '../goals/goals_screen.dart';
import '../help/help_screen.dart';
import '../milestones/milestones_screen.dart';
import '../pre_store/pre_store_mode_screen.dart';
import '../profile/profile_screen.dart';
import '../risky_places/risky_places_screen.dart';
import '../reasons/reasons_screen.dart';
import '../stats/stats_screen.dart';

class HomeShell extends StatefulWidget {
  final int currentStreakDays;
  final int bestStreakDays;
  final int urgesDefeated;
  final int frequencyPerWeek;
  final double averageSpend;
  final double estimatedCashKept;
  final double totalSpent;
  final double monthlySpendEstimate;
  final String goal;
  final List<PurchaseLog> logs;
  final List<UrgeSessionLog> urgeSessions;
  final ReminderSettings reminderSettings;
  final WeeklySummary weeklySummary;
  final PremiumState premiumState;
  final List<WeeklyReflectionArchiveItem> weeklyReflectionArchive;
  final AccountabilityPartner accountabilityPartner;
  final List<StopReason> stopReasons;
  final SpendCapPlan spendCapPlan;
  final SpendCapProgress spendCapProgress;
  final List<RiskyPlace> riskyPlaces;
  final RiskyTimeInsight riskyTimeInsight;
  final bool showRiskyTimeWarningCard;
  final List<MilestoneCardData> milestoneItems;
  final MilestoneCardData? celebrationReady;
  final void Function(double amount, String? note, List<String> tags)
      onLogPurchase;
  final void Function(String id, double amount, String? note, List<String> tags)
      onEditPurchase;
  final void Function(String id) onDeletePurchase;
  final VoidCallback onCompleteUrgeSession;
  final ValueChanged<UrgeSessionLog> onCompleteDetailedUrgeSession;
  final ValueChanged<ReminderSettings> onUpdateReminderSettings;
  final VoidCallback onStartPremiumTrial;
  final Future<String> Function() onEnableLivePlaceAlertsForeground;
  final Future<String> Function() onEnableLivePlaceAlertsBackground;
  final VoidCallback onOpenLiveAlertRescueTest;
  final bool shouldShowSuccessPremiumPrompt;
  final VoidCallback onAcknowledgeSuccessPremiumPrompt;
  final VoidCallback onSaveWeeklyReflectionToHistory;
  final ValueChanged<AccountabilityPartner> onUpdateAccountabilityPartner;
  final ValueChanged<StopReason> onAddStopReason;
  final ValueChanged<StopReason> onEditStopReason;
  final void Function(String id) onDeleteStopReason;
  final ValueChanged<SpendCapPlan> onUpdateSpendCapPlan;
  final ValueChanged<RiskyPlace> onAddRiskyPlace;
  final ValueChanged<RiskyPlace> onEditRiskyPlace;
  final void Function(String id) onDeleteRiskyPlace;
  final ValueChanged<String> onCelebrateMilestone;
  final ValueChanged<String> onUpdateGoal;

  const HomeShell({
    super.key,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.urgesDefeated,
    required this.frequencyPerWeek,
    required this.averageSpend,
    required this.estimatedCashKept,
    required this.totalSpent,
    required this.monthlySpendEstimate,
    required this.goal,
    required this.logs,
    required this.urgeSessions,
    required this.reminderSettings,
    required this.weeklySummary,
    required this.premiumState,
    required this.weeklyReflectionArchive,
    required this.accountabilityPartner,
    required this.stopReasons,
    required this.spendCapPlan,
    required this.spendCapProgress,
    required this.riskyPlaces,
    required this.riskyTimeInsight,
    required this.showRiskyTimeWarningCard,
    required this.milestoneItems,
    required this.celebrationReady,
    required this.onLogPurchase,
    required this.onEditPurchase,
    required this.onDeletePurchase,
    required this.onCompleteUrgeSession,
    required this.onCompleteDetailedUrgeSession,
    required this.onUpdateReminderSettings,
    required this.onStartPremiumTrial,
    required this.onEnableLivePlaceAlertsForeground,
    required this.onEnableLivePlaceAlertsBackground,
    required this.onOpenLiveAlertRescueTest,
    required this.shouldShowSuccessPremiumPrompt,
    required this.onAcknowledgeSuccessPremiumPrompt,
    required this.onSaveWeeklyReflectionToHistory,
    required this.onUpdateAccountabilityPartner,
    required this.onAddStopReason,
    required this.onEditStopReason,
    required this.onDeleteStopReason,
    required this.onUpdateSpendCapPlan,
    required this.onAddRiskyPlace,
    required this.onEditRiskyPlace,
    required this.onDeleteRiskyPlace,
    required this.onCelebrateMilestone,
    required this.onUpdateGoal,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void _openHelp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HelpScreen(),
      ),
    );
  }

  void _openCopingStrategies() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CopingStrategiesScreen(),
      ),
    );
  }

  void _openNearMissEducation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NearMissScreen(),
      ),
    );
  }

  void _openGoals() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalsScreen(
          plan: widget.spendCapPlan,
          progress: widget.spendCapProgress,
          onSavePlan: widget.onUpdateSpendCapPlan,
        ),
      ),
    );
  }

  void _openPreStoreMode() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreStoreModeScreen(
          onComplete: widget.onCompleteUrgeSession,
          onOpenCopingStrategies: _openCopingStrategies,
          onOpenAccountability: _openAccountability,
          onOpenRiskyPlaces: _openRiskyPlaces,
          accountabilityPartner: widget.accountabilityPartner,
          riskyPlaces: widget.riskyPlaces,
          weeklySummary: widget.weeklySummary,
          currentStreakDays: widget.currentStreakDays,
        ),
      ),
    );
  }

  void _openMilestones() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MilestonesScreen(
          items: widget.milestoneItems,
          celebrationReady: widget.celebrationReady,
          onCelebrateMilestone: widget.onCelebrateMilestone,
        ),
      ),
    );
  }

  void _openRiskyPlaces() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RiskyPlacesScreen(
          places: widget.riskyPlaces,
          premiumState: widget.premiumState,
          riskyTimeInsight: widget.riskyTimeInsight,
          onStartPremiumTrial: widget.onStartPremiumTrial,
          onEnableLivePlaceAlertsBackground:
              widget.onEnableLivePlaceAlertsBackground,
          onAddPlace: widget.onAddRiskyPlace,
          onEditPlace: widget.onEditRiskyPlace,
          onDeletePlace: widget.onDeleteRiskyPlace,
        ),
      ),
    );
  }

  void _openAccountability() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountabilityScreen(
          partner: widget.accountabilityPartner,
          onSavePartner: widget.onUpdateAccountabilityPartner,
          weeklySummary: widget.weeklySummary,
          logs: widget.logs,
          currentStreakDays: widget.currentStreakDays,
          bestStreakDays: widget.bestStreakDays,
        ),
      ),
    );
  }

  void _openReasons() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReasonsScreen(
          reasons: widget.stopReasons,
          onAddReason: widget.onAddStopReason,
          onEditReason: widget.onEditStopReason,
          onDeleteReason: widget.onDeleteStopReason,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        currentStreakDays: widget.currentStreakDays,
        bestStreakDays: widget.bestStreakDays,
        urgesDefeated: widget.urgesDefeated,
        averageSpend: widget.averageSpend,
        estimatedCashKept: widget.estimatedCashKept,
        totalSpent: widget.totalSpent,
        monthlySpendEstimate: widget.monthlySpendEstimate,
        logs: widget.logs,
        reasons: widget.stopReasons,
        weeklySummary: widget.weeklySummary,
        spendCapPlan: widget.spendCapPlan,
        spendCapProgress: widget.spendCapProgress,
        riskyTimeInsight: widget.riskyTimeInsight,
        showRiskyTimeWarningCard: widget.showRiskyTimeWarningCard,
        accountabilityPartner: widget.accountabilityPartner,
        riskyPlaces: widget.riskyPlaces,
        celebrationReady: widget.celebrationReady,
        onLogPurchase: widget.onLogPurchase,
        onEditPurchase: widget.onEditPurchase,
        onDeletePurchase: widget.onDeletePurchase,
        onCompleteUrgeSession: widget.onCompleteUrgeSession,
        onCompleteDetailedUrgeSession:
            widget.onCompleteDetailedUrgeSession,
        onStartPremiumTrial: widget.onStartPremiumTrial,
        shouldShowSuccessPremiumPrompt: widget.shouldShowSuccessPremiumPrompt,
        onAcknowledgeSuccessPremiumPrompt:
            widget.onAcknowledgeSuccessPremiumPrompt,
        onOpenHelp: _openHelp,
        onOpenCopingStrategies: _openCopingStrategies,
        onOpenNearMissEducation: _openNearMissEducation,
        onOpenGoals: _openGoals,
        onOpenMilestones: _openMilestones,
        onOpenPreStoreMode: _openPreStoreMode,
        onOpenRiskyPlaces: _openRiskyPlaces,
        onOpenAccountability: _openAccountability,

        onCelebrateMilestone: widget.onCelebrateMilestone,
      ),
      StatsScreen(
        logs: widget.logs,
        urgeSessions: widget.urgeSessions,
        currentStreakDays: widget.currentStreakDays,
        bestStreakDays: widget.bestStreakDays,
        averageSpend: widget.averageSpend,
        monthlySpendEstimate: widget.monthlySpendEstimate,
        estimatedCashKept: widget.estimatedCashKept,
        weeklySummary: widget.weeklySummary,
        premiumState: widget.premiumState,
        weeklyReflectionArchive: widget.weeklyReflectionArchive,
        onStartPremiumTrial: widget.onStartPremiumTrial,
        onEnableLivePlaceAlertsForeground:
            widget.onEnableLivePlaceAlertsForeground,
        onEnableLivePlaceAlertsBackground:
            widget.onEnableLivePlaceAlertsBackground,
        onSaveWeeklyReflectionToHistory: widget.onSaveWeeklyReflectionToHistory,
        onEditPurchase: widget.onEditPurchase,
        onDeletePurchase: widget.onDeletePurchase,
      ),
      ProfileScreen(
        goal: widget.goal,
        frequencyPerWeek: widget.frequencyPerWeek,
        averageSpend: widget.averageSpend,
        monthlySpendEstimate: widget.monthlySpendEstimate,
        currentStreakDays: widget.currentStreakDays,
        bestStreakDays: widget.bestStreakDays,
        reminderSettings: widget.reminderSettings,
        premiumState: widget.premiumState,
        accountabilityPartner: widget.accountabilityPartner,
        riskyTimeInsight: widget.riskyTimeInsight,
        onUpdateReminderSettings: widget.onUpdateReminderSettings,
        onStartPremiumTrial: widget.onStartPremiumTrial,
        onOpenHelp: _openHelp,
        onOpenAccountability: _openAccountability,
        onOpenReasons: _openReasons,
        onOpenCopingStrategies: _openCopingStrategies,
        onOpenNearMissEducation: _openNearMissEducation,
        onOpenGoals: _openGoals,
        onOpenMilestones: _openMilestones,
        onOpenPreStoreMode: _openPreStoreMode,
        onOpenRiskyPlaces: _openRiskyPlaces,
        onOpenLiveAlertRescueTest:
            widget.onOpenLiveAlertRescueTest,
        onUpdateGoal: widget.onUpdateGoal,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.card,
        indicatorColor: Colors.white.withOpacity(0.08),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
