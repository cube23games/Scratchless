import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scratchless/core/models/accountability_partner.dart';
import 'package:scratchless/core/models/milestone_state.dart';
import 'package:scratchless/core/models/premium_state.dart';
import 'package:scratchless/core/models/starting_plan.dart';
import 'package:scratchless/core/models/reminder_settings.dart';
import 'package:scratchless/core/models/spend_cap_plan.dart';
import 'package:scratchless/core/storage/app_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy baseline migrates without inventing personal answers', () async {
    SharedPreferences.setMockInitialValues({
      'is_onboarded': true,
      'frequency_per_week': 5,
      'average_spend': 22.0,
      'goal': 'Keep more money',
    });

    final state = await AppStorage.load();

    expect(state.startingPlan.frequencyPerWeek, 5);
    expect(state.startingPlan.averageSpend, 22);
    expect(state.startingPlan.goal, 'Keep more money');
    expect(state.startingPlan.problemFit, isNull);
    expect(state.startingPlan.triggers, isEmpty);
    expect(state.startingPlan.preferredRescue, isNull);
    expect(state.startingPlan.supportPreference, isNull);
  });

  test('Starting Plan round-trips through AppStorage', () async {
    SharedPreferences.setMockInitialValues({});

    const plan = StartingPlan(
      problemFit: 'I buy scratch-offs more than I want to.',
      goal: 'Stop completely',
      frequencyPerWeek: 4,
      averageSpend: 25,
      triggers: <String>['Payday', 'Store displays'],
      preferredRescue: 'My reasons to stop',
      supportPreference: 'Keep it private for now',
    );

    final state = StoredAppState(
      isOnboarded: true,
      startedAt: DateTime(2026, 11, 1),
      startingPlan: plan,
      urgesDefeated: 0,
      legacyUrgeWinsBaseline: 0,
      logs: const [],
      reminderSettings: ReminderSettings.defaults(),
      urgeSessions: const [],
      premiumState: PremiumState.free(),
      weeklyReflectionArchive: const [],
      accountabilityPartner: AccountabilityPartner.empty(),
      stopReasons: const [],
      spendCapPlan: SpendCapPlan.defaults(),
      riskyPlaces: const [],
      hasSeenSuccessPremiumPrompt: false,
      milestoneState: MilestoneState.empty(),
    );

    await AppStorage.save(state);
    final loaded = await AppStorage.load();

    expect(loaded.startingPlan.toJson(), plan.toJson());
    expect(loaded.frequencyPerWeek, 4);
    expect(loaded.averageSpend, 25);
    expect(loaded.goal, 'Stop completely');
  });

  test('editing baseline changes dependent estimates', () {
    const initial = StartingPlan(
      problemFit: null,
      goal: 'Stay in control',
      frequencyPerWeek: 2,
      averageSpend: 15,
      triggers: <String>[],
      preferredRescue: null,
      supportPreference: null,
    );

    final edited = initial.copyWith(
      frequencyPerWeek: 5,
      averageSpend: 20,
    );

    expect(initial.estimatedMonthlySpend, closeTo(129.9, 0.001));
    expect(edited.estimatedMonthlySpend, closeTo(433, 0.001));
  });

  test('known onboarding triggers choose a relevant first urge script', () {
    const payday = StartingPlan(
      problemFit: null,
      goal: 'Stay in control',
      frequencyPerWeek: 2,
      averageSpend: 15,
      triggers: <String>['Payday'],
      preferredRescue: null,
      supportPreference: null,
    );
    const display = StartingPlan(
      problemFit: null,
      goal: 'Stay in control',
      frequencyPerWeek: 2,
      averageSpend: 15,
      triggers: <String>['Store displays'],
      preferredRescue: null,
      supportPreference: null,
    );

    expect(payday.preferredUrgeScriptId, 'after_paycheck');
    expect(display.preferredUrgeScriptId, 'saw_display');
    expect(
      display.copyWith(supportPreference: 'Keep it private for now')
          .prefersPrivateSupport,
      isTrue,
    );
  });
}
