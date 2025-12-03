import 'package:flutter/material.dart';

class ValueChangeLegend extends StatelessWidget {
  const ValueChangeLegend({super.key});
  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
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
              Colors.green.withValues(alpha: 0.20),
              'Initial value',
            ),
            _buildLegendItem(
              Colors.orange.withValues(alpha: 0.20),
              'Changed Value',
            ),
          ],
        ),
      ),
    );
  }
}
