class StartingPlan {
  static const List<String> problemFitOptions = <String>[
    'I buy scratch-offs more than I want to.',
    'I spend more than I plan on lottery tickets.',
    'I want help stopping the cycle before it starts.',
    'I’m trying to cut back, not quit completely.',
  ];

  static const List<String> triggerOptions = <String>[
    'Payday',
    'Gas station stops',
    'Store displays',
    'Stress',
    'Boredom',
    'Loneliness',
    'Chasing losses',
    'Habit / routine',
  ];

  static const List<String> rescueOptions = <String>[
    'A quick breathing reset',
    'A delay timer',
    'My reasons to stop',
    'Texting someone I trust',
    'A replacement activity',
  ];

  static const List<String> supportOptions = <String>[
    'Keep it private for now',
    'Add one trusted person later',
    'I want accountability help',
  ];

  final String? problemFit;
  final String goal;
  final int frequencyPerWeek;
  final double averageSpend;
  final List<String> triggers;
  final String? preferredRescue;
  final String? supportPreference;

  const StartingPlan({
    required this.problemFit,
    required this.goal,
    required this.frequencyPerWeek,
    required this.averageSpend,
    required this.triggers,
    required this.preferredRescue,
    required this.supportPreference,
  });

  factory StartingPlan.defaults() {
    return const StartingPlan(
      problemFit: null,
      goal: 'Spend less',
      frequencyPerWeek: 3,
      averageSpend: 10,
      triggers: <String>[],
      preferredRescue: null,
      supportPreference: null,
    );
  }

  factory StartingPlan.fromLegacy({
    required int frequencyPerWeek,
    required double averageSpend,
    required String goal,
  }) {
    return StartingPlan(
      problemFit: null,
      goal: goal.trim().isEmpty ? 'Spend less' : goal.trim(),
      frequencyPerWeek: frequencyPerWeek > 0 ? frequencyPerWeek : 3,
      averageSpend: averageSpend > 0 ? averageSpend : 10,
      triggers: const <String>[],
      preferredRescue: null,
      supportPreference: null,
    );
  }

  factory StartingPlan.fromJson(
    Map<String, dynamic> json, {
    StartingPlan? fallback,
  }) {
    final base = fallback ?? StartingPlan.defaults();

    String? optionalString(String key, String? fallbackValue) {
      final value = json[key];
      if (value is! String) {
        return fallbackValue;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final rawGoal = json['goal'];
    final goal = rawGoal is String && rawGoal.trim().isNotEmpty
        ? rawGoal.trim()
        : base.goal;

    final rawFrequency = json['frequencyPerWeek'];
    final parsedFrequency = rawFrequency is int
        ? rawFrequency
        : int.tryParse(rawFrequency?.toString() ?? '');

    final rawSpend = json['averageSpend'];
    final parsedSpend = rawSpend is num
        ? rawSpend.toDouble()
        : double.tryParse(rawSpend?.toString() ?? '');

    final rawTriggers = json['triggers'];
    final parsedTriggers = rawTriggers is List
        ? rawTriggers
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
        : base.triggers;

    return StartingPlan(
      problemFit: optionalString('problemFit', base.problemFit),
      goal: goal,
      frequencyPerWeek: parsedFrequency != null && parsedFrequency > 0
          ? parsedFrequency
          : base.frequencyPerWeek,
      averageSpend: parsedSpend != null && parsedSpend > 0
          ? parsedSpend
          : base.averageSpend,
      triggers: List<String>.unmodifiable(parsedTriggers),
      preferredRescue:
          optionalString('preferredRescue', base.preferredRescue),
      supportPreference:
          optionalString('supportPreference', base.supportPreference),
    );
  }

  double get estimatedWeeklySpend => frequencyPerWeek * averageSpend;

  double get estimatedMonthlySpend => estimatedWeeklySpend * 4.33;

  double get estimatedYearlySpend => estimatedMonthlySpend * 12;

  bool get prefersPrivateSupport =>
      supportPreference == 'Keep it private for now';

  String? get preferredUrgeScriptId {
    if (triggers.contains('Payday')) {
      return 'after_paycheck';
    }
    if (triggers.contains('Store displays')) {
      return 'saw_display';
    }
    if (triggers.contains('Gas station stops') ||
        triggers.contains('Habit / routine')) {
      return 'passing_store';
    }
    return null;
  }

  StartingPlan copyWith({
    String? problemFit,
    String? goal,
    int? frequencyPerWeek,
    double? averageSpend,
    List<String>? triggers,
    String? preferredRescue,
    String? supportPreference,
  }) {
    return StartingPlan(
      problemFit: problemFit ?? this.problemFit,
      goal: goal ?? this.goal,
      frequencyPerWeek: frequencyPerWeek ?? this.frequencyPerWeek,
      averageSpend: averageSpend ?? this.averageSpend,
      triggers: List<String>.unmodifiable(triggers ?? this.triggers),
      preferredRescue: preferredRescue ?? this.preferredRescue,
      supportPreference: supportPreference ?? this.supportPreference,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'problemFit': problemFit,
      'goal': goal,
      'frequencyPerWeek': frequencyPerWeek,
      'averageSpend': averageSpend,
      'triggers': triggers,
      'preferredRescue': preferredRescue,
      'supportPreference': supportPreference,
    };
  }
}
