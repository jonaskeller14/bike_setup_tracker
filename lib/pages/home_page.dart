import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../models/adjustment.dart';
import '../models/setting.dart';
import '../models/component.dart';
import 'bike_page.dart';
import 'component_page.dart';
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
        ..addAll(data.settings)
        ..sort((a, b) => a.datetime.compareTo(b.datetime));
      components
        ..clear()
        ..addAll(data.components);
      determineCurrentSettings();
      determinePreviousSettings();
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
          ..addAll(data.settings)
          ..sort((a, b) => a.datetime.compareTo(b.datetime));
        determineCurrentSettings();
        determinePreviousSettings();
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
        settings.sort((a, b) => a.datetime.compareTo(b.datetime));
        determineCurrentSettings();
        determinePreviousSettings();

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
    final confirmed = await showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    final obsoleteComponents = components.where((c) => c.bike == bike).toList();
    final obsoleteSettings = settings.where((s) => s.bike == bike).toList();

    setState(() {
      bikes.remove(bike);
    });

    removeComponents(obsoleteComponents, confirm: false);
    removeSettings(obsoleteSettings, confirm: false);

    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> removeSetting(Setting toRemoveSetting) async {
    removeSettings([toRemoveSetting]);
  }

  Future<void> removeSettings(List<Setting> toRemoveSettings, {bool confirm = true}) async {
    if (toRemoveSettings.isEmpty) return;

    if (confirm) {
      final confirmed = await showConfirmationDialog(context);
      if (!confirmed) return;
    }

    setState(() {
      for (var setting in toRemoveSettings) {
        settings.remove(setting);

        // Also ensure components don't hold dangling references
        for (var c in components) {
          if (c.currentSetting == setting) {
            c.currentSetting = null;
          }
        }
      }
      determineCurrentSettings();
      determinePreviousSettings();
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> removeComponent(Component toRemoveComponent) async {
    removeComponents([toRemoveComponent]);
  }

  Future<void> removeComponents(List<Component> toRemoveComponents, {bool confirm = true}) async {
    if (toRemoveComponents.isEmpty) return;

    if (confirm) {
      final confirmed = await showConfirmationDialog(context);
      if (!confirmed) return;
    }

    setState(() {
      for (var component in toRemoveComponents) {
        for (var adjustment in component.adjustments) {
          adjustments.remove(adjustment);
        }
        components.remove(component);
      }
    });

    await FileExport.saveData(
      bikes: bikes,
      adjustments: adjustments,
      settings: settings,
      components: components,
    );
  }
  
  Future<void> _addBike() async {
    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => const BikePage()),
    );
    if (bike == null) return;
  
    setState(() {
      bikes.add(bike);
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> _addComponent() async {
    if (bikes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Add a bike first"), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    final component = await Navigator.push<Component>(
      context,
      MaterialPageRoute(builder: (context) => ComponentPage(bikes: bikes)),
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
        builder: (context) => BikePage(bike: bike),
      ),
    );
    if (editedBike == null) return;
    setState(() {
      final index = bikes.indexOf(bike);
      if (index != -1) {
        bikes[index] = editedBike;
      }
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> editComponent(Component component) async {
    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage(component: component, bikes: bikes),
      ),
    );
    if (editedComponent == null) return;

    setState(() {
      final index = components.indexOf(component);
      if (index != -1) {
        components[index] = editedComponent;
      }
    });
    await resetAdjustments();
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> duplicateComponent(Component component) async {
    final newComponent = component.deepCopy();
    setState(() {
      components.add(newComponent);
      adjustments.addAll(newComponent.adjustments);
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
    editComponent(newComponent);
  }

  Future<void> resetAdjustments() async {
    adjustments.clear();
    for (final component in components) {
      adjustments.addAll(component.adjustments);
    }
    
    Set<Adjustment> toRemoveAdjustments = adjustments.toSet();
    for (final component in components) {
      for (final adjustment in component.adjustments) {
        toRemoveAdjustments.remove(adjustment);
      }
    }
    for (final toRemoveAdjustment in toRemoveAdjustments) {
      adjustments.remove(toRemoveAdjustment);
    }
  }

  Future<void> _addSetting() async {
    if (bikes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Add a bike first"), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (components.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Add a component first"), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    final setting = await Navigator.push<Setting>(
      context,
      MaterialPageRoute(builder: (context) => AddSettingPage(components: components, bikes: bikes)),
    );
    if (setting == null) return;
    
    setState(() {
      settings.add(setting);
      settings.sort((a, b) => a.datetime.compareTo(b.datetime));
      determineCurrentSettings();
      determinePreviousSettings();
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
  }

  Future<void> editSetting(Setting setting) async {
    final editedSetting = await Navigator.push<Setting>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSettingPage(setting: setting, components: components, bikes: bikes),
      ),
    );
    if (editedSetting != null) {
      setState(() {
        final index = settings.indexOf(setting);
        if (index != -1) {
          settings[index] = editedSetting;
        }
        settings.sort((a, b) => a.datetime.compareTo(b.datetime));
        determineCurrentSettings();
        determinePreviousSettings();
      });
      await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);
    }
  }

  Future<void> restoreSetting(Setting setting) async {
    final newSetting = Setting(
      name: setting.name, 
      bike: setting.bike,
      datetime: DateTime.now(),
      adjustmentValues: setting.adjustmentValues,
      isCurrent: true,
    );  //FIXME: Location and waether data is null --> maybe add default constructor?

    setState(() {
      settings.add(newSetting);
      settings.sort((a, b) => a.datetime.compareTo(b.datetime));
      determineCurrentSettings();
      determinePreviousSettings();
    });
    await FileExport.saveData(bikes: bikes, adjustments: adjustments, settings: settings, components: components);

    editSetting(newSetting);
  }

  Future<void> determineCurrentSettings() async {
    for (final setting in settings) {
      setting.isCurrent = false;
    }
    final remainingBikes = Set.of(bikes);
    for (final setting in settings.reversed) {
      final bike = setting.bike;
      if (remainingBikes.contains(bike)) {
        setting.isCurrent = true;
        for (final component in components.where((c) => c.bike == bike)) {
          component.currentSetting = setting;
        }
        remainingBikes.remove(bike);
        if (remainingBikes.isEmpty) break;
      }
    }
  }

  Future<void> determinePreviousSettings() async {
    Map<Bike, Setting> previousSettings = {}; 
    for (final setting in settings) {
      final bike = setting.bike;
      final previousSetting = previousSettings[bike];
      if (previousSetting != null) setting.previousSetting = previousSetting;
      previousSettings[bike] = setting;
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
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
              onPressed: _addBike,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          BikeList(bikes: bikes, editBike: editBike, removeBike: removeBike),

          ListTile(
            title: Text("Components", style: Theme.of(context).textTheme.headlineSmall),
            trailing: IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
              onPressed: _addComponent,
              tooltip: 'Add Component',
            ),
            contentPadding: EdgeInsets.zero,
          ),

          ComponentList(
            components: components,
            editComponent: editComponent,
            duplicateComponent: duplicateComponent,
            removeComponent: removeComponent,
          ),

          ListTile(
            title: Text("Setting History", style: Theme.of(context).textTheme.headlineSmall),
            trailing: IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
              onPressed: _addSetting,
              tooltip: 'Add Setting',
            ),
            contentPadding: EdgeInsets.zero,
          ),

          SettingList(
            settings: settings,
            components: components,
            editSetting: editSetting,
            restoreSetting: restoreSetting,
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
              label: const Text('Add Setting'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
