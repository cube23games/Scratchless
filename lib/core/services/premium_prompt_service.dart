import '../models/premium_state.dart';

enum PremiumPromptType {
  onboardingPaywall,
  firstUrgeWin,
  firstWeeklyReflection,
  firstStreakMilestone,
  advancedInsightsIntent,
  exportIntent,
}

class PremiumPromptService {
  static bool canShow({
    required PremiumPromptType type,
    required PremiumState premiumState,
    required bool hasSeenSuccessPremiumPrompt,
    required int urgeSessionsCount,
    bool isEmergencyFlow = false,
    bool isPurchaseMoment = false,
  }) {
    if (premiumState.isPremium) {
      return false;
    }

    if (_isBlockedContext(
      type: type,
      isEmergencyFlow: isEmergencyFlow,
      isPurchaseMoment: isPurchaseMoment,
    )) {
      return false;
    }

    switch (type) {
      case PremiumPromptType.firstUrgeWin:
        return !hasSeenSuccessPremiumPrompt && urgeSessionsCount == 0;
      case PremiumPromptType.onboardingPaywall:
      case PremiumPromptType.firstWeeklyReflection:
      case PremiumPromptType.firstStreakMilestone:
      case PremiumPromptType.advancedInsightsIntent:
      case PremiumPromptType.exportIntent:
        return true;
    }
  }

  static bool _isBlockedContext({
    required PremiumPromptType type,
    required bool isEmergencyFlow,
    required bool isPurchaseMoment,
  }) {
    switch (type) {
      case PremiumPromptType.firstUrgeWin:
        return isEmergencyFlow || isPurchaseMoment;
      case PremiumPromptType.onboardingPaywall:
      case PremiumPromptType.firstWeeklyReflection:
      case PremiumPromptType.firstStreakMilestone:
      case PremiumPromptType.advancedInsightsIntent:
      case PremiumPromptType.exportIntent:
        return false;
    }
  }
}
