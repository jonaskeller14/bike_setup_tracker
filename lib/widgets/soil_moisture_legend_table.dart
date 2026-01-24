import 'package:flutter/material.dart';
import '../models/weather.dart';

class SoilMoistureLegendTable extends StatelessWidget {
  const SoilMoistureLegendTable({super.key});

  static final List<Map<String, dynamic>> _conditionsData = [
    {
      'range': '0.00 - 0.09',
      'label': Condition.dry.value,
      'icon': Condition.dry.getIconData(),
      'color': Condition.dry.getColor(),
    },
    {
      'range': '0.10 - 0.19',
      'label': Condition.moist.value,
      'icon': Condition.moist.getIconData(),
      'color': Condition.moist.getColor(),
    },
    {
      'range': '0.20 - 0.34',
      'label': Condition.wet.value,
      'icon': Condition.wet.getIconData(),
      'color': Condition.wet.getColor(),
    },
    {
      'range': '0.35+',
      'label': Condition.muddy.value,
      'icon': Condition.muddy.getIconData(),
      'color': Condition.muddy.getColor(),
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
                  data['range']!,
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
                      data['label']!,
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