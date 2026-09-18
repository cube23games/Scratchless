import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scratchless/core/services/place_alert_reentry_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = PlaceAlertReentryService.instance;
  final base = DateTime(2026, 9, 17, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues(
      <String, Object>{},
    );
  });

  test('entry without a prior exit is not a re-entry', () async {
    final result = await service.evaluateEntry(
      placeId: 'store',
      minimumOutside: const Duration(seconds: 90),
      now: base,
    );

    expect(result.decision, PlaceAlertReentryDecision.none);
  });

  test('quick return does not re-arm', () async {
    await service.markExited('store', now: base);

    final result = await service.evaluateEntry(
      placeId: 'store',
      minimumOutside: const Duration(seconds: 90),
      now: base.add(const Duration(seconds: 45)),
    );

    expect(
      result.decision,
      PlaceAlertReentryDecision.waitingForStableOutside,
    );

    expect(await service.lastExitedAt('store'), base);
  });

  test('stable outside period re-arms once', () async {
    await service.markExited('store', now: base);

    final first = await service.evaluateEntry(
      placeId: 'store',
      minimumOutside: const Duration(seconds: 90),
      now: base.add(const Duration(seconds: 91)),
    );

    expect(
      first.decision,
      PlaceAlertReentryDecision.rearmed,
    );

    final second = await service.evaluateEntry(
      placeId: 'store',
      minimumOutside: const Duration(seconds: 90),
      now: base.add(const Duration(seconds: 100)),
    );

    expect(
      second.decision,
      PlaceAlertReentryDecision.none,
    );
  });
}
