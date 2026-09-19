import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/models/accountability_partner.dart';
import 'package:scratchless/features/live_alert/live_alert_rescue_screen.dart';

void main() {
  testWidgets(
    'deeper help handoff appears after a rescue tool and opens help',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LiveAlertRescueScreen(
            placeLabel: 'Test shop',
            stopReasons: const [],
            accountabilityPartner: AccountabilityPartner.empty(),
            onLogUrge: (_) {},
          ),
        ),
      );

      expect(find.text('Need another layer?'), findsNothing);

      await tester.ensureVisible(find.text('Read my reasons'));
      await tester.tap(find.text('Read my reasons'));
      await tester.pumpAndSettle();

      expect(find.text('Read your reasons'), findsOneWidget);

      Navigator.of(
        tester.element(find.text('Read your reasons')),
      ).pop();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Need another layer?'),
        400,
      );
      await tester.pump();

      expect(find.text('Need another layer?'), findsOneWidget);
      expect(find.text('Open live support options'), findsOneWidget);

      await tester.tap(find.text('Open live support options'));
      await tester.pumpAndSettle();

      expect(find.text('Get help now'), findsOneWidget);
      expect(find.text('Call 1-800-MY-RESET'), findsOneWidget);
      expect(find.text('Text 800GAM'), findsOneWidget);
      expect(find.text('Open live chat'), findsOneWidget);
    },
  );
}
