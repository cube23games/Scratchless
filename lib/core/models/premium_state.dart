class PremiumState {
  final bool isPremium;
  final DateTime? trialStartedAt;
  final String livePlaceAlertAccess;

  const PremiumState({
    required this.isPremium,
    required this.trialStartedAt,
    required this.livePlaceAlertAccess,
  });

  factory PremiumState.free() {
    return const PremiumState(
      isPremium: false,
      trialStartedAt: null,
      livePlaceAlertAccess: 'off',
    );
  }

  PremiumState copyWith({
    bool? isPremium,
    DateTime? trialStartedAt,
    String? livePlaceAlertAccess,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      livePlaceAlertAccess:
          livePlaceAlertAccess ?? this.livePlaceAlertAccess,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPremium': isPremium,
      'trialStartedAt': trialStartedAt?.toIso8601String(),
      'livePlaceAlertAccess': livePlaceAlertAccess,
    };
  }

  factory PremiumState.fromJson(Map<String, dynamic> json) {
    final rawTrialStartedAt = json['trialStartedAt']?.toString();
    final parsedTrialStartedAt = rawTrialStartedAt == null
        ? null
        : DateTime.tryParse(rawTrialStartedAt);

    return PremiumState(
      isPremium: json['isPremium'] as bool? ?? false,
      trialStartedAt: parsedTrialStartedAt,
      livePlaceAlertAccess:
          json['livePlaceAlertAccess']?.toString() ?? 'off',
    );
  }
}
