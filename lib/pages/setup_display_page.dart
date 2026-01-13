import 'package:flutter/material.dart';
import '../models/setup.dart';
import '../models/adjustment/adjustment.dart';
import '../models/person.dart';
import '../models/bike.dart';

class SetupDisplayPage extends StatefulWidget{
  final List<Setup> setups;
  final Setup initialSetup;

  const SetupDisplayPage({
    super.key, 
    required this.setups,
    required this.initialSetup,
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.setups[_currentPageIndex].name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(setup.datetime.toIso8601String()),
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
                ListTile(
                  leading: const Icon(Bike.iconData),
                  title: Text(setup.bike),
                  dense: true,
                ),
                ...setup.bikeAdjustmentValues.entries.map((entry) {
                  return ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text(Adjustment.formatValue(entry.value)),
                  );
                }),
                ListTile(
                  leading: const Icon(Person.iconData),
                  title: Text(setup.person ?? "-"),
                  dense: true,
                ),
                //TODO: Placeholder for empty adjsutmentValues
                ...setup.personAdjustmentValues.entries.map((entry) {
                  return ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text(Adjustment.formatValue(entry.value)),
                  );
                }),
                Divider(),
                Text("Rating", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
