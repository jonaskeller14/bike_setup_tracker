import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/setup.dart';
import '../models/rating.dart';
import '../models/app_settings.dart';

class TrashPage extends StatefulWidget{
  final Map<String, Person> persons;
  final Map<String, Bike> bikes;
  final List<Component> components;
  final List<Setup> setups;
  final Map<String, Rating> ratings;
  final VoidCallback onChanged;

  const TrashPage({
    super.key, 
    required this.persons,
    required this.bikes,
    required this.components, 
    required this.setups,
    required this.ratings,
    required this.onChanged,
  });

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  bool hasChanges = false;

  @override
  void dispose() {
    if (hasChanges) widget.onChanged();
    super.dispose();
  }

  ListTile _trashItem({required dynamic deletedItem, required DateFormat dateFormat, required DateFormat timeFormat}) {
    return ListTile(
      leading: deletedItem is Bike 
          ? const Icon(Icons.pedal_bike) 
          : deletedItem is Component 
              ? Component.getIcon(deletedItem.componentType) 
              : deletedItem is Setup 
                  ? const Icon(Icons.tune) 
                  : deletedItem is Person
                      ? const Icon(Icons.person)
                      : deletedItem is Rating
                          ? const Icon(Icons.star)
                          : null,
      title: Text(deletedItem.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Deleted at: ${dateFormat.format(deletedItem.lastModified)} ${timeFormat.format(deletedItem.lastModified)}"),
      trailing: IconButton(
        icon: Icon(Icons.restore_from_trash),
        onPressed: () {
          setState(() {
            deletedItem.isDeleted = false;
            deletedItem.lastModified = DateTime.now();
            hasChanges = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    
    final deletedCombined = <dynamic>[];
    deletedCombined.addAll(widget.persons.values.where((p) => p.isDeleted).toList());
    deletedCombined.addAll(widget.bikes.values.where((b) => b.isDeleted).toList());
    deletedCombined.addAll(widget.components.where((c) => c.isDeleted));
    deletedCombined.addAll(widget.setups.where((s) => s.isDeleted));
    deletedCombined.addAll(widget.ratings.values.where((r) => r.isDeleted).toList());
    deletedCombined.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          spacing: 8,
          children: [
            Icon(Icons.delete),
            Expanded(child: Text('Trash')),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Items in the Trash are permanently deleted after 30 days. The Trash is emptied automatically.'),
            dense: true,
          ),
          Expanded(
            child: deletedCombined.isEmpty
                ? Center(
                    child: Text(
                      "Empty Trash",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: deletedCombined.length,
                    itemBuilder: (context, index) {
                      final deletedItem = deletedCombined[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: _trashItem(
                          deletedItem: deletedItem,
                          dateFormat: DateFormat(appSettings.dateFormat),
                          timeFormat: DateFormat(appSettings.timeFormat),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
