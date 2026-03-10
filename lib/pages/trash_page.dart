import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../models/filtered_data.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/setup.dart';
import '../models/rating.dart';
import '../models/app_settings.dart';

class TrashPage extends StatelessWidget{
  const TrashPage({super.key});

  ListTile _trashItem({required BuildContext context, required dynamic deletedItem}) {
    final appSettings = context.read<AppSettings>();
    final dateFormat = DateFormat(appSettings.dateFormat);
    final timeFormat = DateFormat(appSettings.timeFormat);

    final data = context.read<AppData>();

    final lastModified = deletedItem.lastModified as DateTime;

    return ListTile(
      leading: switch(deletedItem) {
        Bike() => const Icon(Bike.iconData),
        Component() => Icon(deletedItem.componentType.getIconData()),
        Setup() => const Icon(Setup.iconData),
        Person() => const Icon(Person.iconData),
        Rating() => const Icon(Rating.iconData),
        _ => null,
      },
      title: Text(deletedItem.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Deleted at: ${dateFormat.format(lastModified.toLocal())} ${timeFormat.format(lastModified.toLocal())}"),
      trailing: IconButton(
        icon: Icon(Icons.restore_from_trash),
        onPressed: () {
          switch (deletedItem) {
            case Bike(): data.restoreBike(deletedItem);
            case Component(): data.restoreComponents([deletedItem]);
            case Setup(): data.restoreSetups([deletedItem]);
            case Person(): data.restorePerson(deletedItem);
            case Rating(): data.restoreRatings([deletedItem]);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();

    final deletedCombined = <dynamic>[];
    deletedCombined.addAll(filteredData.deletedPersons);
    deletedCombined.addAll(filteredData.deletedBikes);
    deletedCombined.addAll(filteredData.deletedComponents);
    deletedCombined.addAll(filteredData.deletedSetups);
    deletedCombined.addAll(filteredData.deletedRatings);
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
      body: SafeArea(
        bottom: false,
        child: Column(
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
                          child: _trashItem(context: context, deletedItem: deletedItem),
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom)
          ],
        ),
      ),
    );
  }
}
