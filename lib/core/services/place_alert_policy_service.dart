import '../models/premium_state.dart';
import '../models/risky_place.dart';
import 'feature_gate_service.dart';
import 'risky_time_service.dart';

enum PlaceAlertSeverity {
  standard,
  elevated,
  high,
}

class PlaceAlertDecision {
  final bool allowed;
  final PlaceAlertSeverity severity;
  final String headline;
  final String body;
  final int cooldownMinutes;

  const PlaceAlertDecision({
    required this.allowed,
    required this.severity,
    required this.headline,
    required this.body,
    required this.cooldownMinutes,
  });
}

class PlaceAlertPolicyService {
  static PlaceAlertDecision evaluate({
    required PremiumState premiumState,
    required RiskyPlace place,
    required RiskyTimeInsight riskyTimeInsight,
  }) {
    if (!FeatureGateService.placeAlertsUnlocked(premiumState) ||
        !place.locationAlertsEnabled) {
      return const PlaceAlertDecision(
        allowed: false,
        severity: PlaceAlertSeverity.standard,
        headline: 'Place alerts unavailable',
        body: 'Premium live place alerts are not enabled for this stop.',
        cooldownMinutes: 360,
      );
    }

    final boostedByTime =
        riskyTimeInsight.hasEnoughData && riskyTimeInsight.isActiveNow;

    if (place.isTopRisk && boostedByTime) {
      return const PlaceAlertDecision(
        allowed: true,
        severity: PlaceAlertSeverity.high,
        headline: 'High-risk moment',
        body:
            'You are near a top-risk place during one of your harder windows. Open ScratchLess now.',
        cooldownMinutes: 240,
      );
    }

    if (place.isTopRisk) {
      return const PlaceAlertDecision(
        allowed: true,
        severity: PlaceAlertSeverity.elevated,
        headline: 'Top-risk place ahead',
        body:
            'This stop has pulled you in before. Pause before going in.',
        cooldownMinutes: 240,
      );
    }

    return const PlaceAlertDecision(
      allowed: true,
      severity: PlaceAlertSeverity.standard,
      headline: 'Risky place ahead',
      body:
          'This stop is on your watchlist. Open ScratchLess before it turns automatic.',
      cooldownMinutes: 360,
    );
  }
}
