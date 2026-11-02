import 'package:url_launcher/url_launcher.dart';

class SupportLinkService {
  static const String gamblingDisplayNumber = '1-800-MY-RESET';
  static const String gamblingDialDigits = '18006973738';
  static const String crisis988Display = '988';
  static const String emergency911Display = '911';

  static final Uri gamblingCallUri = Uri(
    scheme: 'tel',
    path: gamblingDialDigits,
  );

  static final Uri gamblingTextUri = Uri(
    scheme: 'sms',
    path: gamblingDialDigits,
  );

  static final Uri crisis988CallUri = Uri(
    scheme: 'tel',
    path: crisis988Display,
  );

  static final Uri crisis988TextUri = Uri(
    scheme: 'sms',
    path: crisis988Display,
  );

  static final Uri emergency911CallUri = Uri(
    scheme: 'tel',
    path: emergency911Display,
  );

  static final Uri chatUri = Uri.parse(
    'https://www.ncpgambling.org/chat/',
  );

  static final Uri helpHomeUri = Uri.parse(
    'https://www.ncpgambling.org/help-treatment/',
  );

  static final Uri helpByStateUri = Uri.parse(
    'https://www.ncpgambling.org/help-treatment/help-by-state/',
  );

  static Future<bool> launchCall() async {
    return launchUrl(gamblingCallUri);
  }

  static Future<bool> launchText() async {
    return launchUrl(gamblingTextUri);
  }

  static Future<bool> launchChat() async {
    return launchUrl(chatUri);
  }

  static Future<bool> launchHelpHome() async {
    return launchUrl(helpHomeUri);
  }

  static Future<bool> launchHelpByState() async {
    return launchUrl(helpByStateUri);
  }

  static Future<bool> launch988Call() async {
    return launchUrl(crisis988CallUri);
  }

  static Future<bool> launch988Text() async {
    return launchUrl(crisis988TextUri);
  }

  static Future<bool> launch911Call() async {
    return launchUrl(emergency911CallUri);
  }
}
