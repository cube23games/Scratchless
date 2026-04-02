import 'package:flutter/material.dart';

import '../core/models/accountability_partner.dart';
import '../core/models/milestone_state.dart';
import '../core/models/premium_state.dart';
import '../core/models/purchase_log.dart';
import '../core/models/risky_place.dart';
import '../core/models/reminder_settings.dart';
import '../core/models/spend_cap_plan.dart';
import '../core/models/stop_reason.dart';
import '../core/models/urge_session_log.dart';
import '../core/models/weekly_reflection_archive_item.dart';
import '../core/services/local_notification_service.dart';
import '../core/services/premium_prompt_service.dart';
import '../core/services/milestone_service.dart';
import '../core/services/risky_time_service.dart';
import '../core/services/spend_cap_service.dart';
import '../core/services/streak_service.dart';
import '../core/services/weekly_reflection_service.dart';
import '../core/services/weekly_summary_service.dart';
import '../core/storage/app_storage.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'app_theme.dart';

class ScratchLessApp extends StatefulWidget {
  const ScratchLessApp({super.key});

  @override
  State<ScratchLessApp> createState() => _ScratchLessAppState();
}

class _ScratchLessAppState extends State<ScratchLessApp> {
  bool _isLoading = true;
  bool _isOnboarded = false;
  DateTime? _startedAt;

  int _frequencyPerWeek = 3;
  double _averageSpend = 10;
  String _goal = 'Spend less';

  int _urgesDefeated = 0;
  List<PurchaseLog> _logs = <PurchaseLog>[];
  List<UrgeSessionLog> _urgeSessions = <UrgeSessionLog>[];
  ReminderSettings _reminderSettings = ReminderSettings.defaults();
  PremiumState _premiumState = PremiumState.free();
  List<WeeklyReflectionArchiveItem> _weeklyReflectionArchive =
      <WeeklyReflectionArchiveItem>[];
  AccountabilityPartner _accountabilityPartner =
      AccountabilityPartner.empty();
  List<StopReason> _stopReasons = <StopReason>[];
  SpendCapPlan _spendCapPlan = SpendCapPlan.defaults();
  List<RiskyPlace> _riskyPlaces = <RiskyPlace>[];
  bool _hasSeenSuccessPremiumPrompt = false;
  MilestoneState _milestoneState = MilestoneState.empty();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  double get _monthlySpendEstimate {
    return _frequencyPerWeek * _averageSpend * 4.33;
  }

  double get _estimatedCashKept {
    return _urgesDefeated * _averageSpend;
  }

  double get _totalSpent {
    return _logs.fold<double>(0, (sum, log) => sum + log.amount);
  }

  int get _currentStreakDays {
    return StreakService.currentStreakDays(
      startedAt: _startedAt,
      logs: _logs,
    );
  }

  int get _bestStreakDays {
    return StreakService.bestStreakDays(
      startedAt: _startedAt,
      logs: _logs,
    );
  }

  WeeklySummary get _weeklySummary {
    return WeeklySummaryService.build(
      purchaseLogs: _logs,
      urgeSessions: _urgeSessions,
      averageSpend: _averageSpend,
    );
  }

  SpendCapProgress get _spendCapProgress {
    return SpendCapService.build(
      logs: _logs,
      plan: _spendCapPlan,
    );
  }

  RiskyTimeInsight get _riskyTimeInsight {
    return RiskyTimeService.build(
      logs: _logs,
    );
  }

  bool get _showRiskyTimeWarningCard {
    return _reminderSettings.habitTimeWarningsEnabled &&
        _riskyTimeInsight.hasEnoughData &&
        _riskyTimeInsight.isActiveNow;
  }

  List<MilestoneCardData> get _milestoneItems {
    return MilestoneService.buildItems(
      logs: _logs,
      urgesDefeated: _urgesDefeated,
      bestStreakDays: _bestStreakDays,
      estimatedCashKept: _estimatedCashKept,
      milestoneState: _milestoneState,
    );
  }

  MilestoneCardData? get _celebrationReady {
    return MilestoneService.firstUncelebrated(_milestoneItems);
  }

  Future<void> _bootstrap() async {
    await LocalNotificationService.instance.initialize();
    final stored = await AppStorage.load();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _isOnboarded = stored.isOnboarded;
      _startedAt = stored.startedAt;
      _frequencyPerWeek = stored.frequencyPerWeek;
      _averageSpend = stored.averageSpend;
      _goal = stored.goal;
      _urgesDefeated = stored.urgesDefeated;
      _logs = stored.logs;
      _reminderSettings = stored.reminderSettings;
      _urgeSessions = stored.urgeSessions;
      _premiumState = stored.premiumState;
      _weeklyReflectionArchive = stored.weeklyReflectionArchive;
      _accountabilityPartner = stored.accountabilityPartner;
      _stopReasons = stored.stopReasons;
      _spendCapPlan = stored.spendCapPlan;
      _riskyPlaces = stored.riskyPlaces;
      _hasSeenSuccessPremiumPrompt = stored.hasSeenSuccessPremiumPrompt;
      _milestoneState = stored.milestoneState;
    });

    _syncReminderNotifications();
  }

  Future<void> _persistState() async {
    await AppStorage.save(
      StoredAppState(
        isOnboarded: _isOnboarded,
        startedAt: _startedAt,
        frequencyPerWeek: _frequencyPerWeek,
        averageSpend: _averageSpend,
        goal: _goal,
        urgesDefeated: _urgesDefeated,
        logs: _logs,
        reminderSettings: _reminderSettings,
        urgeSessions: _urgeSessions,
        premiumState: _premiumState,
        weeklyReflectionArchive: _weeklyReflectionArchive,
        accountabilityPartner: _accountabilityPartner,
        stopReasons: _stopReasons,
        spendCapPlan: _spendCapPlan,
        riskyPlaces: _riskyPlaces,
        hasSeenSuccessPremiumPrompt: _hasSeenSuccessPremiumPrompt,
        milestoneState: _milestoneState,
      ),
    );
  }

  void _syncReminderNotifications() {
    LocalNotificationService.instance.syncReminderSettings(
      _reminderSettings,
      riskyTimeInsight: _riskyTimeInsight,
    );
  }

  void _completeOnboarding(OnboardingResult result) {
    setState(() {
      _isOnboarded = true;
      _startedAt = DateTime.now();
      _frequencyPerWeek = result.frequencyPerWeek;
      _averageSpend = result.averageSpend;
      _goal = result.goal;
    });

    _persistState();
    _syncReminderNotifications();
  }

  void _logPurchase(double amount, String? note, List<String> tags) {
    setState(() {
      _logs = <PurchaseLog>[
        PurchaseLog(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          amount: amount,
          note: note,
          tags: tags,
        ),
        ..._logs,
      ];
    });

    _persistState();
  }

  void _editPurchase(
    String id,
    double amount,
    String? note,
    List<String> tags,
  ) {
    setState(() {
      _logs = _logs.map((log) {
        if (log.id != id) {
          return log;
        }

        return log.copyWith(
          amount: amount,
          note: note,
          tags: tags,
        );
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    _persistState();
    _syncReminderNotifications();
  }

  void _deletePurchase(String id) {
    setState(() {
      _logs = _logs.where((log) => log.id != id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    _persistState();
    _syncReminderNotifications();
  }

  void _completeUrgeSession() {
    setState(() {
      _urgesDefeated += 1;
      _urgeSessions = <UrgeSessionLog>[
        UrgeSessionLog(
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
          selectedScriptId: 'pre_store_mode',
          openedFullUrgeScript: false,
          usedCopingStrategies: false,
          usedNearMissEducation: false,
          usedAccountability: false,
        ),
        ..._urgeSessions,
      ];
    });

    _persistState();
  }

  void _completeDetailedUrgeSession(UrgeSessionLog session) {
    setState(() {
      _urgesDefeated += 1;
      _urgeSessions = <UrgeSessionLog>[
        session,
        ..._urgeSessions,
      ];
    });

    _persistState();
  }

  void _updateReminderSettings(ReminderSettings settings) {
    setState(() {
      _reminderSettings = settings;
    });

    _persistState();
    _syncReminderNotifications();
  }

  void _startPremiumTrial() {
    if (_premiumState.isPremium) {
      return;
    }

    setState(() {
      _premiumState = PremiumState(
        isPremium: true,
        trialStartedAt: DateTime.now(),
      );
    });

    _persistState();
  }

  void _saveWeeklyReflectionToHistory() {
    final report = WeeklyReflectionService.build(
      weeklySummary: _weeklySummary,
      logs: _logs,
    );

    final now = DateTime.now();
    final weekEnding = DateTime(now.year, now.month, now.day);
    final archiveId =
        '${weekEnding.year}-${weekEnding.month.toString().padLeft(2, '0')}-${weekEnding.day.toString().padLeft(2, '0')}';

    final item = WeeklyReflectionArchiveItem(
      id: archiveId,
      savedAt: now,
      weekEnding: weekEnding,
      title: report.title,
      summary: report.summary,
      strongestWindow: report.strongestWindow,
      topTrigger: report.topTrigger,
      reflections: report.reflections,
      nextStep: report.nextStep,
    );

    setState(() {
      _weeklyReflectionArchive = [
        item,
        ..._weeklyReflectionArchive.where((existing) => existing.id != archiveId),
      ]..sort((a, b) => b.weekEnding.compareTo(a.weekEnding));
    });

    _persistState();
  }

  void _updateAccountabilityPartner(AccountabilityPartner partner) {
    setState(() {
      _accountabilityPartner = partner;
    });

    _persistState();
  }

  void _addStopReason(StopReason reason) {
    setState(() {
      _stopReasons = [
        reason,
        ..._stopReasons.where((item) => item.id != reason.id),
      ];
    });

    _persistState();
  }

  void _editStopReason(StopReason reason) {
    setState(() {
      _stopReasons = _stopReasons.map((item) {
        if (item.id != reason.id) {
          return item;
        }
        return reason;
      }).toList();
    });

    _persistState();
  }

  void _deleteStopReason(String id) {
    setState(() {
      _stopReasons = _stopReasons.where((reason) => reason.id != id).toList();
    });

    _persistState();
  }

  void _updateSpendCapPlan(SpendCapPlan plan) {
    setState(() {
      _spendCapPlan = plan;
    });

    _persistState();
  }

  void _updateGoal(String goal) {
    final nextGoal = goal.trim();
    if (nextGoal.isEmpty) {
      return;
    }

    setState(() {
      _goal = nextGoal;
    });

    _persistState();
  }

  void _addRiskyPlace(RiskyPlace place) {
    setState(() {
      _riskyPlaces = [
        place,
        ..._riskyPlaces.where((item) => item.id != place.id),
      ];
    });

    _persistState();
  }

  void _editRiskyPlace(RiskyPlace place) {
    setState(() {
      _riskyPlaces = _riskyPlaces.map((item) {
        if (item.id != place.id) {
          return item;
        }
        return place;
      }).toList();
    });

    _persistState();
  }

  void _deleteRiskyPlace(String id) {
    setState(() {
      _riskyPlaces = _riskyPlaces.where((place) => place.id != id).toList();
    });

    _persistState();
  }

  void _acknowledgeSuccessPremiumPrompt() {
    if (_hasSeenSuccessPremiumPrompt) {
      return;
    }

    setState(() {
      _hasSeenSuccessPremiumPrompt = true;
    });

    _persistState();
  }

  void _celebrateMilestone(String id) {
    if (_milestoneState.celebratedIds.contains(id)) {
      return;
    }

    setState(() {
      _milestoneState = _milestoneState.copyWith(
        celebratedIds: [
          ..._milestoneState.celebratedIds,
          id,
        ],
      );
    });

    _persistState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScratchLess',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: _isLoading
          ? const _LoadingScreen()
          : _isOnboarded
              ? HomeShell(
                  currentStreakDays: _currentStreakDays,
                  bestStreakDays: _bestStreakDays,
                  urgesDefeated: _urgesDefeated,
                  frequencyPerWeek: _frequencyPerWeek,
                  averageSpend: _averageSpend,
                  estimatedCashKept: _estimatedCashKept,
                  totalSpent: _totalSpent,
                  monthlySpendEstimate: _monthlySpendEstimate,
                  goal: _goal,
                  logs: _logs,
                  urgeSessions: _urgeSessions,
                  reminderSettings: _reminderSettings,
                  weeklySummary: _weeklySummary,
                  premiumState: _premiumState,
                  weeklyReflectionArchive: _weeklyReflectionArchive,
                  accountabilityPartner: _accountabilityPartner,
                  stopReasons: _stopReasons,
                  spendCapPlan: _spendCapPlan,
                  spendCapProgress: _spendCapProgress,
                  riskyPlaces: _riskyPlaces,
                  riskyTimeInsight: _riskyTimeInsight,
                  showRiskyTimeWarningCard: _showRiskyTimeWarningCard,
                  milestoneItems: _milestoneItems,
                  celebrationReady: _celebrationReady,
                  onLogPurchase: _logPurchase,
                  onEditPurchase: _editPurchase,
                  onDeletePurchase: _deletePurchase,
                  onCompleteUrgeSession: _completeUrgeSession,
                  onCompleteDetailedUrgeSession:
                      _completeDetailedUrgeSession,
                  onUpdateReminderSettings: _updateReminderSettings,
                  onStartPremiumTrial: _startPremiumTrial,
                  shouldShowSuccessPremiumPrompt:
                      PremiumPromptService.canShow(
                    type: PremiumPromptType.firstUrgeWin,
                    premiumState: _premiumState,
                    hasSeenSuccessPremiumPrompt:
                        _hasSeenSuccessPremiumPrompt,
                    urgeSessionsCount: _urgeSessions.length,
                  ),
                  onAcknowledgeSuccessPremiumPrompt:
                      _acknowledgeSuccessPremiumPrompt,
                  onSaveWeeklyReflectionToHistory: _saveWeeklyReflectionToHistory,
                  onUpdateAccountabilityPartner: _updateAccountabilityPartner,
                  onAddStopReason: _addStopReason,
                  onEditStopReason: _editStopReason,
                  onDeleteStopReason: _deleteStopReason,
                  onUpdateSpendCapPlan: _updateSpendCapPlan,
                  onAddRiskyPlace: _addRiskyPlace,
                  onEditRiskyPlace: _editRiskyPlace,
                  onDeleteRiskyPlace: _deleteRiskyPlace,
                  onCelebrateMilestone: _celebrateMilestone,
                  onUpdateGoal: _updateGoal,
                )
              : OnboardingScreen(
                  onComplete: _completeOnboarding,
                  onStartPremiumTrial: _startPremiumTrial,
                ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
