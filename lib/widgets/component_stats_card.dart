import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/component_stats.dart';

class ComponentStatsCard extends StatefulWidget {
  final ComponentStats componentStats;

  const ComponentStatsCard({super.key, required this.componentStats});

  @override
  State<ComponentStatsCard> createState() => _ComponentStatsCardState();
}

class _ComponentStatsCardState extends State<ComponentStatsCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildStatItem(BuildContext context, {required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() {
                unawaited(HapticFeedback.selectionClick());
                _currentPage = index;
              }),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.route,
                      label: "Distance",
                      value: '${NumberFormat.decimalPattern().format((widget.componentStats.distance / 1000).round())} km',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.terrain_outlined,
                      label: "Elevation",
                      value: '${NumberFormat.decimalPattern().format(widget.componentStats.elevationGain.round())} m',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.timer_outlined,
                      label: "Moving Time",
                      value: '${NumberFormat.decimalPattern().format(widget.componentStats.movingTime.inHours)}h ${widget.componentStats.movingTime.inMinutes.remainder(60)}m',
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.timer_outlined,
                      label: "Elapsed Time",
                      value: '${NumberFormat.decimalPattern().format(widget.componentStats.elapsedTime.inHours)}h ${widget.componentStats.elapsedTime.inMinutes.remainder(60)}m',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.repeat,
                      label: "Activities",
                      value: '${widget.componentStats.activityCount}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            )),
          ),
        ],
      ),
    );
  }
}
