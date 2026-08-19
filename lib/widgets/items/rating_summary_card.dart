import 'package:flutter/material.dart';

import '../../models/rating_metric.dart';

class RatingSummaryCard extends StatelessWidget {
  final int entryCount;
  final double? score;
  final Map<String, double> metricScores;
  final Map<String, RatingMetric> metrics;

  const RatingSummaryCard({
    super.key,
    required this.entryCount,
    required this.score,
    required this.metricScores,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RatingSummaryContent(
          entryCount: entryCount,
          score: score,
          metricScores: metricScores,
          metrics: metrics,
        ),
      ),
    );
  }
}

class RatingSummaryContent extends StatelessWidget {
  final int entryCount;
  final double? score;
  final Map<String, double> metricScores;
  final Map<String, RatingMetric> metrics;
  final Iterable<String>? metricIds;
  final bool compactMetrics;

  const RatingSummaryContent({
    super.key,
    required this.entryCount,
    required this.score,
    required this.metricScores,
    required this.metrics,
    this.metricIds,
    this.compactMetrics = false,
  });

  @override
  Widget build(BuildContext context) {
    final ids = metricIds ?? metricScores.keys;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreHeader(
          entryCount: entryCount,
          score: score,
        ),
        if (ids.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final id in ids)
            if (metrics[id] != null)
              _MetricProgress(
                metric: metrics[id]!,
                score: metricScores[id],
                compact: compactMetrics,
              ),
        ],
      ],
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final int entryCount;
  final double? score;

  const _ScoreHeader({
    required this.entryCount,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scoreBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: score == null ? scheme.surfaceContainerHighest : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        score == null ? '– / 10' : '${score!.toStringAsFixed(1)} / 10',
        maxLines: 1,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: score == null ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    final countText = Text(
      entryCount == 0 ? 'No ratings yet' : 'Avg. of $entryCount rating${entryCount == 1 ? '' : 's'}',
      style: TextStyle(color: scheme.onSurfaceVariant),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              scoreBadge,
              const SizedBox(height: 8),
              countText,
            ],
          );
        }
        return Row(
          children: [
            scoreBadge,
            const SizedBox(width: 12),
            Expanded(child: countText),
          ],
        );
      },
    );
  }
}

class _MetricProgress extends StatelessWidget {
  final RatingMetric metric;
  final double? score;
  final bool compact;

  const _MetricProgress({
    required this.metric,
    required this.score,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final absWeight = metric.weight.abs();
    final weight = absWeight == absWeight.roundToDouble() ? absWeight.toStringAsFixed(0) : absWeight.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            _MetricName(metric: metric),
            const SizedBox(height: 4),
            Row(
              children: [
                _MetricScore(score: score),
                const SizedBox(width: 8),
                _WeightBadge(weight: weight),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _MetricName(metric: metric),
                ),
                const SizedBox(width: 8),
                _MetricScore(score: score),
                const SizedBox(width: 8),
                _WeightBadge(weight: weight),
              ],
            ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score == null ? 0 : (score! / 10).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
          if (metric.weight < 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'lower is better',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricName extends StatelessWidget {
  final RatingMetric metric;

  const _MetricName({required this.metric});

  @override
  Widget build(BuildContext context) => Text(
    metric.adjustment.name,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(fontWeight: FontWeight.w500),
  );
}

class _MetricScore extends StatelessWidget {
  final double? score;

  const _MetricScore({required this.score});

  @override
  Widget build(BuildContext context) => Text(
    score == null ? '– / 10' : '${score!.toStringAsFixed(1)}/10',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _WeightBadge extends StatelessWidget {
  final String weight;

  const _WeightBadge({required this.weight});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '×$weight',
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
