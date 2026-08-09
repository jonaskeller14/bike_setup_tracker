import 'package:flutter/material.dart';

import '../models/context/context_weather.dart';

class SoilMoistureLegendTable extends StatelessWidget {
  const SoilMoistureLegendTable({super.key});

  static final List<Map<String, dynamic>> _conditionsData = [
    {
      'range': '0.00 - 0.09',
      'label': Condition.dry.value,
      'icon': Condition.dry.iconData,
      'color': Condition.dry.color,
    },
    {
      'range': '0.10 - 0.19',
      'label': Condition.moist.value,
      'icon': Condition.moist.iconData,
      'color': Condition.moist.color,
    },
    {
      'range': '0.20 - 0.34',
      'label': Condition.wet.value,
      'icon': Condition.wet.iconData,
      'color': Condition.wet.color,
    },
    {
      'range': '0.35+',
      'label': Condition.muddy.value,
      'icon': Condition.muddy.iconData,
      'color': Condition.muddy.color,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const SizedBox.shrink(),
      title: DataTable(
        columnSpacing: 25,
        dataRowMinHeight: 25,
        dataRowMaxHeight: 25,
        headingRowHeight: 25,
        
        columns: [
          DataColumn(
            label: Text(
              'Soil Moisture [m³/m³]',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          DataColumn(
            label: Text(
              'Condition',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],

        rows: _conditionsData.map((data) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  data['range']! as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),

              DataCell(
                Row(
                  children: [
                    Icon(
                      data['icon'] as IconData,
                      color: data['color'] as Color,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['label']! as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: data['color'] as Color),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
