import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scratchless/core/models/purchase_log.dart';
import 'package:scratchless/core/models/urge_session_log.dart';
import 'package:scratchless/core/models/premium_state.dart';
import 'package:scratchless/core/services/premium_prompt_service.dart';
import 'package:scratchless/core/services/weekly_summary_service.dart';
import 'package:scratchless/core/storage/app_storage.dart';

UrgeSessionLog _session({
  required DateTime at,
  required UrgeSessionOutcome outcome,
  String scriptId = 'saw_display',
}) {
  return UrgeSessionLog(
    startedAt: at,
    completedAt: at,
    selectedScriptId: scriptId,
    openedFullUrgeScript: false,
    usedCopingStrategies: false,
    usedNearMissEducation: false,
    usedAccountability: false,
    outcome: outcome,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explicit outcomes round-trip and only resolved counts as win', () {
    final now = DateTime(2026, 9, 19, 2);
    final resolved = _session(at: now, outcome: UrgeSessionOutcome.resolvedWithoutPurchase);
    final deciding = _session(at: now, outcome: UrgeSessionOutcome.stillDeciding, scriptId: 'live_alert_rescue_deciding');
    final purchase = _session(at: now, outcome: UrgeSessionOutcome.purchaseOccurred, scriptId: 'live_alert_rescue_purchase');
    final resolvedReloaded = UrgeSessionLog.fromJson(resolved.toJson());
    final decidingReloaded = UrgeSessionLog.fromJson(deciding.toJson());
    final purchaseReloaded = UrgeSessionLog.fromJson(purchase.toJson());
    expect(resolvedReloaded.countsAsUrgeWin, isTrue);
    expect(resolvedReloaded.countsTowardCashKept, isTrue);
    expect(decidingReloaded.countsAsUrgeWin, isFalse);
    expect(decidingReloaded.countsTowardCashKept, isFalse);
    expect(purchaseReloaded.outcome, UrgeSessionOutcome.purchaseOccurred);
    expect(purchaseReloaded.countsAsUrgeWin, isFalse);
    expect(purchaseReloaded.countsTowardCashKept, isFalse);
  });

  test('legacy live-alert deciding is migrated as not a win', () {
    final migrated = UrgeSessionLog.fromJson({
      'startedAt': '2026-09-19T02:00:00',
      'completedAt': '2026-09-19T02:00:00',
      'selectedScriptId': 'live_alert_rescue_deciding',
    });
    expect(migrated.outcome, UrgeSessionOutcome.stillDeciding);
    expect(migrated.countsAsUrgeWin, isFalse);
  });

  test('known legacy completion remains a win, unknown stays conservative', () {
    final known = UrgeSessionLog.fromJson({
      'startedAt': '2026-09-19T02:00:00',
      'completedAt': '2026-09-19T02:00:00',
      'selectedScriptId': 'pre_store_mode',
    });
    final unknown = UrgeSessionLog.fromJson({
      'startedAt': '2026-09-19T02:00:00',
      'completedAt': '2026-09-19T02:00:00',
      'selectedScriptId': 'mystery_old_flow',
    });
    expect(known.countsAsUrgeWin, isTrue);
    expect(unknown.outcome, UrgeSessionOutcome.unknownLegacy);
    expect(unknown.countsAsUrgeWin, isFalse);
  });

  test('weekly summary excludes still-deciding from wins and cash kept', () {
    final now = DateTime(2026, 9, 19, 12);
    final summary = WeeklySummaryService.build(
      purchaseLogs: const [],
      urgeSessions: [
        _session(at: now, outcome: UrgeSessionOutcome.resolvedWithoutPurchase),
        _session(at: now, outcome: UrgeSessionOutcome.stillDeciding, scriptId: 'live_alert_rescue_deciding'),
      ],
      averageSpend: 15,
      now: now,
    );
    expect(summary.urgeWinsThisWeek, 1);
    expect(summary.cashKeptThisWeek, 15);
  });

  test('purchase outcome records spend truth without creating an urge win', () {
    final now = DateTime(2026, 9, 19, 12);
    final summary = WeeklySummaryService.build(
      purchaseLogs: [
        PurchaseLog(
          id: 'purchase-1',
          createdAt: now,
          amount: 15,
          tags: const ['Saw a display'],
        ),
      ],
      urgeSessions: [
        _session(
          at: now,
          outcome: UrgeSessionOutcome.purchaseOccurred,
          scriptId: 'live_alert_rescue_purchase',
        ),
      ],
      averageSpend: 15,
      now: now,
    );
    expect(summary.purchasesThisWeek, 1);
    expect(summary.spentThisWeek, 15);
    expect(summary.urgeWinsThisWeek, 0);
    expect(summary.cashKeptThisWeek, 0);
  });

  test('first-win prompt uses win count rather than raw sessions', () {
    final canShow = PremiumPromptService.canShow(
      type: PremiumPromptType.firstUrgeWin,
      premiumState: PremiumState.free(),
      hasSeenSuccessPremiumPrompt: false,
      urgeWinsCount: 0,
    );
    expect(canShow, isTrue);
  });

  test('storage migration preserves aggregate-only wins once', () async {
    final successJson = {
      'startedAt': '2026-09-19T01:00:00',
      'completedAt': '2026-09-19T01:00:00',
      'selectedScriptId': 'pre_store_mode',
    };
    final decidingJson = {
      'startedAt': '2026-09-19T02:00:00',
      'completedAt': '2026-09-19T02:00:00',
      'selectedScriptId': 'live_alert_rescue_deciding',
    };

    SharedPreferences.setMockInitialValues({
      'urges_defeated': 3,
      'urge_sessions': [jsonEncode(successJson), jsonEncode(decidingJson)],
    });

    final first = await AppStorage.load();
    expect(first.legacyUrgeWinsBaseline, 1);
    expect(first.urgeSessions.where((s) => s.countsAsUrgeWin).length, 1);

    final second = await AppStorage.load();
    expect(second.legacyUrgeWinsBaseline, 1);
  });
}
