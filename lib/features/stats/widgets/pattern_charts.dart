import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/pattern_chart_service.dart';

class PatternBarChart extends StatelessWidget {
  final List<PatternBarPoint> points;

  const PatternBarChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = points.isEmpty
        ? 0.0
        : points.map((point) => point.value).reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double topLabelHeight = 18;
        const double topGap = 6;
        const double bottomGap = 8;
        const double labelHeight = 18;

        final usableBarArea = constraints.maxHeight -
            topLabelHeight -
            topGap -
            bottomGap -
            labelHeight;

        final safeBarArea = usableBarArea < 24 ? 24.0 : usableBarArea;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points.map((point) {
            final ratio = maxValue <= 0 ? 0.0 : point.value / maxValue;
            final barHeight = point.value <= 0
                ? 8.0
                : (safeBarArea * (0.18 + (ratio * 0.82)));

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: topLabelHeight,
                      child: Center(
                        child: Text(
                          point.topLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: topGap),
                    SizedBox(
                      height: safeBarArea,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: point.value > 0
                                ? AppTheme.accent
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: bottomGap),
                    SizedBox(
                      height: labelHeight,
                      child: Center(
                        child: Text(
                          point.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class DualPatternBarChart extends StatelessWidget {
  final List<DualPatternBarPoint> points;

  const DualPatternBarChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = points.isEmpty
        ? 0.0
        : points
            .map((point) => point.leftValue > point.rightValue
                ? point.leftValue
                : point.rightValue)
            .reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double topLabelHeight = 18;
        const double topGap = 6;
        const double bottomGap = 8;
        const double labelHeight = 16;

        final usableBarArea = constraints.maxHeight -
            topLabelHeight -
            topGap -
            bottomGap -
            labelHeight;

        final safeBarArea = usableBarArea < 24 ? 24.0 : usableBarArea;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points.map((point) {
            final leftRatio = maxValue <= 0 ? 0.0 : point.leftValue / maxValue;
            final rightRatio = maxValue <= 0 ? 0.0 : point.rightValue / maxValue;

            final leftHeight = point.leftValue <= 0
                ? 8.0
                : (safeBarArea * (0.18 + (leftRatio * 0.82)));
            final rightHeight = point.rightValue <= 0
                ? 8.0
                : (safeBarArea * (0.18 + (rightRatio * 0.82)));

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: topLabelHeight,
                      child: Center(
                        child: Text(
                          point.topLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: topGap),
                    SizedBox(
                      height: safeBarArea,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: leftHeight,
                                decoration: BoxDecoration(
                                  color: point.leftValue > 0
                                      ? AppTheme.accent
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: rightHeight,
                                decoration: BoxDecoration(
                                  color: point.rightValue > 0
                                      ? Colors.white70
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: bottomGap),
                    SizedBox(
                      height: labelHeight,
                      child: Center(
                        child: Text(
                          point.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
