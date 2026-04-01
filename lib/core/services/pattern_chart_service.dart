import '../models/purchase_log.dart';
import '../models/urge_session_log.dart';

class PatternBarPoint {
  final String label;
  final double value;
  final String topLabel;

  const PatternBarPoint({
    required this.label,
    required this.value,
    required this.topLabel,
  });
}

class DualPatternBarPoint {
  final String label;
  final double leftValue;
  final double rightValue;
  final String topLabel;

  const DualPatternBarPoint({
    required this.label,
    required this.leftValue,
    required this.rightValue,
    required this.topLabel,
  });
}

class WarningSignalPoint {
  final String label;
  final double score;
  final String status;
  final String detail;

  const WarningSignalPoint({
    required this.label,
    required this.score,
    required this.status,
    required this.detail,
  });
}

class WarningRadarReport {
  final List<WarningSignalPoint> points;
  final String summary;

  const WarningRadarReport({
    required this.points,
    required this.summary,
  });
}

class PatternChartService {
  static List<PatternBarPoint> timeOfDayPoints(
    List<PurchaseLog> logs,
  ) {
    final counts = <String, int>{
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
      'Late': 0,
    };

    for (final log in logs) {
      final hour = log.createdAt.hour;
      if (hour >= 5 && hour <= 11) {
        counts['Morning'] = counts['Morning']! + 1;
      } else if (hour >= 12 && hour <= 16) {
        counts['Afternoon'] = counts['Afternoon']! + 1;
      } else if (hour >= 17 && hour <= 21) {
        counts['Evening'] = counts['Evening']! + 1;
      } else {
        counts['Late'] = counts['Late']! + 1;
      }
    }

    return [
      _point('Morning', counts['Morning']!),
      _point('Afternoon', counts['Afternoon']!),
      _point('Evening', counts['Evening']!),
      _point('Late', counts['Late']!),
    ];
  }

  static List<PatternBarPoint> dayOfWeekPoints(
    List<PurchaseLog> logs,
  ) {
    final counts = List<int>.filled(7, 0);

    for (final log in logs) {
      counts[log.createdAt.weekday - 1] += 1;
    }

    return [
      _point('Mon', counts[0]),
      _point('Tue', counts[1]),
      _point('Wed', counts[2]),
      _point('Thu', counts[3]),
      _point('Fri', counts[4]),
      _point('Sat', counts[5]),
      _point('Sun', counts[6]),
    ];
  }

  static List<DualPatternBarPoint> urgeWinsVsPurchasePoints({
    required List<PurchaseLog> purchaseLogs,
    required List<UrgeSessionLog> urgeSessions,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    return List<DualPatternBarPoint>.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));

      final purchaseCount = purchaseLogs.where((log) {
        final logDay = _dateOnly(log.createdAt);
        return _sameDay(logDay, day);
      }).length;

      final urgeWinCount = urgeSessions.where((session) {
        final sessionDay = _dateOnly(session.completedAt);
        return _sameDay(sessionDay, day);
      }).length;

      return DualPatternBarPoint(
        label: _weekdayShort(day.weekday),
        leftValue: purchaseCount.toDouble(),
        rightValue: urgeWinCount.toDouble(),
        topLabel: 'P$purchaseCount / U$urgeWinCount',
      );
    });
  }

  static List<DualPatternBarPoint> slipRecoveryPoints({
    required List<PurchaseLog> purchaseLogs,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    return List<DualPatternBarPoint>.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final previousDay = day.subtract(const Duration(days: 1));

      final purchaseCount = purchaseLogs.where((log) {
        final logDay = _dateOnly(log.createdAt);
        return _sameDay(logDay, day);
      }).length;

      final previousPurchaseCount = purchaseLogs.where((log) {
        final logDay = _dateOnly(log.createdAt);
        return _sameDay(logDay, previousDay);
      }).length;

      final slipDay = purchaseCount > 0 ? 1.0 : 0.0;
      final recoveryDay =
          previousPurchaseCount > 0 && purchaseCount == 0 ? 1.0 : 0.0;

      return DualPatternBarPoint(
        label: _weekdayShort(day.weekday),
        leftValue: slipDay,
        rightValue: recoveryDay,
        topLabel: purchaseCount > 1
            ? 'Repeat'
            : purchaseCount == 1
                ? 'Slip'
                : recoveryDay > 0
                    ? 'Back'
                    : '',
      );
    });
  }

  static List<PatternBarPoint> cycleTriggerPoints(
    List<PurchaseLog> purchaseLogs,
  ) {
    final counts = <String, int>{};

    for (final log in purchaseLogs) {
      for (final rawTag in log.tags) {
        final tag = rawTag.trim();
        if (tag.isEmpty) {
          continue;
        }
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) {
      return const <PatternBarPoint>[];
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final diff = b.value.compareTo(a.value);
        if (diff != 0) {
          return diff;
        }
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return sorted.take(4).map((entry) {
      return PatternBarPoint(
        label: _compactPhrase(entry.key),
        value: entry.value.toDouble(),
        topLabel: '${entry.value}',
      );
    }).toList();
  }

  static List<PatternBarPoint> cycleUrgeContextPoints(
    List<UrgeSessionLog> urgeSessions,
  ) {
    final counts = <String, int>{};

    for (final session in urgeSessions) {
      final key = session.selectedScriptId.trim();
      if (key.isEmpty) {
        continue;
      }
      counts[key] = (counts[key] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const <PatternBarPoint>[];
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final diff = b.value.compareTo(a.value);
        if (diff != 0) {
          return diff;
        }
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return sorted.take(4).map((entry) {
      return PatternBarPoint(
        label: _scriptLabel(entry.key),
        value: entry.value.toDouble(),
        topLabel: '${entry.value}',
      );
    }).toList();
  }

  static List<PatternBarPoint> cycleOutcomePoints({
    required List<PurchaseLog> purchaseLogs,
    required List<UrgeSessionLog> urgeSessions,
  }) {
    final slipCount = purchaseLogs.length;
    final urgeWinCount = urgeSessions.length;
    final copingCount = urgeSessions
        .where((session) => session.usedCopingStrategies)
        .length;
    final supportCount = urgeSessions
        .where((session) => session.usedAccountability)
        .length;

    return [
      PatternBarPoint(
        label: 'Slips',
        value: slipCount.toDouble(),
        topLabel: slipCount > 0 ? '$slipCount' : '',
      ),
      PatternBarPoint(
        label: 'Wins',
        value: urgeWinCount.toDouble(),
        topLabel: urgeWinCount > 0 ? '$urgeWinCount' : '',
      ),
      PatternBarPoint(
        label: 'Coping',
        value: copingCount.toDouble(),
        topLabel: copingCount > 0 ? '$copingCount' : '',
      ),
      PatternBarPoint(
        label: 'Support',
        value: supportCount.toDouble(),
        topLabel: supportCount > 0 ? '$supportCount' : '',
      ),
    ];
  }

  static WarningRadarReport buildWarningRadar({
    required List<PurchaseLog> purchaseLogs,
    required List<UrgeSessionLog> urgeSessions,
    required bool hasRiskyTimePattern,
    required String riskyWindowLabel,
  }) {
    final timeSignal = WarningSignalPoint(
      label: 'Time pressure',
      score: hasRiskyTimePattern ? 0.85 : (purchaseLogs.length >= 3 ? 0.35 : 0.15),
      status: hasRiskyTimePattern ? 'Pattern found' : 'Still forming',
      detail: hasRiskyTimePattern
          ? 'Your logs lean toward $riskyWindowLabel.'
          : 'No strong harder window has formed yet.',
    );

    final tagCounts = <String, int>{};
    for (final log in purchaseLogs) {
      for (final rawTag in log.tags) {
        final tag = rawTag.trim();
        if (tag.isEmpty) {
          continue;
        }
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    WarningSignalPoint triggerSignal;
    String topTriggerLabel = 'mixed pressure';

    if (tagCounts.isEmpty) {
      triggerSignal = const WarningSignalPoint(
        label: 'Trigger concentration',
        score: 0.15,
        status: 'Need more tags',
        detail: 'Tag purchases to make trigger pressure clearer.',
      );
    } else {
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sortedTags.first;
      final total = tagCounts.values.fold<int>(0, (sum, value) => sum + value);
      final concentration = total <= 0 ? 0.0 : top.value / total;
      topTriggerLabel = _compactPhrase(top.key).toLowerCase();

      triggerSignal = WarningSignalPoint(
        label: 'Trigger concentration',
        score: concentration.clamp(0.15, 1.0),
        status: concentration >= 0.55
            ? 'One trigger dominates'
            : concentration >= 0.35
                ? 'Some clustering'
                : 'Mixed triggers',
        detail: 'Top trigger: ${_compactPhrase(top.key)}.',
      );
    }

    final today = _dateOnly(DateTime.now());
    final startDay = today.subtract(const Duration(days: 13));
    final dailyPurchaseCounts = <DateTime, int>{};

    for (final log in purchaseLogs) {
      final day = _dateOnly(log.createdAt);
      if (!_isBefore(day, startDay) && !_isAfter(day, today)) {
        dailyPurchaseCounts[day] = (dailyPurchaseCounts[day] ?? 0) + 1;
      }
    }

    final slipDays = dailyPurchaseCounts.values.where((count) => count >= 1).length;
    final repeatSlipDays = dailyPurchaseCounts.values.where((count) => count >= 2).length;

    final slipScore = repeatSlipDays > 0
        ? (repeatSlipDays / 4).clamp(0.0, 1.0)
        : (slipDays > 0 ? 0.35 : 0.10);

    final slipSignal = WarningSignalPoint(
      label: 'Slip pressure',
      score: slipScore,
      status: repeatSlipDays > 0
          ? 'Repeat-slip pressure'
          : slipDays > 0
              ? 'Some slip pressure'
              : 'Quiet right now',
      detail: repeatSlipDays > 0
          ? '$repeatSlipDays repeat-slip day${repeatSlipDays == 1 ? '' : 's'} in the last 14 days.'
          : slipDays > 0
              ? '$slipDays slip day${slipDays == 1 ? '' : 's'} in the last 14 days.'
              : 'No recent slip days logged.',
    );

    final urgeWinDays = urgeSessions
        .map((session) => _dateOnly(session.completedAt))
        .where((day) => !_isBefore(day, startDay) && !_isAfter(day, today))
        .toSet()
        .length;

    int recoveryDays = 0;
    for (final day in dailyPurchaseCounts.keys) {
      final nextDay = day.add(const Duration(days: 1));
      final nextCount = dailyPurchaseCounts[nextDay] ?? 0;
      if (nextCount == 0) {
        recoveryDays += 1;
      }
    }

    final recoveryScore = slipDays == 0
        ? (urgeWinDays > 0 ? 0.75 : 0.30)
        : ((recoveryDays + urgeWinDays) / (slipDays + urgeWinDays + 1))
            .clamp(0.0, 1.0);

    final recoverySignal = WarningSignalPoint(
      label: 'Recovery strength',
      score: recoveryScore,
      status: recoveryScore >= 0.66
          ? 'Comebacks visible'
          : recoveryScore >= 0.40
              ? 'Still building'
              : 'Needs reinforcement',
      detail: recoveryDays > 0
          ? '$recoveryDays comeback day${recoveryDays == 1 ? '' : 's'} after a slip recently.'
          : urgeWinDays > 0
              ? '$urgeWinDays urge-win day${urgeWinDays == 1 ? '' : 's'} logged recently.'
              : 'Recovery momentum is still building.',
    );

    final summary =
        'Right now the cycle leans toward ${hasRiskyTimePattern ? riskyWindowLabel.toLowerCase() : 'less consistent timing'}, '
        '$topTriggerLabel, ${slipSignal.status.toLowerCase()}, and recovery is ${recoverySignal.status.toLowerCase()}.';

    return WarningRadarReport(
      points: [
        timeSignal,
        triggerSignal,
        slipSignal,
        recoverySignal,
      ],
      summary: summary,
    );
  }

  static PatternBarPoint _point(String label, int count) {
    return PatternBarPoint(
      label: label,
      value: count.toDouble(),
      topLabel: count > 0 ? '$count' : '',
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isBefore(DateTime a, DateTime b) {
    return a.year < b.year ||
        (a.year == b.year && a.month < b.month) ||
        (a.year == b.year && a.month == b.month && a.day < b.day);
  }

  static bool _isAfter(DateTime a, DateTime b) {
    return a.year > b.year ||
        (a.year == b.year && a.month > b.month) ||
        (a.year == b.year && a.month == b.month && a.day > b.day);
  }

  static String _compactPhrase(String raw) {
    final words = raw
        .split(RegExp(r'[\s/_-]+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'Other';
    }

    final first = words.first;
    final normalized = _titleCase(first);
    return normalized.length <= 8
        ? normalized
        : normalized.substring(0, 8);
  }

  static String _scriptLabel(String raw) {
    final words = raw
        .split(RegExp(r'[\s/_-]+'))
        .where((word) => word.trim().isNotEmpty)
        .where(
          (word) =>
              word.toLowerCase() != 'script' &&
              word.toLowerCase() != 'urge' &&
              word.toLowerCase() != 'mode',
        )
        .toList();

    if (words.isEmpty) {
      return 'Other';
    }

    final normalized = _titleCase(words.first);
    return normalized.length <= 8
        ? normalized
        : normalized.substring(0, 8);
  }

  static String _titleCase(String raw) {
    if (raw.isEmpty) {
      return raw;
    }

    final lower = raw.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
      default:
        return '?';
    }
  }
}
