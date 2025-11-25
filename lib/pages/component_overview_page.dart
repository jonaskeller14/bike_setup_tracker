import 'package:bike_setup_tracker/models/adjustment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/component.dart';
import '../models/setup.dart';

class ComponentOverviewPage extends StatefulWidget{
  final Component component;
  final List<Setup> setups;

  const ComponentOverviewPage({
    super.key, 
    required this.component, 
    required this.setups,
  });

  @override
  State<ComponentOverviewPage> createState() => _ComponentOverviewPageState();
}

class _ComponentOverviewPageState extends State<ComponentOverviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Component.getIcon(widget.component.componentType),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.component.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(
                label: Text(
                  'Setup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final adjustment in widget.component.adjustments)
                DataColumn(
                  label: Text(
                    adjustment.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            rows: widget.setups.reversed.where((setup) {
                return widget.component.adjustments.any(
                  (componentAdjustment) => setup.adjustmentValues.containsKey(componentAdjustment)
                );
              }).map((setup) {
              return DataRow(
                cells: [
                  DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: Text(setup.name, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(DateFormat('yyyy-MM-dd').format(setup.datetime))),
                  for (final adjustment in widget.component.adjustments)
                    DataCell(
                      Text(
                        Adjustment.formatValue(setup.adjustmentValues[adjustment]),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
