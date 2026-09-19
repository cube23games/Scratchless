import '../models/purchase_log.dart';
import '../models/urge_session_log.dart';

class DailySpendPoint {
  final DateTime day;
  final double amount;

  const DailySpendPoint({
    required this.day,
    required this.amount,
  });
}

class WeeklySummary {
  final double spentThisWeek;
  final double spentPreviousWeek;
  final int purchasesThisWeek;
  final int purchasesPreviousWeek;
  final int urgeWinsThisWeek;
  final int urgeWinsPreviousWeek;
  final double cashKeptThisWeek;
  final double cashKeptPreviousWeek;
  final String topTriggerThisWeek;
  final String comparisonMessage;
  final List<DailySpendPoint> spendPoints;

  const WeeklySummary({
    required this.spentThisWeek,
    required this.spentPreviousWeek,
    required this.purchasesThisWeek,
    required this.purchasesPreviousWeek,
    required this.urgeWinsThisWeek,
    required this.urgeWinsPreviousWeek,
    required this.cashKeptThisWeek,
    required this.cashKeptPreviousWeek,
    required this.topTriggerThisWeek,
    required this.comparisonMessage,
    required this.spendPoints,
  });
}

class WeeklySummaryService {
  static WeeklySummary build({
    required List<PurchaseLog> purchaseLogs,
    required List<UrgeSessionLog> urgeSessions,
    required double averageSpend,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    final currentStart = today.subtract(const Duration(days: 6));
    final currentEnd = today;

    final previousStart = today.subtract(const Duration(days: 13));
    final previousEnd = today.subtract(const Duration(days: 7));

    final currentPurchases = purchaseLogs.where((log) {
      final day = _dateOnly(log.createdAt);
      return !_isBefore(day, currentStart) && !_isAfter(day, currentEnd);
    }).toList();

    final previousPurchases = purchaseLogs.where((log) {
      final day = _dateOnly(log.createdAt);
      return !_isBefore(day, previousStart) && !_isAfter(day, previousEnd);
    }).toList();

    final currentUrges = urgeSessions.where((session) {
      final day = _dateOnly(session.completedAt);
      return !_isBefore(day, currentStart) && !_isAfter(day, currentEnd);
    }).toList();

    final previousUrges = urgeSessions.where((session) {
      final day = _dateOnly(session.completedAt);
      return !_isBefore(day, previousStart) && !_isAfter(day, previousEnd);
    }).toList();

    final spentThisWeek = currentPurchases.fold<double>(
      0,
      (sum, log) => sum + log.amount,
    );

    final spentPreviousWeek = previousPurchases.fold<double>(
      0,
      (sum, log) => sum + log.amount,
    );

    final purchasesThisWeek = currentPurchases.length;
    final purchasesPreviousWeek = previousPurchases.length;

    final urgeWinsThisWeek =
        currentUrges.where((session) => session.countsAsUrgeWin).length;
    final urgeWinsPreviousWeek =
        previousUrges.where((session) => session.countsAsUrgeWin).length;

    final cashKeptThisWeek = urgeWinsThisWeek * averageSpend;
    final cashKeptPreviousWeek = urgeWinsPreviousWeek * averageSpend;

    return WeeklySummary(
      spentThisWeek: spentThisWeek,
      spentPreviousWeek: spentPreviousWeek,
      purchasesThisWeek: purchasesThisWeek,
      purchasesPreviousWeek: purchasesPreviousWeek,
      urgeWinsThisWeek: urgeWinsThisWeek,
      urgeWinsPreviousWeek: urgeWinsPreviousWeek,
      cashKeptThisWeek: cashKeptThisWeek,
      cashKeptPreviousWeek: cashKeptPreviousWeek,
      topTriggerThisWeek: _topTriggerThisWeek(currentPurchases),
      comparisonMessage: _comparisonMessage(
        purchasesThisWeek: purchasesThisWeek,
        purchasesPreviousWeek: purchasesPreviousWeek,
        spentThisWeek: spentThisWeek,
        spentPreviousWeek: spentPreviousWeek,
      ),
      spendPoints: _buildSpendPoints(
        start: currentStart,
        end: currentEnd,
        logs: purchaseLogs,
      ),
    );
  }

  static List<DailySpendPoint> _buildSpendPoints({
    required DateTime start,
    required DateTime end,
    required List<PurchaseLog> logs,
  }) {
    final points = <DailySpendPoint>[];
    var day = start;

    while (!_isAfter(day, end)) {
      final amount = logs
          .where((log) {
            final logDay = _dateOnly(log.createdAt);
            return logDay.year == day.year &&
                logDay.month == day.month &&
                logDay.day == day.day;
          })
          .fold<double>(0, (sum, log) => sum + log.amount);

      points.add(
        DailySpendPoint(
          day: day,
          amount: amount,
        ),
      );

      day = day.add(const Duration(days: 1));
    }

    return points;
  }

  static String _topTriggerThisWeek(List<PurchaseLog> logs) {
    final tagCounts = <String, int>{};

    for (final log in logs) {
      for (final tag in log.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    if (tagCounts.isNotEmpty) {
      final sorted = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.first.key;
    }

    return 'No common trigger tag yet this week';
  }

  static String _comparisonMessage({
    required int purchasesThisWeek,
    required int purchasesPreviousWeek,
    required double spentThisWeek,
    required double spentPreviousWeek,
  }) {
    if (purchasesThisWeek < purchasesPreviousWeek) {
      final diff = purchasesPreviousWeek - purchasesThisWeek;
      return 'You logged $diff fewer purchase${diff == 1 ? '' : 's'} than the previous 7 days.';
    }

    if (purchasesThisWeek > purchasesPreviousWeek) {
      final diff = purchasesThisWeek - purchasesPreviousWeek;
      return 'You logged $diff more purchase${diff == 1 ? '' : 's'} than the previous 7 days. Keep logging honestly.';
    }

    if (spentThisWeek < spentPreviousWeek) {
      return 'Your purchase count matched the previous 7 days, but you spent less.';
    }

    if (spentThisWeek > spentPreviousWeek) {
      return 'Your purchase count matched the previous 7 days, but spending was higher.';
    }

    return 'Your last 7 days matched the previous 7 days.';
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

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
