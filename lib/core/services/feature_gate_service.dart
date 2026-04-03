import '../models/premium_state.dart';

class FeatureGateService {
  static bool advancedInsightsUnlocked(PremiumState state) {
    return state.isPremium;
  }

  static bool longHistoryUnlocked(PremiumState state) {
    return state.isPremium;
  }

  static bool reflectionReportsUnlocked(PremiumState state) {
    return state.isPremium;
  }

  static bool customReminderSchedulesUnlocked(PremiumState state) {
    return state.isPremium;
  }

  static bool exportProgressUnlocked(PremiumState state) {
    return state.isPremium;
  }

  static bool placeAlertsUnlocked(PremiumState state) {
    return state.isPremium;
  }

  static String premiumStatusLabel(PremiumState state) {
    return state.isPremium ? 'Premium active' : 'Free plan';
  }

  static String premiumCtaLabel(PremiumState state) {
    return state.isPremium ? 'Premium active' : 'Start 3-day free trial';
  }
}
