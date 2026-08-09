import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme.dart';

class InitialChangedValueLegend extends StatelessWidget {
  @Preview(name: "InitialChangedValueLegend")
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
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Wrap(
          spacing: 30.0,
          runSpacing: 4.0,
          children: <Widget>[
            _buildLegendItem(
              context,
              highlights?.initial ?? Colors.green,
              'Initial Value',
            ),
            _buildLegendItem(
              context,
              highlights?.changed ?? Colors.orange,
              'Changed Value',
            ),
          ],
        ),
      ),
    );
  }
}
