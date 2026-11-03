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
  static const String backgroundDisclosureTitle =
      'Background location for Live Risky Places';

  static const String backgroundDisclosureBody =
      'ScratchLess accesses location data to enable Live Risky Place alerts even when the app is closed or not in use. Your location is compared with risky places you choose so ScratchLess can alert you before a risky stop. ScratchLess does not use location for advertising.';

  static const String locationPrivacySummary =
      'Live Risky Places uses location only for places you choose. Background location lets alerts work when ScratchLess is closed or not in use. You can leave background location off and still use ScratchLess without live place alerts.';

  static LocationPermissionPlan premiumPlaceAlertsPlan() {
    return const LocationPermissionPlan(
      stage: LocationPermissionStage.backgroundForPlaceAlerts,
      headline: 'Live Risky Places uses background location',
      body:
          backgroundDisclosureBody,
      nextStepLabel: 'Review location access',
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
