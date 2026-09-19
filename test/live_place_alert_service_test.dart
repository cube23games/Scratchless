import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/tracelet.dart' as tl;

import 'package:scratchless/core/models/risky_place.dart';
import 'package:scratchless/core/services/live_place_alert_service.dart';

void main() {
  final service = LivePlaceAlertService.instance;

  group('geofence action normalization', () {
    test('accepts plain and enum-style entry values', () {
      expect(
        service.normalizeGeofenceActionForQa('ENTER'),
        'ENTER',
      );
      expect(
        service.normalizeGeofenceActionForQa('enter'),
        'ENTER',
      );
      expect(
        service.normalizeGeofenceActionForQa(
          'GeofenceAction.enter',
        ),
        'ENTER',
      );
      expect(
        service.normalizeGeofenceActionForQa(
          'geofence_action_enter',
        ),
        'ENTER',
      );
    });

    test('accepts Android numeric transition values', () {
      expect(
        service.normalizeGeofenceActionForQa(1),
        'ENTER',
      );
      expect(
        service.normalizeGeofenceActionForQa('1'),
        'ENTER',
      );
      expect(
        service.normalizeGeofenceActionForQa(2),
        'EXIT',
      );
      expect(
        service.normalizeGeofenceActionForQa('2'),
        'EXIT',
      );
      expect(
        service.normalizeGeofenceActionForQa(4),
        'DWELL',
      );
      expect(
        service.normalizeGeofenceActionForQa('4'),
        'DWELL',
      );
    });

    test('classifies exit and dwell enum values', () {
      expect(
        service.normalizeGeofenceActionForQa(
          'GeofenceEventAction.exit',
        ),
        'EXIT',
      );
      expect(
        service.normalizeGeofenceActionForQa(
          'Action.dwell',
        ),
        'DWELL',
      );
    });

    test('reads action and identifier from nested payload', () {
      final event = <String, dynamic>{
        'event_payload': <String, dynamic>{
          'geofence': <String, dynamic>{
            'identifier': 'store-123',
            'action': 'GeofenceAction.enter',
          },
        },
      };

      expect(
        service.readGeofenceIdentifierForQa(event),
        'store-123',
      );
      expect(
        service.readGeofenceActionForQa(event),
        'ENTER',
      );
    });

    test('reads numeric transition from deeper payload', () {
      final event = <String, dynamic>{
        'payload': <String, dynamic>{
          'data': <String, dynamic>{
            'geofence_id': 'store-456',
            'transition': 1,
          },
        },
      };

      expect(
        service.readGeofenceIdentifierForQa(event),
        'store-456',
      );
      expect(
        service.readGeofenceActionForQa(event),
        'ENTER',
      );
    });

    test('does not invent entry for unknown data', () {
      expect(
        service.normalizeGeofenceActionForQa(null),
        isNull,
      );
      expect(
        service.normalizeGeofenceActionForQa(
          'something_else',
        ),
        isNull,
      );
    });
  });
  group('geofence definition preservation', () {
    const place = RiskyPlace(
      id: 'bakery',
      label: 'Bakery',
      note: '',
      isTopRisk: true,
      radiusMeters: 300,
      locationAlertsEnabled: true,
      latitude: 35.123456,
      longitude: -80.654321,
    );

    test('unchanged fence is preserved', () {
      const existing = tl.Geofence(
        identifier: 'bakery',
        latitude: 35.123456,
        longitude: -80.654321,
        radius: 300,
        notifyOnEntry: true,
        notifyOnExit: true,
      );

      expect(
        service.sameGeofenceDefinitionForQa(existing, place),
        isTrue,
      );
    });

    test('changed or entry-only fence must be upserted', () {
      const changedRadius = tl.Geofence(
        identifier: 'bakery',
        latitude: 35.123456,
        longitude: -80.654321,
        radius: 250,
        notifyOnEntry: true,
        notifyOnExit: true,
      );

      const missingExit = tl.Geofence(
        identifier: 'bakery',
        latitude: 35.123456,
        longitude: -80.654321,
        radius: 300,
        notifyOnEntry: true,
        notifyOnExit: false,
      );

      expect(
        service.sameGeofenceDefinitionForQa(changedRadius, place),
        isFalse,
      );
      expect(
        service.sameGeofenceDefinitionForQa(missingExit, place),
        isFalse,
      );
    });
  });

}
