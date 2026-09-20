import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/models/accountability_partner.dart';
import 'package:scratchless/features/live_alert/live_alert_rescue_screen.dart';

void main() {
  testWidgets(
    'full urge handoff requires deliberate rescue use and preserves live support',
    (tester) async {
      var openedFullUrgeMode = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LiveAlertRescueScreen(
            placeLabel: 'Test shop',
            autoStartTenMinutePause: true,
            stopReasons: const [],
            accountabilityPartner: AccountabilityPartner.empty(),
            onLogUrge: (_) {},
            onOpenFullUrgeMode: () {
              openedFullUrgeMode = true;
            },
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Open full urge tools'), findsNothing);

      final reasonsButton = find.text('Read my reasons');
      await tester.ensureVisible(reasonsButton);
      await tester.pumpAndSettle();
      await tester.tap(reasonsButton);
      await tester.pumpAndSettle();

      expect(find.text('Read your reasons'), findsOneWidget);

      Navigator.of(
        tester.element(find.text('Read your reasons')),
      ).pop();
      await tester.pumpAndSettle();

      final fullUrgeButton = find.text('Open full urge tools');
      await tester.ensureVisible(fullUrgeButton);
      await tester.pumpAndSettle();

      expect(fullUrgeButton, findsOneWidget);
      expect(find.text('Open live support options'), findsOneWidget);

      await tester.tap(fullUrgeButton);
      await tester.pump();

      expect(openedFullUrgeMode, isTrue);

      await tester.pump(const Duration(minutes: 11));
      await tester.pump();
    },
  );
}
