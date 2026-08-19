import 'package:flutter/material.dart';

import '../../models/setup_comparison.dart' as comparison;
import 'rating_summary_card.dart';

class RatingSummaryCardDiff extends StatelessWidget {
  final comparison.SetupComparisonRatingSummary ratingsA;
  final comparison.SetupComparisonRatingSummary ratingsB;

  const RatingSummaryCardDiff({
    super.key,
    required this.ratingsA,
    required this.ratingsB,
  });

  @override
  Widget build(BuildContext context) {
    final metricIds = {...ratingsA.metricScores.keys, ...ratingsB.metricScores.keys}.toList()
      ..sort((a, b) => _metricName(a).compareTo(_metricName(b)));
    return Semantics(
      container: true,
      label: 'Ratings comparison',
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RatingSummaryContent(
                  entryCount: ratingsA.entryCount,
                  score: ratingsA.score,
                  metricScores: ratingsA.metricScores,
                  metrics: {...ratingsB.metrics, ...ratingsA.metrics},
                  metricIds: metricIds,
                  compactMetrics: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RatingSummaryContent(
                  entryCount: ratingsB.entryCount,
                  score: ratingsB.score,
                  metricScores: ratingsB.metricScores,
                  metrics: {...ratingsA.metrics, ...ratingsB.metrics},
                  metricIds: metricIds,
                  compactMetrics: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _metricName(String id) => (ratingsA.metrics[id] ?? ratingsB.metrics[id])?.adjustment.name.toLowerCase() ?? id;
}
