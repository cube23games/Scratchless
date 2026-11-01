import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/models/accountability_partner.dart';
import 'package:scratchless/core/models/starting_plan.dart';
import 'package:scratchless/core/services/weekly_summary_service.dart';
import 'package:scratchless/features/urge/urge_mode_screen.dart';

void main() {
  testWidgets('Urge Mode honors the persisted Starting Plan', (tester) async {
    const plan = StartingPlan(
      problemFit: 'I buy scratch-offs more than I want to.',
      goal: 'Stay in control',
      frequencyPerWeek: 2,
      averageSpend: 15,
      triggers: <String>['Store displays', 'Stress'],
      preferredRescue: 'My reasons to stop',
      supportPreference: 'Keep it private for now',
    );

    final weeklySummary = WeeklySummaryService.build(
      purchaseLogs: const [],
      urgeSessions: const [],
      averageSpend: plan.averageSpend,
      now: DateTime(2026, 11, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UrgeModeScreen(
          startingPlan: plan,
          onComplete: (_) {},
          onStartPremiumTrial: () {},
          shouldShowSuccessPremiumPrompt: false,
          onAcknowledgeSuccessPremiumPrompt: () {},
          onOpenCopingStrategies: () {},
          onOpenNearMissEducation: () {},
          onOpenAccountability: () {},
          accountabilityPartner: AccountabilityPartner.empty(),
          weeklySummary: weeklySummary,
          currentStreakDays: 0,
          reasons: const [],
        ),
      ),
    );

    expect(find.text('Your Starting Plan'), findsOneWidget);
    expect(find.textContaining('Store displays'), findsWidgets);
    expect(find.text('Preferred first move: My reasons to stop'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('The display caught your attention'),
      500,
    );
    expect(find.text('The display caught your attention'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Private support for now'),
      -500,
    );
    expect(find.text('Private support for now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
