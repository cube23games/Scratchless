import 'dart:math' as math;

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
  final bool? isMock;

  const CurrentPlaceCoordinate({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isMock,
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
  static const int _maxRecentEvents = 12;

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
      isMock: _readLocationMockFlag(location),
    );
  }

  Future<String> evaluateCurrentLocationForQa(
    RiskyPlace place,
  ) async {
    final latitude = place.latitude;
    final longitude = place.longitude;
    final label = _placeLabel(place);

    if (latitude == null || longitude == null) {
      final message =
          'QA location check blocked: $label has no coordinates';
      _logEvent(message);
      return message;
    }

    final current = await captureCurrentPosition();
    if (current == null) {
      final message =
          'QA location check blocked: Android location permission unavailable';
      _logEvent(message);
      return message;
    }

    final distance = _distanceMeters(
      current.latitude,
      current.longitude,
      latitude,
      longitude,
    );

    final inside = distance <= place.radiusMeters;
    final mockLabel = current.isMock == null
        ? 'unknown'
        : current.isMock!
            ? 'yes'
            : 'no';

    final message =
        'QA location: ${_metersLabel(distance)} from $label; '
        '${inside ? 'INSIDE' : 'OUTSIDE'} '
        '${_metersLabel(place.radiusMeters.toDouble())} radius; '
        'accuracy ${_metersLabel(current.accuracy)}; '
        'mock $mockLabel';

    _logEvent(message);
    return message;
  }

  Future<String> sendQaTestNotification(
    RiskyPlace place,
  ) async {
    final label = _placeLabel(place);

    final shown =
        await LocalNotificationService.instance.showLivePlaceAlert(
      headline: 'QA risky-place alert',
      body: 'Test alert for $label. Tap to open Live Alert Rescue.',
      placeLabel: label,
    );

    final message = shown
        ? 'QA notification sent for $label'
        : 'QA notification blocked for $label';

    _logEvent(message);
    return message;
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

    final shown =
        await LocalNotificationService.instance.showLivePlaceAlert(
      headline: _liveAlertHeadline(),
      body: _liveAlertBody(place),
      placeLabel: place.label,
    );

    if (!shown) {
      _logEvent(
        'Notification blocked for ${_placeLabel(place)}',
      );
      return false;
    }

    await PlaceAlertCooldownService.instance.markFired(
      place.id,
      now: current,
    );

    _recentEntryHits[place.id] = current;
    _logEvent(
      'Live alert sent for ${_placeLabel(place)}',
    );
    return true;
  }

  Future<void> _handleGeofenceEvent(dynamic event) async {
    final identifier = _readEventIdentifier(event);
    final rawAction = _readRawEventAction(event);
    final action = normalizeGeofenceActionForQa(rawAction);
    final eventType = event.runtimeType.toString();

    if (identifier == null) {
      _logEvent(
        'Geofence event missing identifier; '
        'action ${action ?? 'UNKNOWN'}; '
        'raw ${_compactDebugValue(rawAction)}; '
        'type $eventType',
      );
      return;
    }

    final place = _monitoredPlacesById[identifier];
    final label = place == null
        ? identifier
        : _placeLabel(place);

    _logEvent(
      'Geofence ${action ?? 'UNKNOWN'} for $label; '
      'raw ${_compactDebugValue(rawAction)}; '
      'type $eventType',
    );

    if (action != 'ENTER') {
      return;
    }

    if (place == null) {
      _logEvent('Entered unknown place $identifier');
      return;
    }

    _logEvent(
      'Entered ${_placeLabel(place)} radius',
    );

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

  dynamic _attemptRead(dynamic Function() reader) {
    try {
      return reader();
    } catch (_) {
      return null;
    }
  }

  String _normalizedMapKey(Object? key) {
    return key
        .toString()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toLowerCase();
  }

  dynamic _readMapValue(
    dynamic source,
    List<String> keys,
  ) {
    if (source is! Map) {
      return null;
    }

    final normalizedKeys = keys
        .map(_normalizedMapKey)
        .toSet();

    for (final entry in source.entries) {
      if (normalizedKeys.contains(
        _normalizedMapKey(entry.key),
      )) {
        return entry.value;
      }
    }

    return null;
  }

  List<dynamic> _eventContainers(dynamic event) {
    final containers = <dynamic>[];
    final pending = <dynamic>[event];
    final seenObjects = <int>{};

    while (pending.isNotEmpty && containers.length < 16) {
      final current = pending.removeAt(0);

      if (current == null) {
        continue;
      }

      final identity = identityHashCode(current);
      if (!seenObjects.add(identity)) {
        continue;
      }

      containers.add(current);

      final candidates = <dynamic>[
        _attemptRead(() => current.geofence),
        _attemptRead(() => current.eventPayload),
        _attemptRead(() => current.event_payload),
        _attemptRead(() => current.payload),
        _attemptRead(() => current.data),
        _attemptRead(() => current.event),
        _readMapValue(
          current,
          const <String>[
            'geofence',
            'eventPayload',
            'event_payload',
            'payload',
            'data',
            'event',
          ],
        ),
      ];

      for (final candidate in candidates) {
        if (candidate != null) {
          pending.add(candidate);
        }
      }
    }

    return containers;
  }

  String? _nonEmptyString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? readGeofenceIdentifierForQa(
    dynamic event,
  ) {
    return _readEventIdentifier(event);
  }

  String? readGeofenceActionForQa(
    dynamic event,
  ) {
    return normalizeGeofenceActionForQa(
      _readRawEventAction(event),
    );
  }

  String? _readEventIdentifier(dynamic event) {
    for (final container in _eventContainers(event)) {
      final candidates = <dynamic>[
        _attemptRead(() => container.identifier),
        _attemptRead(() => container.id),
        _readMapValue(
          container,
          const <String>[
            'identifier',
            'geofenceId',
            'geofence_id',
          ],
        ),
      ];

      for (final candidate in candidates) {
        final value = _nonEmptyString(candidate);
        if (value != null) {
          return value;
        }
      }
    }

    return null;
  }

  dynamic _readRawEventAction(dynamic event) {
    for (final container in _eventContainers(event)) {
      final candidates = <dynamic>[
        _attemptRead(() => container.action),
        _attemptRead(() => container.transition),
        _readMapValue(
          container,
          const <String>[
            'action',
            'transition',
            'geofenceAction',
            'geofence_action',
          ],
        ),
      ];

      for (final candidate in candidates) {
        if (candidate != null &&
            candidate.toString().trim().isNotEmpty) {
          return candidate;
        }
      }
    }

    return null;
  }

  String? normalizeGeofenceActionForQa(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return 'ENTER';
        case 2:
          return 'EXIT';
        case 4:
          return 'DWELL';
      }
    }

    final normalized =
        value.toString().trim().toUpperCase();

    if (normalized == '1') {
      return 'ENTER';
    }
    if (normalized == '2') {
      return 'EXIT';
    }
    if (normalized == '4') {
      return 'DWELL';
    }

    final tokens = normalized
        .split(RegExp(r'[^A-Z]+'))
        .where((token) => token.isNotEmpty)
        .toSet();

    if (tokens.contains('ENTER')) {
      return 'ENTER';
    }
    if (tokens.contains('EXIT')) {
      return 'EXIT';
    }
    if (tokens.contains('DWELL')) {
      return 'DWELL';
    }

    return null;
  }

  bool? _readLocationMockFlag(dynamic location) {
    final candidates = <dynamic>[
      _attemptRead(() => location.isMock),
      _attemptRead(() => location.mock),
      _attemptRead(() => location.coords.isMock),
      _attemptRead(() => location.coords.mock),
      _readMapValue(
        location,
        const <String>['isMock', 'mock'],
      ),
      _readMapValue(
        _readMapValue(
          location,
          const <String>['coords'],
        ),
        const <String>['isMock', 'mock'],
      ),
    ];

    for (final candidate in candidates) {
      if (candidate is bool) {
        return candidate;
      }

      final text =
          candidate?.toString().trim().toLowerCase();

      if (text == 'true') {
        return true;
      }
      if (text == 'false') {
        return false;
      }
    }

    return null;
  }

  String _compactDebugValue(dynamic value) {
    if (value == null) {
      return 'missing';
    }

    var text = value
        .toString()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.length > 70) {
      text = '${text.substring(0, 67)}...';
    }

    return text.isEmpty ? 'empty' : text;
  }

  String _placeLabel(RiskyPlace place) {
    final label = place.label.trim();
    return label.isEmpty
        ? 'saved risky place'
        : label;
  }

  double _distanceMeters(
    double firstLatitude,
    double firstLongitude,
    double secondLatitude,
    double secondLongitude,
  ) {
    const earthRadiusMeters = 6371000.0;

    final firstLatRadians =
        firstLatitude * math.pi / 180.0;
    final secondLatRadians =
        secondLatitude * math.pi / 180.0;
    final latitudeDelta =
        (secondLatitude - firstLatitude) *
            math.pi /
            180.0;
    final longitudeDelta =
        (secondLongitude - firstLongitude) *
            math.pi /
            180.0;

    final rawHaversine =
        math.sin(latitudeDelta / 2) *
            math.sin(latitudeDelta / 2) +
        math.cos(firstLatRadians) *
            math.cos(secondLatRadians) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);

    final haversine =
        rawHaversine.clamp(0.0, 1.0).toDouble();

    final angularDistance = 2 *
        math.atan2(
          math.sqrt(haversine),
          math.sqrt(1 - haversine),
        );

    return earthRadiusMeters * angularDistance;
  }

  String _metersLabel(double meters) {
    if (!meters.isFinite) {
      return 'unknown distance';
    }

    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }

    return '${meters.round()} m';
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
