import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/setup.dart';
import '../models/adjustment/adjustment.dart';
import '../models/person.dart';
import '../models/component.dart';
import '../models/bike.dart';
import '../widgets/display_adjustment/display_adjustment_list.dart';

class SetupDisplayPage extends StatefulWidget{
  final List<Setup> setups;
  final Setup initialSetup;
  final Map<String, Bike> bikes;
  final Map<String, Person> persons;
  final List<Component> components;
  final Setup? Function({required DateTime datetime, String? bike, String? person}) getPreviousSetupbyDateTime;

  const SetupDisplayPage({
    super.key, 
    required this.setups,
    required this.initialSetup,
    required this.bikes,
    required this.persons,
    required this.components,
    required this.getPreviousSetupbyDateTime,
  });

  @override
  State<SetupDisplayPage> createState() => _SetupDisplayPageState();
}

class _SetupDisplayPageState extends State<SetupDisplayPage> {
  late PageController _pageController;
  late int _currentPageIndex;
  
  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.setups.indexOf(widget.initialSetup);
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  Padding _navigationRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          TextButton.icon(
            onPressed: index > 0 
              ? () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeInOut)
              : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Previous"),
          ),
          Text(
            "Setup ${index + 1} of ${widget.setups.length}",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: index < widget.setups.length - 1 
              ? () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeInOut)
              : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text("Next"),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }

  Widget _notesCard(BuildContext context, String? notes) {
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

    return Card.outlined(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(Icons.notes, size: 20),
                Text("Notes", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Text(notes, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _navigationRow(_currentPageIndex),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPageIndex = index),
        itemCount: widget.setups.length,
        itemBuilder: (context, index) {
          final setup = widget.setups[index];
          
          final Bike? bike = widget.bikes[setup.bike];
          Iterable<Component> bikeComponents = widget.components.where((c) => c.bike == setup.bike);
          final Person? person = widget.persons[setup.person];

          final previousBikeSetup = widget.getPreviousSetupbyDateTime(datetime: setup.datetime, bike: setup.bike);
          final previousPersonSetup = widget.getPreviousSetupbyDateTime(datetime: setup.datetime, person: setup.person);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.setups[_currentPageIndex].name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  "${DateFormat(appSettings.dateFormat).format(setup.datetime)} • ${DateFormat(appSettings.timeFormat).format(setup.datetime)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),),
                ),
                Divider(),
                Text("Context", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                
                ListTile(
                  leading: Icon(Icons.notes),
                  title: Text(setup.notes ?? "sdf"),
                  dense: true,
                ),
                _notesCard(context, setup.notes),
                Text(setup.position.toString()),
                Text(setup.place?.toJson().toString() ?? "no place"),
                Text(setup.weather?.toJson().toString() ?? "No weather data"),
                Divider(),
                Text("Values", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                //TODO: Placeholder for empty adjsutmentValues
                if (bikeComponents.isEmpty)
                  SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'No components available.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      ),
                    ),
                  )
                else
                ...bikeComponents.map((bikeComponent) {
                    return Card.outlined(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(bikeComponent.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(Intl.plural(
                              bikeComponent.adjustments.length,
                              zero: "No adjustments yet.",
                              one: "1 adjustment",
                              other: '${bikeComponent.adjustments.length} adjustments',
                            )),
                            leading: Icon(bikeComponent.componentType.getIconData()),
                          ),
                          AdjustmentDisplayList(
                            adjustments: bikeComponent.adjustments,
                            initialAdjustmentValues: previousBikeSetup?.bikeAdjustmentValues ?? {},
                            adjustmentValues: setup.bikeAdjustmentValues,
                          ),
                        ],
                      ),
                    );
                  }),
                ListTile(
                  leading: const Icon(Bike.iconData),
                  title: Text(setup.bike),
                  dense: true,
                ),
                ListTile(
                  leading: const Icon(Person.iconData),
                  title: Text(setup.person ?? "-"),
                  dense: true,
                ),
                //TODO: Placeholder for empty adjsutmentValues
                //only if person is enables in settips
                ...setup.personAdjustmentValues.entries.map((entry) {
                  return ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text(Adjustment.formatValue(entry.value)),
                  );
                }),
                Divider(),
                Text("Rating", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                //TODO only if rating is enabled in settings
                //TODO: Placeholder for empty adjsutmentValues
                ...setup.ratingAdjustmentValues.entries.map((entry) {
                  return ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text(Adjustment.formatValue(entry.value)),
                  );
                }),
              ],
            ),
          );
        },
      )
    );
  }
}
