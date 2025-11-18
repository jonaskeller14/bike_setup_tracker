import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../models/adjustment.dart';
import '../models/setting.dart';
import '../models/component.dart';
import 'add_bike_page.dart';
import 'edit_bike_page.dart';
import 'add_component_page.dart';
import 'edit_component_page.dart';
import 'add_setting_page.dart';
import 'edit_setting_page.dart';
import '../utils/file_export.dart';
import '../utils/file_import.dart';
import '../widgets/bike_list.dart';
import '../widgets/component_list.dart';
import '../widgets/setting_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Bike> bikes = [];
  final List<Adjustment> adjustments = [];
  final List<Setting> settings = [];
  final List<Component> components = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await FileImport.readData(context);
    if (data == null) return;

    if (!mounted) return;
    setState(() {
      bikes
        ..clear()
        ..addAll(data.bikes);
      adjustments
        ..clear()
        ..addAll(data.adjustments);
      settings
        ..clear()
        ..addAll(data.settings);
      components
        ..clear()
        ..addAll(data.components);
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> loadJsonFileData() async {
    final data = await FileImport.readJsonFileData(context);
    if (data == null) return;

    if (!mounted) return;
    final choice = await FileImport.showImportChoiceDialog(context);
    if (choice == 'cancel' || choice == null) return;

    if (choice == 'overwrite') {
      setState(() {
        bikes
          ..clear()
          ..addAll(data.bikes);
        adjustments
          ..clear()
          ..addAll(data.adjustments);
        settings
          ..clear()
          ..addAll(data.settings);
        components
          ..clear()
          ..addAll(data.components);
      });
    } else if (choice == 'merge') {
      setState(() {
        for (var b in data.bikes) {
          if (!bikes.any((x) => x.id == b.id)) {
            bikes.add(b);
          }
        }

        for (var a in data.adjustments) {
          if (!adjustments.any((x) => x.id == a.id)) {
            adjustments.add(a);
          }
        }

        for (var s in data.settings) {
          if (!settings.any((x) => x.id == s.id)) {
            settings.add(s);
          }
        }

        for (var c in data.components) {
          if (!components.any((x) => x.id == c.id)) {
            components.add(c);
          }
        }
      });
    }

    await FileExport.saveData(
      bikes: bikes, 
      adjustments: adjustments,
      settings: settings,
      components: components,
    );
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(choice == 'overwrite'
          ? 'Data overwritten successfully'
          : 'Data merged successfully')),
    );
  }

  Future<void> clearData() async {
    final confirmed = await showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      adjustments.clear();
      settings.clear();
      components.clear();
    });
  }

  Future<void> removeBike(Bike bike) async {
    //TODO: Check --> At least one bike needs to exist
    final confirmed = await showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    setState(() {
      bikes.remove(bike);
      //TODO: remove components of this bike
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> removeSetting(Setting setting) async {
    final confirmed = await showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    setState(() {
      settings.remove(setting);
      // Also ensure components don't hold dangling references
      for (var c in components) {
        if (c.currentSetting == setting) {
          c.currentSetting = null;
        }
      }
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> removeComponent(Component component) async {
    final confirmed = await showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    setState(() {
      for (var adjustment in component.adjustments) {
        adjustments.remove(adjustment);
      }
      components.remove(component);
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> _addBike() async {
    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => const AddBikePage()),
    );
    if (bike == null) return;
  
    setState(() {
      bikes.add(bike);
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> _addComponent() async {
    final component = await Navigator.push<Component>(
      context,
      MaterialPageRoute(builder: (context) => AddComponentPage(bikes: bikes)),
    );
    if (component == null) return;
  
    setState(() {
      components.add(component);
      adjustments.addAll(component.adjustments);
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> editBike(Bike bike) async {
    final editedBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => EditBikePage(bike: bike),
      ),
    );
    if (editedBike != null) {
      setState(() {
        final index = bikes.indexOf(bike);
        if (index != -1) {
          bikes[index] = editedBike;
        }
      });
      await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
    }
  }

  Future<void> editComponent(Component component) async {
    //TODO: Update adjustments?
    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => EditComponentPage(component: component),
      ),
    );
    if (editedComponent != null) {
      setState(() {
        final index = components.indexOf(component);
        if (index != -1) {
          components[index] = editedComponent;
        }
      });
      await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
    }
  }

  Future<void> _addSetting() async {
    final setting = await Navigator.push<Setting>(
      context,
      MaterialPageRoute(builder: (context) => AddSettingPage(components: components)),
    );
    if (setting == null) return;
    
    setState(() {
      setting.previousSetting = components.firstOrNull?.currentSetting;  //FIXME
      for (var component in components) {
        component.currentSetting = setting;
      }
      settings.add(setting);
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> editSetting(Setting setting) async {
    final editedSetting = await Navigator.push<Setting>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSettingPage(setting: setting),
      ),
    );
    if (editedSetting != null) {
      setState(() {
        final index = settings.indexOf(setting);
        if (index != -1) {
          settings[index] = editedSetting;
        }
      });
      await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Continue"),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: loadJsonFileData,
            icon: Icon(Icons.file_upload),
          ),
          IconButton(
            onPressed: () {
              FileExport.downloadJson(
                context: context,
                bikes: bikes,
                adjustments: adjustments,
                settings: settings,
                components: components,
              );
            },
            icon: const Icon(Icons.file_download),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text("Bikes", style: Theme.of(context).textTheme.headlineSmall),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addBike,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          BikeList(bikes: bikes, editBike: editBike, removeBike: removeBike),

          ListTile(
            title: Text("Components", style: Theme.of(context).textTheme.headlineSmall),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addComponent,
              tooltip: 'Add Component',
            ),
            contentPadding: EdgeInsets.zero,
          ),

          ComponentList(
            components: components,
            editComponent: editComponent,
            removeComponent: removeComponent,
          ),

          ListTile(
            title: Text("Setting History", style: Theme.of(context).textTheme.headlineSmall),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addSetting,
              tooltip: 'Add Setting',
            ),
            contentPadding: EdgeInsets.zero,
          ),

          SettingList(
            settings: settings,
            editSetting: editSetting,
            removeSetting: removeSetting,
          ),

          const SizedBox(height: 200),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: "addSetting",
              onPressed: _addSetting,
              tooltip: 'Add Setting',
              label: const Text('Add Setting'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "clearData",
              onPressed: clearData,
              label: const Text('#TODO Clear Data'),
              icon: const Icon(Icons.delete),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "loadData",
              onPressed: loadData,
              label: const Text('#TODO Load Data'),
              icon: const Icon(Icons.file_upload),
            ),
          ],
        ),
      ),
    );
  }
}
