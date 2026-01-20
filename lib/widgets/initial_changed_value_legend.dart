import 'package:flutter/material.dart';

class InitialChangedValueLegend extends StatelessWidget {
  const InitialChangedValueLegend({super.key});
  Widget _buildLegendItem(BuildContext context, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Wrap(
          spacing: 30.0,
          runSpacing: 4.0,
          children: <Widget>[
            _buildLegendItem(
              context,
              Colors.green.withValues(alpha: 0.20),
              'Initial Value',
            ),
            _buildLegendItem(
              context,
              Colors.orange.withValues(alpha: 0.20),
              'Changed Value',
            ),
          ],
        ),
      ),
    );
  }
}
