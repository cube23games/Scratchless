import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/config/app_build_config.dart';
import 'package:scratchless/core/models/premium_state.dart';
import 'package:scratchless/core/services/feature_gate_service.dart';
import 'package:scratchless/core/services/premium_prompt_service.dart';

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

  test('SL-81D Store suppresses local Premium upsell prompts', () {
    final canShow = PremiumPromptService.canShow(
      type: PremiumPromptType.firstWeeklyReflection,
      premiumState: PremiumState.free(),
      hasSeenSuccessPremiumPrompt: false,
      urgeWinsCount: 0,
    );

    expect(canShow, expectedBuild == 'qa');
  });
}
