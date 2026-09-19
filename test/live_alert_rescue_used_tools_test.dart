import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scratchless/core/models/accountability_partner.dart';
import 'package:scratchless/features/live_alert/live_alert_rescue_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget buildScreen() {
    return MaterialApp(
      home: LiveAlertRescueScreen(
        placeLabel: 'Test shop',
        stopReasons: const [],
        accountabilityPartner: AccountabilityPartner.empty(),
        onLogUrge: (_) {},
      ),
    );
  }

  testWidgets(
    'used-tools section appears and updates as rescue tools are used',
    (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text("You've already used"), findsNothing);

      await tester.tap(find.text('Give me 10 minutes'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text("You've already used"),
        400,
      );
      await tester.pump();

      expect(find.text("You've already used"), findsOneWidget);
      expect(find.text('10-minute pause started'), findsOneWidget);

      await tester.ensureVisible(find.text('Read my reasons'));
      await tester.tap(find.text('Read my reasons'));
      await tester.pumpAndSettle();

      expect(find.text('Read your reasons'), findsOneWidget);

      Navigator.of(
        tester.element(find.text('Read your reasons')),
      ).pop();
      await tester.pumpAndSettle();

      expect(find.text('Reasons reviewed'), findsOneWidget);

      await tester.ensureVisible(find.text('Message support'));
      await tester.tap(find.text('Message support'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy support message'));
      await tester.pumpAndSettle();

      expect(find.text('Support contacted'), findsOneWidget);

      // Let the real 10-minute rescue timer finish inside fake test time.
      await tester.pump(const Duration(minutes: 11));
      await tester.pump();
    },
  );
}
