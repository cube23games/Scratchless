import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/config/app_build_config.dart';
import 'package:scratchless/core/models/premium_state.dart';
import 'package:scratchless/core/services/feature_gate_service.dart';
import 'package:scratchless/core/services/premium_prompt_service.dart';
import 'package:scratchless/features/onboarding/onboarding_screen.dart';

void main() {
  const expectedBuild = String.fromEnvironment('EXPECTED_SCRATCHLESS_BUILD');

  test('SL-81D separates QA-only surfaces from Store', () {
    expect(expectedBuild, anyOf('qa', 'store'));
    final isQa = expectedBuild == 'qa';

    expect(AppBuildConfig.buildName, expectedBuild);
    expect(AppBuildConfig.localPremiumTrialEnabled, isQa);
    expect(AppBuildConfig.deferredPlaceSearchVisible, isQa);
    expect(AppBuildConfig.internalDiagnosticsVisible, isQa);
  });

  test('SL-81D Store never offers the simulated Premium trial', () {
    final label = FeatureGateService.premiumCtaLabel(PremiumState.free());
    expect(
      label,
      expectedBuild == 'qa' ? 'Start 3-day free trial' : 'Premium coming soon',
    );
  });

  test('SL-81D generic Premium prompt semantics stay build-agnostic', () {
    final canShow = PremiumPromptService.canShow(
      type: PremiumPromptType.firstWeeklyReflection,
      premiumState: PremiumState.free(),
      hasSeenSuccessPremiumPrompt: false,
      urgeWinsCount: 0,
    );

    expect(canShow, isTrue);
  });
  testWidgets('SL-81D onboarding keeps QA paywall out of Store',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onComplete: (_) {},
          onStartPremiumTrial: () {},
        ),
      ),
    );

    for (var step = 0; step < 8; step += 1) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Start Free'), findsOneWidget);

    if (expectedBuild == 'qa') {
      expect(find.text('See Premium'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    } else {
      expect(find.text('See Premium'), findsNothing);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Enable QA Premium'), findsNothing);
    }
  });

}
