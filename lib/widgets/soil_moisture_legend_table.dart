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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: DataTable(
        columnSpacing: 25,
        dataRowMinHeight: 25,
        dataRowMaxHeight: 25,
        headingRowHeight: 25,
        
        columns: const [
          DataColumn(
            label: Text(
              'Soil Moisture',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Condition',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],

        rows: _conditionsData.map((data) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  data['range']!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),

              DataCell(
                Row(
                  children: [
                    Icon(
                      data['icon'] as IconData,
                      color: data['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['label']!,
                      style: TextStyle(color: data['color'] as Color),
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