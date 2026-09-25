import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/models/accountability_partner.dart';
import 'package:scratchless/core/models/urge_session_log.dart';
import 'package:scratchless/features/live_alert/live_alert_rescue_screen.dart';
import 'package:scratchless/features/logging/purchase_log_sheet.dart';

void main() {
  testWidgets(
    'purchase outcome uses real purchase sheet and opens recovery escalation',
    (tester) async {
      double? savedAmount;
      UrgeSessionLog? savedSession;

      await tester.pumpWidget(
        MaterialApp(
          home: LiveAlertRescueScreen(
            placeLabel: 'Test shop',
            stopReasons: const [],
            accountabilityPartner: AccountabilityPartner.empty(),
            onLogUrge: (_) {},
            onLogPurchaseAfterRescue: ({
              required double amount,
              String? note,
              required List<String> tags,
              required UrgeSessionLog session,
            }) {
              savedAmount = amount;
              savedSession = session;
            },
            onOpenFullUrgeMode: () {},
          ),
        ),
      );

      final logUrgeButton = find.text('Log the urge');
      await tester.scrollUntilVisible(logUrgeButton, 300);
      await tester.ensureVisible(logUrgeButton);
      await tester.pumpAndSettle();
      await tester.tap(logUrgeButton);
      await tester.pumpAndSettle();

      expect(find.text('I bought tickets'), findsOneWidget);
      await tester.tap(find.text('I bought tickets'));
      await tester.pumpAndSettle();

      expect(find.text('Log a scratch-off purchase'), findsOneWidget);

      final saveEntryButton = find.descendant(
        of: find.byType(PurchaseLogSheet),
        matching: find.text('Save entry'),
      );
      await tester.scrollUntilVisible(saveEntryButton, 300);
      await tester.ensureVisible(saveEntryButton);
      await tester.pumpAndSettle();
      await tester.tap(saveEntryButton);
      await tester.pumpAndSettle();

      expect(savedAmount, 10);
      expect(savedSession, isNotNull);
      expect(savedSession!.outcome, UrgeSessionOutcome.purchaseOccurred);
      expect(savedSession!.countsAsUrgeWin, isFalse);
      expect(savedSession!.countsTowardCashKept, isFalse);
      expect(
        find.text('Purchase logged — stop the spiral here'),
        findsOneWidget,
      );
      expect(find.text('Purchase logged honestly'), findsOneWidget);

      final recoveryHeading = find.text('Need another layer?');
      await tester.scrollUntilVisible(recoveryHeading, 300);
      await tester.ensureVisible(recoveryHeading);
      await tester.pumpAndSettle();

      expect(recoveryHeading, findsOneWidget);
      expect(find.text('Open full urge tools'), findsOneWidget);
      expect(find.text('Open live support options'), findsOneWidget);
    },
  );
}
