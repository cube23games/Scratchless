enum LocationPermissionStage {
  none,
  foregroundOnly,
  backgroundForPlaceAlerts,
}

class LocationPermissionPlan {
  final LocationPermissionStage stage;
  final String headline;
  final String body;
  final String nextStepLabel;

  const LocationPermissionPlan({
    required this.stage,
    required this.headline,
    required this.body,
    required this.nextStepLabel,
  });
}

class LocationPermissionPlanService {
  static LocationPermissionPlan premiumPlaceAlertsPlan() {
    return const LocationPermissionPlan(
      stage: LocationPermissionStage.backgroundForPlaceAlerts,
      headline: 'Location permission will come later',
      body:
          'ScratchLess will first explain why place alerts help, then ask for location only when you choose live place alerts. Background access will be requested only for persistent place-based warnings.',
      nextStepLabel: 'Premium live place alerts',
    );
  }

  static LocationPermissionPlan foregroundOnlyPlan() {
    return const LocationPermissionPlan(
      stage: LocationPermissionStage.foregroundOnly,
      headline: 'Foreground location comes first',
      body:
          'Before live place alerts run in the background, ScratchLess should first ask for foreground location with a clear explanation tied to the feature.',
      nextStepLabel: 'Ask in feature flow',
    );
  }

  static bool requiresBackgroundLocation(LocationPermissionStage stage) {
    return stage == LocationPermissionStage.backgroundForPlaceAlerts;
  }
}
