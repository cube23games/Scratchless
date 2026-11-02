import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scratchless/core/services/support_link_service.dart';
import 'package:scratchless/features/help/help_screen.dart';

void main() {
  test('SL-81B support destinations use current NCPG and crisis endpoints', () {
    expect(
      SupportLinkService.gamblingCallUri.toString(),
      'tel:18006973738',
    );
    expect(
      SupportLinkService.gamblingTextUri.toString(),
      'sms:18006973738',
    );
    expect(
      SupportLinkService.crisis988CallUri.toString(),
      'tel:988',
    );
    expect(
      SupportLinkService.crisis988TextUri.toString(),
      'sms:988',
    );
    expect(
      SupportLinkService.emergency911CallUri.toString(),
      'tel:911',
    );
    expect(
      SupportLinkService.chatUri.toString(),
      'https://www.ncpgambling.org/chat/',
    );
  });

  testWidgets(
    'Help screen clearly separates gambling support from crisis support',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.text('Gambling support'), findsOneWidget);
      expect(find.text('Call 1-800-MY-RESET'), findsOneWidget);
      expect(find.text('Text 1-800-MY-RESET'), findsOneWidget);
      expect(find.text('Text 800GAM'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Crisis or immediate danger'),
        300,
      );
      await tester.pumpAndSettle();

      expect(find.text('Crisis or immediate danger'), findsOneWidget);
      expect(find.text('Call 988'), findsOneWidget);
      expect(find.text('Text 988'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Call 911'),
        300,
      );
      await tester.pumpAndSettle();

      expect(find.text('Call 911'), findsOneWidget);
    },
  );
}
