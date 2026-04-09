import 'package:tracelet/tracelet.dart' as tl;

import '../models/premium_state.dart';
import '../models/risky_place.dart';
import 'feature_gate_service.dart';
import 'local_notification_service.dart';
import 'place_alert_cooldown_service.dart';
import 'place_alert_policy_service.dart';
import 'risky_time_service.dart';

class CurrentPlaceCoordinate {
  final double latitude;
  final double longitude;
  final double accuracy;

  const CurrentPlaceCoordinate({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}

class LiveAlertDebugEvent {
  final DateTime createdAt;
  final String message;

  const LiveAlertDebugEvent({
    required this.createdAt,
    required this.message,
  });
}

class LiveAlertPlaceDebugItem {
  final String placeId;
  final String label;
  final bool armed;
  final String status;

  const LiveAlertPlaceDebugItem({
    required this.placeId,
    required this.label,
    required this.armed,
    required this.status,
  });
}

class LiveAlertDebugState {
  final String accessLevel;
  final String permissionLabel;
  final bool isArmed;
  final int eligiblePlaceCount;
  final int blockedPlaceCount;
  final String? topBlocker;
  final String? lastEventMessage;
  final DateTime? lastEventAt;
  final List<LiveAlertPlaceDebugItem> placeItems;
  final List<LiveAlertDebugEvent> recentEvents;

  const LiveAlertDebugState({
    required this.accessLevel,
    required this.permissionLabel,
    required this.isArmed,
    required this.eligiblePlaceCount,
    required this.blockedPlaceCount,
    required this.topBlocker,
    required this.lastEventMessage,
    required this.lastEventAt,
    required this.placeItems,
    required this.recentEvents,
  });

  factory LiveAlertDebugState.empty() {
    return const LiveAlertDebugState(
      accessLevel: 'off',
      permissionLabel: 'Off',
      isArmed: false,
      eligiblePlaceCount: 0,
      blockedPlaceCount: 0,
      topBlocker: null,
      lastEventMessage: null,
      lastEventAt: null,
      placeItems: <LiveAlertPlaceDebugItem>[],
      recentEvents: <LiveAlertDebugEvent>[],
    );
  }
}

class LivePlaceAlertService {
  LivePlaceAlertService._();

  static final LivePlaceAlertService instance = LivePlaceAlertService._();

  static const Duration _burstSuppressionWindow = Duration(seconds: 60);
  static const int _maxRecentEvents = 5;

  bool _initialized = false;
  bool _geofenceListenerRegistered = false;

  final Map<String, DateTime> _recentEntryHits = <String, DateTime>{};
  final List<LiveAlertDebugEvent> _recentEvents = <LiveAlertDebugEvent>[];

  Map<String, RiskyPlace> _monitoredPlacesById = <String, RiskyPlace>{};
  List<RiskyPlace> _latestAllRiskyPlaces = <RiskyPlace>[];
  PremiumState _latestPremiumState = PremiumState.free();
  RiskyTimeInsight _latestRiskyTimeInsight = RiskyTimeInsight.empty();
  String _lastKnownAccess = 'off';
  List<RiskyPlace> _latestRiskyPlaces = <RiskyPlace>[];

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
      _logEvent('Geofence listener registered');
    }
  }

  Future<int> requestLocationPermission() async {
    await initialize();
    return await tl.Tracelet.requestPermission();
  }

  Future<String> currentAccessLevel() async {
    await initialize();

    try {
      final status = await tl.Tracelet.getPermissionStatus();
      final access = _normalizePermissionStatus(status);
      _lastKnownAccess = access;
      return access;
    } catch (_) {
      return _lastKnownAccess;
    }
  }

  Future<int> getPermissionStatus() async {
    await initialize();
    return await tl.Tracelet.getPermissionStatus();
  }

  Future<void> openAppSettings() async {
    await initialize();
    await tl.Tracelet.openAppSettings();
  }

  Future<CurrentPlaceCoordinate?> captureCurrentPosition() async {
    await initialize();

    final authStatus = await tl.Tracelet.requestPermission();
    if (authStatus != 2 && authStatus != 3) {
      return null;
    }

    final location = await tl.Tracelet.getCurrentPosition(
      desiredAccuracy: tl.DesiredAccuracy.high,
      timeout: 30,
      persist: false,
    );

    return CurrentPlaceCoordinate(
      latitude: location.coords.latitude,
      longitude: location.coords.longitude,
      accuracy: location.coords.accuracy,
    );
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

    final access = await currentAccessLevel();
    _lastKnownAccess = access;
    _latestPremiumState =
        premiumState.copyWith(livePlaceAlertAccess: access);
    _latestRiskyTimeInsight = riskyTimeInsight;
    _latestRiskyPlaces = List<RiskyPlace>.from(riskyPlaces);

    if (access != 'fullBackground') {
      _monitoredPlacesById = <String, RiskyPlace>{};
      await tl.Tracelet.removeGeofences();
      _logEvent('Permission sync: ${_permissionLabel(access)}');
      return;
    }

    final places = enabledPremiumPlaces(
      premiumState: _latestPremiumState,
      riskyPlaces: riskyPlaces,
    );

    _monitoredPlacesById = {
      for (final place in places) place.id: place,
    };

    await tl.Tracelet.removeGeofences();

    if (places.isEmpty) {
      _logEvent('No places are armed yet');
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
    if (places.length == 1) {
      _logEvent('Geofence armed for ${places.first.label}');
    } else {
      _logEvent('Geofences armed for ${places.length} places');
    }
  }


  String _liveAlertHeadline() {
    return 'Pause before you go in';
  }

  String _liveAlertBody(RiskyPlace place) {
    final label = place.label.trim();
    if (label.isEmpty) {
      return "You're near a saved risky place. Open Rescue before you decide.";
    }

    return "You're near $label. Open Rescue before you decide.";
  }

  Future<bool> handlePlaceEntry({
    required PremiumState premiumState,
    required RiskyPlace place,
    required RiskyTimeInsight riskyTimeInsight,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();

    if (!FeatureGateService.placeAlertsUnlocked(premiumState)) {
      _logEvent('Ignored ${place.label}: Premium inactive');
      return false;
    }

    if (!place.locationAlertsEnabled) {
      _logEvent('Ignored ${place.label}: Live alerts off');
      return false;
    }

    final decision = PlaceAlertPolicyService.evaluate(
      premiumState: premiumState,
      place: place,
      riskyTimeInsight: riskyTimeInsight,
    );

    if (!decision.allowed) {
      _logEvent('Ignored ${place.label}: Not in a risky window');
      return false;
    }

    _pruneRecentEntryHits(current);

    final recentHit = _recentEntryHits[place.id];
    if (recentHit != null &&
        current.difference(recentHit) < _burstSuppressionWindow) {
      _logEvent('Waiting for re-entry for ${place.label}');
      return false;
    }

    final suppressed = await PlaceAlertCooldownService.instance.shouldSuppress(
      placeId: place.id,
      cooldownMinutes: decision.cooldownMinutes,
      now: current,
    );

    if (suppressed) {
      _recentEntryHits[place.id] = current;
      _logEvent('Held by cooldown for ${place.label}');
      return false;
    }

    await LocalNotificationService.instance.showLivePlaceAlert(
      headline: _liveAlertHeadline(),
      body: _liveAlertBody(place),
      placeLabel: place.label,
    );

    await PlaceAlertCooldownService.instance.markFired(
      place.id,
      now: current,
    );

    _recentEntryHits[place.id] = current;
    _logEvent('Live alert sent for ${place.label}');
    return true;
  }

  Future<void> _handleGeofenceEvent(dynamic event) async {
    final identifier = _readEventIdentifier(event);
    if (identifier == null) {
      _logEvent('Ignored geofence event with no identifier');
      return;
    }

    final action = _readEventAction(event);
    if (action != null && action.toUpperCase() != 'ENTER') {
      _logEvent('Ignored non-entry event for $identifier');
      return;
    }

    final place = _monitoredPlacesById[identifier];
    if (place == null) {
      _logEvent('Entered unknown place $identifier');
      return;
    }

    _logEvent('Entered ${place.label} radius');

    await handlePlaceEntry(
      premiumState: _latestPremiumState,
      place: place,
      riskyTimeInsight: _latestRiskyTimeInsight,
    );
  }

  LiveAlertPlaceDebugItem _buildPlaceDebugItem(RiskyPlace place) {
    if (!place.locationAlertsEnabled) {
      return LiveAlertPlaceDebugItem(
        placeId: place.id,
        label: place.label,
        armed: false,
        status: 'Turn on live alerts for this place',
      );
    }

    if (place.latitude == null || place.longitude == null) {
      return LiveAlertPlaceDebugItem(
        placeId: place.id,
        label: place.label,
        armed: false,
        status: 'Save this place’s location first',
      );
    }

    if (!FeatureGateService.placeAlertsUnlocked(_latestPremiumState)) {
      return LiveAlertPlaceDebugItem(
        placeId: place.id,
        label: place.label,
        armed: false,
        status: 'Start Premium to arm this place',
      );
    }

    if (_latestPremiumState.livePlaceAlertAccess != 'fullBackground') {
      return LiveAlertPlaceDebugItem(
        placeId: place.id,
        label: place.label,
        armed: false,
        status: 'Needs one more Android permission step',
      );
    }

    return LiveAlertPlaceDebugItem(
      placeId: place.id,
      label: place.label,
      armed: true,
      status: 'Armed',
    );
  }


  LiveAlertDebugState getDebugState() {
    final placeItems = _latestRiskyPlaces.map((place) {
      final bool armed = _monitoredPlacesById.containsKey(place.id);

      String status;
      if (!FeatureGateService.placeAlertsUnlocked(_latestPremiumState)) {
        status = 'Start Premium to arm this place';
      } else if (!place.locationAlertsEnabled) {
        status = 'Turn on live alerts for this place';
      } else if (place.latitude == null || place.longitude == null) {
        status = 'Save this place’s location first';
      } else if (_lastKnownAccess != 'fullBackground') {
        status = 'Needs one more Android permission step';
      } else if (armed) {
        status = 'Armed';
      } else {
        status = 'Needs one more Android permission step';
      }

      return LiveAlertPlaceDebugItem(
        placeId: place.id,
        label: place.label,
        armed: armed,
        status: status,
      );
    }).toList();

    final blockedPlaceCount = placeItems.where((item) => !item.armed).length;

    return LiveAlertDebugState(
      isArmed: _monitoredPlacesById.isNotEmpty,
      accessLevel: _lastKnownAccess,
      permissionLabel: _permissionLabel(_lastKnownAccess),
      eligiblePlaceCount: _monitoredPlacesById.length,
      blockedPlaceCount: blockedPlaceCount,
      topBlocker: _topBlocker(),
      lastEventMessage: _recentEvents.isEmpty ? null : _recentEvents.first.message,
      lastEventAt: _recentEvents.isEmpty ? null : _recentEvents.first.createdAt,
      recentEvents: List<LiveAlertDebugEvent>.from(_recentEvents),
      placeItems: placeItems,
    );
  }

  String _normalizePermissionStatus(int status) {
    if (status == 3) {
      return 'fullBackground';
    }
    if (status == 2) {
      return 'foregroundOnly';
    }
    return 'off';
  }

  String _permissionLabel(String access) {
    switch (access) {
      case 'fullBackground':
        return 'Full background';
      case 'foregroundOnly':
        return 'Foreground only';
      default:
        return 'Off';
    }
  }

  String? _topBlocker() {
    if (!FeatureGateService.placeAlertsUnlocked(_latestPremiumState)) {
      return 'Need Premium';
    }

    final hasEnabledPlaces =
        _latestAllRiskyPlaces.any((place) => place.locationAlertsEnabled);

    if (!hasEnabledPlaces) {
      return 'Turn on live alerts for a saved place';
    }

    final hasEnabledMissingCoordinates = _latestAllRiskyPlaces.any(
      (place) =>
          place.locationAlertsEnabled &&
          (place.latitude == null || place.longitude == null),
    );

    if (_latestPremiumState.livePlaceAlertAccess != 'fullBackground') {
      return 'Finish live alerts in Android settings';
    }

    if (hasEnabledMissingCoordinates) {
      return 'Save a location for at least one place';
    }

    if (_monitoredPlacesById.isEmpty) {
      return 'Nothing armed yet';
    }

    return null;
  }

  void _logEvent(String message) {
    final nextEvent = LiveAlertDebugEvent(
      createdAt: DateTime.now(),
      message: message,
    );

    if (_recentEvents.isNotEmpty && _recentEvents.first.message == message) {
      _recentEvents[0] = nextEvent;
      return;
    }

    _recentEvents.insert(0, nextEvent);

    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeRange(_maxRecentEvents, _recentEvents.length);
    }
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
