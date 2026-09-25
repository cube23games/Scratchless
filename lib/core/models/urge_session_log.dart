enum UrgeSessionOutcome {
  resolvedWithoutPurchase,
  stillDeciding,
  purchaseOccurred,
  unknownLegacy,
}

class UrgeSessionLog {
  final DateTime startedAt;
  final DateTime completedAt;
  final String selectedScriptId;
  final bool openedFullUrgeScript;
  final bool usedCopingStrategies;
  final bool usedNearMissEducation;
  final bool usedAccountability;
  final UrgeSessionOutcome outcome;

  const UrgeSessionLog({
    required this.startedAt,
    required this.completedAt,
    required this.selectedScriptId,
    required this.openedFullUrgeScript,
    required this.usedCopingStrategies,
    required this.usedNearMissEducation,
    required this.usedAccountability,
    required this.outcome,
  });

  bool get countsAsUrgeWin =>
      outcome == UrgeSessionOutcome.resolvedWithoutPurchase;

  bool get countsTowardCashKept => countsAsUrgeWin;

  String get _outcomeStorageValue {
    switch (outcome) {
      case UrgeSessionOutcome.resolvedWithoutPurchase:
        return 'resolved_without_purchase';
      case UrgeSessionOutcome.stillDeciding:
        return 'still_deciding';
      case UrgeSessionOutcome.purchaseOccurred:
        return 'purchase_occurred';
      case UrgeSessionOutcome.unknownLegacy:
        return 'unknown_legacy';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'selectedScriptId': selectedScriptId,
      'openedFullUrgeScript': openedFullUrgeScript,
      'usedCopingStrategies': usedCopingStrategies,
      'usedNearMissEducation': usedNearMissEducation,
      'usedAccountability': usedAccountability,
      'outcome': _outcomeStorageValue,
    };
  }

  factory UrgeSessionLog.fromJson(Map<String, dynamic> json) {
    final startedAtRaw = json['startedAt']?.toString();
    final completedAtRaw = json['completedAt']?.toString();
    final parsedStartedAt = startedAtRaw == null ? null : DateTime.tryParse(startedAtRaw);
    final parsedCompletedAt = completedAtRaw == null ? null : DateTime.tryParse(completedAtRaw);
    final fallbackCompletedAt = parsedCompletedAt ?? DateTime.now();
    final selectedScriptId = json['selectedScriptId']?.toString() ?? 'default';

    return UrgeSessionLog(
      startedAt: parsedStartedAt ?? fallbackCompletedAt,
      completedAt: fallbackCompletedAt,
      selectedScriptId: selectedScriptId,
      openedFullUrgeScript: json['openedFullUrgeScript'] as bool? ?? false,
      usedCopingStrategies: json['usedCopingStrategies'] as bool? ?? false,
      usedNearMissEducation: json['usedNearMissEducation'] as bool? ?? false,
      usedAccountability: json['usedAccountability'] as bool? ?? false,
      outcome: _parseOutcome(json['outcome']?.toString(), selectedScriptId: selectedScriptId),
    );
  }

  static UrgeSessionOutcome _parseOutcome(String? raw, {required String selectedScriptId}) {
    switch (raw) {
      case 'resolved_without_purchase':
        return UrgeSessionOutcome.resolvedWithoutPurchase;
      case 'still_deciding':
        return UrgeSessionOutcome.stillDeciding;
      case 'purchase_occurred':
        return UrgeSessionOutcome.purchaseOccurred;
      case 'unknown_legacy':
        return UrgeSessionOutcome.unknownLegacy;
    }

    if (selectedScriptId == 'live_alert_rescue_deciding') {
      return UrgeSessionOutcome.stillDeciding;
    }

    const knownLegacyWins = <String>{
      'pre_store_mode',
      'live_alert_rescue_paused',
      'after_paycheck',
      'saw_display',
      'won_recently',
      'passing_store',
      'only_one',
      'already_in_store',
    };

    if (knownLegacyWins.contains(selectedScriptId)) {
      return UrgeSessionOutcome.resolvedWithoutPurchase;
    }

    return UrgeSessionOutcome.unknownLegacy;
  }
}
