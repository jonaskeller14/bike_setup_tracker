import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/adjustment/adjustment.dart';
import '../models/app_data.dart';
import '../models/app_settings.dart';


String toText({
  required BuildContext context,
  required AppData appData,
  required List<String> selectedPersons,
  required List<String> selectedBikes,
  required List<String> selectedComponents,
  required List<String> selectedSetups,
}) {
  //TODO: Location, Address, Weather context, person values, rating values
  //TODO: Highlight deleted items
  final appSettings = context.read<AppSettings>();

  final List<String> sections = [];
  
  final persons = appData.persons.values.where((p) => selectedPersons.contains(p.id));
  if (appSettings.enablePerson && persons.isNotEmpty) {
    final List<String> sectionItems = ["PROFILES:"];
    sectionItems.addAll(persons.map((p) => "👤 ${p.name}${p.isDeleted ? ' [DELETED]' : ''}"));

    sections.add(sectionItems.join("\n"));
  }

  final bikes = appData.bikes.values.where((b) => selectedBikes.contains(b.id));
  if (bikes.isNotEmpty) {
    final List<String> sectionItems = ["BIKES:"];
    for (final b in bikes) {
      if (appSettings.enablePerson) {
        sectionItems.add("🚲 ${b.name} (${appData.persons[b.person]?.name ?? '-'})${b.isDeleted ? ' [DELETED]' : ''}");

      } else {
        sectionItems.add("🚲 ${b.name}${b.isDeleted ? ' [DELETED]' : ''}");
      }
      if (b.notes != null) sectionItems.add(b.notes!);
    }

    sections.add(sectionItems.join("\n"));
  }

  final setups = appData.setups.values.where((s) => selectedSetups.contains(s.id));
  if (setups.isNotEmpty) {
    final List<String> sectionItems = ["SETUPS:"];
    for (final setup in setups) {
      final dateString = DateFormat(appSettings.dateFormat).format(setup.datetime);
      final timeString = DateFormat(appSettings.timeFormat).format(setup.datetime);

      if (appSettings.enablePerson) {
        sectionItems.add("🎛️ $dateString $timeString - ${setup.name} (${appData.bikes[setup.bike]?.name ?? '-'} | ${appData.persons[setup.person]?.name ?? '-'})${setup.isDeleted ? ' [DELETED]' : ''}");
      } else {
        sectionItems.add("🎛️ $dateString $timeString - ${setup.name} (${appData.bikes[setup.bike]?.name ?? '-'})${setup.isDeleted ? ' [DELETED]' : ''}");
      }

      if (setup.notes != null) sectionItems.add(setup.notes!);

      final components = appData.components.values.where((c) => selectedComponents.contains(c.id));
      for (final component in components) {
        if (!component.adjustments.any((adj) => setup.bikeAdjustmentValues.containsKey(adj.id))) continue;

        sectionItems.add("- ${component.name}");
        for (final adjustment in component.adjustments) {
          sectionItems.add("\t- ${adjustment.name}: ${Adjustment.formatValue(setup.bikeAdjustmentValues[adjustment.id])}${adjustment.unitSuffix()}");
        }
        //FIXME: Dangling adjustmentvalues
        //FIXME: Person adjustmentValues
        //FIXME: Rating adjustmentValues
      }

      sectionItems.add("\n");
      
    }
    sections.add(sectionItems.join("\n"));
  }

  return sections.join("\n-----------\n\n");
}
