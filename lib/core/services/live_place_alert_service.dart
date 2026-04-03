import 'package:tracelet/tracelet.dart' as tl;

import '../models/premium_state.dart';
import '../models/risky_place.dart';
import 'feature_gate_service.dart';
import 'local_notification_service.dart';
import 'place_alert_cooldown_service.dart';
import 'place_alert_policy_service.dart';
import 'risky_time_service.dart';

class LivePlaceAlertService {
  LivePlaceAlertService._();

  static final LivePlaceAlertService instance = LivePlaceAlertService._();

  static const Duration _burstSuppressionWindow = Duration(seconds: 60);

  bool _initialized = false;
  final Map<String, DateTime> _recentEntryHits = <String, DateTime>{};

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await tl.Tracelet.ready(
      tl.Config(
        geo: tl.GeoConfig(
          desiredAccuracy: tl.DesiredAccuracy.high,
          distanceFilter: 25.0,
        ),
        app: tl.AppConfig(
          stopOnTerminate: false,
          startOnBoot: true,
        ),
        logger: tl.LoggerConfig(
          debug: true,
          logLevel: tl.LogLevel.verbose,
        ),
      ),
    );

    _initialized = true;
  }

  Future<int> requestLocationPermission() async {
    await initialize();
    return await tl.Tracelet.requestPermission();
  }

  List<RiskyPlace> enabledPremiumPlaces({
    required PremiumState premiumState,
    required List<RiskyPlace> riskyPlaces,
  }) {
    if (!FeatureGateService.placeAlertsUnlocked(premiumState)) {
      return const <RiskyPlace>[];
    }

    return riskyPlaces
        .where((place) => place.locationAlertsEnabled)
        .toList();
  }

  Future<bool> handlePlaceEntry({
    required PremiumState premiumState,
    required RiskyPlace place,
    required RiskyTimeInsight riskyTimeInsight,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();

    if (!FeatureGateService.placeAlertsUnlocked(premiumState)) {
      return false;
    }

    if (!place.locationAlertsEnabled) {
      return false;
    }

    final decision = PlaceAlertPolicyService.evaluate(
      premiumState: premiumState,
      place: place,
      riskyTimeInsight: riskyTimeInsight,
    );

    if (!decision.allowed) {
      return false;
    }

    _pruneRecentEntryHits(current);

    final recentHit = _recentEntryHits[place.id];
    if (recentHit != null &&
        current.difference(recentHit) < _burstSuppressionWindow) {
      return false;
    }

    final suppressed = await PlaceAlertCooldownService.instance.shouldSuppress(
      placeId: place.id,
      cooldownMinutes: decision.cooldownMinutes,
      now: current,
    );

    if (suppressed) {
      _recentEntryHits[place.id] = current;
      return false;
    }

    await LocalNotificationService.instance.showLivePlaceAlert(
      headline: decision.headline,
      body: decision.body,
    );

    await PlaceAlertCooldownService.instance.markFired(
      place.id,
      now: current,
    );

    _recentEntryHits[place.id] = current;
    return true;
  }

  void _pruneRecentEntryHits(DateTime now) {
    final expired = <String>[];

    _recentEntryHits.forEach((placeId, firedAt) {
      if (now.difference(firedAt) >= _burstSuppressionWindow) {
        expired.add(placeId);
      }
    });

    for (final placeId in expired) {
      _recentEntryHits.remove(placeId);
    }
  }
}
