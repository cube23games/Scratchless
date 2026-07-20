import 'package:shared_preferences/shared_preferences.dart';

class PlaceAlertCooldownService {
  PlaceAlertCooldownService._();

  static final PlaceAlertCooldownService instance =
      PlaceAlertCooldownService._();

  static const String _prefix = 'place_alert_last_fired_';

  Future<DateTime?> lastFiredAt(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$placeId');
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<bool> shouldSuppress({
    required String placeId,
    required int cooldownMinutes,
    DateTime? now,
  }) async {
    final last = await lastFiredAt(placeId);
    if (last == null) {
      return false;
    }

    final current = now ?? DateTime.now();
    final diff = current.difference(last).inMinutes;
    return diff < cooldownMinutes;
  }

  Future<void> markFired(String placeId, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$placeId',
      (now ?? DateTime.now()).toIso8601String(),
    );
  }

  Future<void> clear(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$placeId');
  }
}
