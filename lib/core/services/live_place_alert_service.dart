import 'package:tracelet/tracelet.dart' as tl;

import '../models/premium_state.dart';
import '../models/risky_place.dart';
import 'feature_gate_service.dart';

class LivePlaceAlertService {
  LivePlaceAlertService._();

  static final LivePlaceAlertService instance = LivePlaceAlertService._();

  bool _initialized = false;

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
}
