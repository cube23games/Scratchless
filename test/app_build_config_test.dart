import 'package:flutter_test/flutter_test.dart';
import 'package:scratchless/core/config/app_build_config.dart';

void main() {
  const expectedBuild = String.fromEnvironment(
    'EXPECTED_SCRATCHLESS_BUILD',
  );

  test('ScratchLess build configuration matches CI expectation', () {
    expect(
      expectedBuild,
      anyOf('qa', 'store'),
      reason: 'CI must provide EXPECTED_SCRATCHLESS_BUILD.',
    );

    expect(AppBuildConfig.buildName, expectedBuild);
    expect(
      AppBuildConfig.qaToolsEnabled,
      expectedBuild == 'qa',
    );
    expect(
      AppBuildConfig.storeBuild,
      expectedBuild == 'store',
    );
  });
}
