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
  bool _geofenceListenerRegistered = false;

  final Map<String, DateTime> _recentEntryHits = <String, DateTime>{};
  Map<String, RiskyPlace> _monitoredPlacesById = <String, RiskyPlace>{};
  PremiumState _latestPremiumState = PremiumState.free();
  RiskyTimeInsight _latestRiskyTimeInsight = RiskyTimeInsight.empty();

  Future<void> initialize() async {
    if (!_initialized) {
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

    if (!_geofenceListenerRegistered) {
      tl.Tracelet.onGeofence((dynamic event) async {
        await _handleGeofenceEvent(event);
      });
      _geofenceListenerRegistered = true;
    }
  }

  Future<int> requestLocationPermission() async {
    await initialize();
    return await tl.Tracelet.requestPermission();
  }

  Future<int> getPermissionStatus() async {
    await initialize();
    return await tl.Tracelet.getPermissionStatus();
  }

  Future<void> openAppSettings() async {
    await initialize();
    await tl.Tracelet.openAppSettings();
  }

  List<RiskyPlace> enabledPremiumPlaces({
    required PremiumState premiumState,
    required List<RiskyPlace> riskyPlaces,
  }) {
    if (!FeatureGateService.placeAlertsUnlocked(premiumState) ||
        premiumState.livePlaceAlertAccess != 'fullBackground') {
      return const <RiskyPlace>[];
    }

    return riskyPlaces
        .where((place) => place.locationAlertsEnabled)
        .where((place) => place.latitude != null && place.longitude != null)
        .toList();
  }

  Future<void> syncMonitoredPlaces({
    required PremiumState premiumState,
    required List<RiskyPlace> riskyPlaces,
    required RiskyTimeInsight riskyTimeInsight,
  }) async {
    await initialize();

    _latestPremiumState = premiumState;
    _latestRiskyTimeInsight = riskyTimeInsight;

    final places = enabledPremiumPlaces(
      premiumState: premiumState,
      riskyPlaces: riskyPlaces,
    );

    _monitoredPlacesById = {
      for (final place in places) place.id: place,
    };

    await tl.Tracelet.removeGeofences();

    if (places.isEmpty) {
      return;
    }

    for (final place in places) {
      await tl.Tracelet.addGeofence(
        tl.Geofence(
          identifier: place.id,
          latitude: place.latitude!,
          longitude: place.longitude!,
          radius: place.radiusMeters.toDouble(),
          notifyOnEntry: true,
          notifyOnExit: false,
        ),
      );
    }

    await tl.Tracelet.startGeofences();
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

  Future<void> _handleGeofenceEvent(dynamic event) async {
    final identifier = _readEventIdentifier(event);
    if (identifier == null) {
      return;
    }

    final action = _readEventAction(event);
    if (action != null && action.toUpperCase() != 'ENTER') {
      return;
    }

    final place = _monitoredPlacesById[identifier];
    if (place == null) {
      return;
    }

    await handlePlaceEntry(
      premiumState: _latestPremiumState,
      place: place,
      riskyTimeInsight: _latestRiskyTimeInsight,
    );
  }

  String? _readEventIdentifier(dynamic event) {
    try {
      final value = event.identifier;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final geofence = event.geofence;
      final value = geofence.identifier;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    return null;
  }

  String? _readEventAction(dynamic event) {
    try {
      final value = event.action;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final geofence = event.geofence;
      final value = geofence.action;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    return null;
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
