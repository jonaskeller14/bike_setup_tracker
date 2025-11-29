import 'package:flutter/material.dart';

class SoilMoistureLegendTable extends StatelessWidget {
  const SoilMoistureLegendTable({super.key});

  static final List<Map<String, dynamic>> _conditionsData = [
    {
      'range': '0.00 - 0.09',
      'label': 'Dry',
      'icon': Icons.wb_sunny,
      'color': Colors.deepOrange,
    },
    {
      'range': '0.10 - 0.19',
      'label': 'Moist',
      'icon': Icons.water_drop_outlined,
      'color': Colors.amber,
    },
    {
      'range': '0.20 - 0.34',
      'label': 'Wet',
      'icon': Icons.water_drop,
      'color': Colors.lightBlue,
    },
    {
      'range': '0.35+',
      'label': 'Muddy',
      'icon': Icons.water,
      'color': Colors.blue,
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