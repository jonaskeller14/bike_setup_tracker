import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/setup.dart';

class TrashPage extends StatefulWidget{
  final Map<String, Bike> bikes;
  final List<Component> components;
  final List<Setup> setups;

  const TrashPage({
    super.key, 
    required this.bikes,
    required this.components, 
    required this.setups,
  });

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {

  @override
  Widget build(BuildContext context) {
    //FIXME: Sort lists by last modified
    final deletedCombined = <dynamic>[];
    deletedCombined.addAll(widget.bikes.values.where((b) => b.isDeleted).toList());
    deletedCombined.addAll(widget.components.where((c) => c.isDeleted));
    deletedCombined.addAll(widget.setups.where((s) => s.isDeleted));
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
      body: deletedCombined.isEmpty 
          ? Center(
              child: Text("Empty Tash", style: TextStyle(color: Colors.grey.shade600)), 
            ) 
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: deletedCombined.length,
              itemBuilder: (context, index) {
                final deletedItem = deletedCombined[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: deletedItem is Bike 
                        ? Icon(Icons.pedal_bike) 
                        : deletedItem is Component 
                            ? Component.getIcon(deletedItem.componentType) 
                            : deletedItem is Setup 
                                ? Icon(Icons.tune) 
                                : null,
                    title: Text(deletedItem.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Deleted at: ${DateFormat("yyyy-MM-dd HH:mm").format(deletedItem.lastModified)}"),
                    trailing: IconButton(
                      icon: Icon(Icons.restore_from_trash),
                      onPressed: () {
                        setState(() {
                          deletedItem.isDeleted = false;
                          deletedItem.lastModified = DateTime.now();
                        });
                      },
                    ),
                  ),
                );
              }
            ),
    );
  }
}
