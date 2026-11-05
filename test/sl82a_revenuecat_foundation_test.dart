import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/config/app_build_config.dart';

void main() {
  const expectedBuild = String.fromEnvironment(
    'EXPECTED_SCRATCHLESS_BUILD',
  );

  const expectedRevenueCatEnabled = bool.fromEnvironment(
    'EXPECTED_REVENUECAT_ENABLED',
  );

  test('SL-82A RevenueCat enablement matches build policy', () {
    expect(expectedBuild, anyOf('qa', 'store'));

    expect(
      AppBuildConfig.buildName,
      expectedBuild,
    );

    expect(
      AppBuildConfig.revenueCatEnabled,
      expectedRevenueCatEnabled,
    );

    if (expectedBuild == 'qa') {
      expect(
        AppBuildConfig.localPremiumTrialEnabled,
        isTrue,
      );

      expect(
        AppBuildConfig.revenueCatEnabled,
        isFalse,
      );
    }
  });

  test('SL-82A rejects non-production RevenueCat keys', () {
    final key =
        AppBuildConfig.revenueCatAndroidPublicSdkKey;

    if (key.startsWith('test_')) {
      expect(
        AppBuildConfig.revenueCatAndroidKeyLooksProduction,
        isFalse,
      );

      expect(
        AppBuildConfig.revenueCatEnabled,
        isFalse,
      );
    }

    if (expectedRevenueCatEnabled) {
      expect(key, startsWith('goog_'));

      expect(
        AppBuildConfig.revenueCatAndroidKeyLooksProduction,
        isTrue,
      );
    }
  });
}
