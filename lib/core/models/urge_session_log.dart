class UrgeSessionLog {
  final DateTime startedAt;
  final DateTime completedAt;
  final String selectedScriptId;
  final bool openedFullUrgeScript;
  final bool usedCopingStrategies;
  final bool usedNearMissEducation;
  final bool usedAccountability;

  const UrgeSessionLog({
    required this.startedAt,
    required this.completedAt,
    required this.selectedScriptId,
    required this.openedFullUrgeScript,
    required this.usedCopingStrategies,
    required this.usedNearMissEducation,
    required this.usedAccountability,
  });

  Map<String, dynamic> toJson() {
    return {
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'selectedScriptId': selectedScriptId,
      'openedFullUrgeScript': openedFullUrgeScript,
      'usedCopingStrategies': usedCopingStrategies,
      'usedNearMissEducation': usedNearMissEducation,
      'usedAccountability': usedAccountability,
    };
  }

  factory UrgeSessionLog.fromJson(Map<String, dynamic> json) {
    final startedAtRaw = json['startedAt']?.toString();
    final completedAtRaw = json['completedAt']?.toString();

    final parsedStartedAt =
        startedAtRaw == null ? null : DateTime.tryParse(startedAtRaw);
    final parsedCompletedAt =
        completedAtRaw == null ? null : DateTime.tryParse(completedAtRaw);

    final fallbackCompletedAt = parsedCompletedAt ?? DateTime.now();

    return UrgeSessionLog(
      startedAt: parsedStartedAt ?? fallbackCompletedAt,
      completedAt: fallbackCompletedAt,
      selectedScriptId:
          json['selectedScriptId']?.toString() ?? 'default',
      openedFullUrgeScript:
          json['openedFullUrgeScript'] as bool? ?? false,
      usedCopingStrategies:
          json['usedCopingStrategies'] as bool? ?? false,
      usedNearMissEducation:
          json['usedNearMissEducation'] as bool? ?? false,
      usedAccountability:
          json['usedAccountability'] as bool? ?? false,
    );
  }
}
