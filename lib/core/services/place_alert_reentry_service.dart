import 'package:shared_preferences/shared_preferences.dart';

enum PlaceAlertReentryDecision {
  none,
  waitingForStableOutside,
  rearmed,
}

class PlaceAlertReentryResult {
  final PlaceAlertReentryDecision decision;
  final Duration outsideFor;

  const PlaceAlertReentryResult({
    required this.decision,
    required this.outsideFor,
  });
}

class PlaceAlertReentryService {
  PlaceAlertReentryService._();

  static final PlaceAlertReentryService instance =
      PlaceAlertReentryService._();

  static const String _prefix = 'place_alert_last_exit_';

  Future<DateTime?> lastExitedAt(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$placeId');

    if (raw == null) {
      return null;
    }

    return DateTime.tryParse(raw);
  }

  Future<void> markExited(
    String placeId, {
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      '$_prefix$placeId',
      (now ?? DateTime.now()).toIso8601String(),
    );
  }

  Future<PlaceAlertReentryResult> evaluateEntry({
    required String placeId,
    required Duration minimumOutside,
    DateTime? now,
  }) async {
    final exitedAt = await lastExitedAt(placeId);

    if (exitedAt == null) {
      return const PlaceAlertReentryResult(
        decision: PlaceAlertReentryDecision.none,
        outsideFor: Duration.zero,
      );
    }

    final current = now ?? DateTime.now();
    final outsideFor = current.difference(exitedAt);

    if (outsideFor < minimumOutside) {
      return PlaceAlertReentryResult(
        decision:
            PlaceAlertReentryDecision.waitingForStableOutside,
        outsideFor: outsideFor,
      );
    }

    await clear(placeId);

    return PlaceAlertReentryResult(
      decision: PlaceAlertReentryDecision.rearmed,
      outsideFor: outsideFor,
    );
  }

  Future<void> clear(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$placeId');
  }
}
