import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/services/location_permission_plan_service.dart';

void main() {
  test('SL-81C disclosure names location and background behavior', () {
    final disclosure =
        LocationPermissionPlanService.backgroundDisclosureBody;

    expect(disclosure, contains('location'));
    expect(disclosure, contains('even when the app is closed or not in use'));
    expect(disclosure, contains('Live Risky Place alerts'));
    expect(disclosure, contains('does not use location for advertising'));
  });

  test('SL-81C privacy summary explains optional background location', () {
    final summary = LocationPermissionPlanService.locationPrivacySummary;

    expect(summary, contains('Background location'));
    expect(summary, contains('closed or not in use'));
    expect(summary, contains('leave background location off'));
    expect(summary, contains('without live place alerts'));
  });

  test('location plan remains explicitly background-scoped', () {
    final plan = LocationPermissionPlanService.premiumPlaceAlertsPlan();

    expect(
      plan.stage,
      LocationPermissionStage.backgroundForPlaceAlerts,
    );
    expect(
      LocationPermissionPlanService.requiresBackgroundLocation(plan.stage),
      isTrue,
    );
  });
}
