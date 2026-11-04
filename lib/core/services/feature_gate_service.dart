import '../config/app_build_config.dart';
import '../models/premium_state.dart';

class FeatureGateService {
  static bool advancedInsightsUnlocked(PremiumState state) => state.isPremium;
  static bool longHistoryUnlocked(PremiumState state) => state.isPremium;
  static bool reflectionReportsUnlocked(PremiumState state) => state.isPremium;
  static bool customReminderSchedulesUnlocked(PremiumState state) => state.isPremium;
  static bool exportProgressUnlocked(PremiumState state) => state.isPremium;
  static bool placeAlertsUnlocked(PremiumState state) => state.isPremium;

  static String premiumStatusLabel(PremiumState state) {
    return state.isPremium ? 'Premium active' : 'Free plan';
  }

  static String premiumCtaLabel(PremiumState state) {
    if (state.isPremium) return 'Premium active';
    return AppBuildConfig.localPremiumTrialEnabled
        ? 'Start 3-day free trial'
        : 'Premium coming soon';
  }
}
