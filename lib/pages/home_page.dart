import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import '../models/component.dart';
import 'bike_page.dart';
import 'component_page.dart';
import 'setup_page.dart';
import '../utils/file_export.dart';
import '../utils/file_import.dart';
import '../widgets/bike_list.dart';
import '../widgets/component_list.dart';
import '../widgets/setup_list.dart';
import '../widgets/dialogs/confirmation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Bike> bikes = [];
  final List<Setup> setups = [];
  final List<Component> components = [];

  Bike? _selectedBike;
  List<Bike> filteredBikes = [];

  bool _displayOnlyChanges = false;

  void onBikeTap(Bike bike) {
    setState(() {
      if (_selectedBike == bike) {
        _selectedBike = null;
      } else {
        _selectedBike = bike;
      }
      filteredBikes = _selectedBike == null
        ? bikes 
        : bikes.where((b) => b == _selectedBike).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    filteredBikes = bikes;
    _selectedBike = null;
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
      setups
        ..clear()
        ..addAll(data.setups)
        ..sort((a, b) => a.datetime.compareTo(b.datetime));
      components
        ..clear()
        ..addAll(data.components);
      determineCurrentSetups();
      determinePreviousSetups();
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
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
        setups
          ..clear()
          ..addAll(data.setups)
          ..sort((a, b) => a.datetime.compareTo(b.datetime));
        components
          ..clear()
          ..addAll(data.components);
        determineCurrentSetups();
        determinePreviousSetups();
      });
    } else if (choice == 'merge') {
      setState(() {
        for (var b in data.bikes) {
          if (!bikes.any((x) => x.id == b.id)) {
            bikes.add(b);
          }
        }

        for (var s in data.setups) {
          if (!setups.any((x) => x.id == s.id)) {
            setups.add(s);
          }
        }
        for (var c in data.components) {
          if (!components.any((x) => x.id == c.id)) {
            components.add(c);
          }
        }
        setups.sort((a, b) => a.datetime.compareTo(b.datetime));
        determineCurrentSetups();
        determinePreviousSetups();
      });
    }

    await FileExport.saveData(
      bikes: bikes, 
      setups: setups,
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
      setups.clear();
      components.clear();
    });
  }

  Future<void> removeBike(Bike bike) async {
    final confirmed = await showConfirmationDialog(context, content: "This action cannot be undone. All components and setups which belong to this bike will be deleted as well.");
    if (!confirmed) {
      return;
    }

    final obsoleteComponents = components.where((c) => c.bike == bike).toList();
    final obsoleteSetups = setups.where((s) => s.bike == bike).toList();

    setState(() {
      bikes.remove(bike);
      if (bike == _selectedBike) {
        _selectedBike = null;
        filteredBikes = bikes;
      }
    });

    removeComponents(obsoleteComponents, confirm: false);
    removeSetups(obsoleteSetups, confirm: false);

    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
  }

  Future<void> removeSetup(Setup toRemoveSetup) async {
    removeSetups([toRemoveSetup]);
  }

  Future<void> removeSetups(List<Setup> toRemoveSetups, {bool confirm = true}) async {
    if (toRemoveSetups.isEmpty) return;

    if (confirm) {
      final confirmed = await showConfirmationDialog(context);
      if (!confirmed) return;
    }

    setState(() {
      for (var setup in toRemoveSetups) {
        setups.remove(setup);

        // Also ensure components don't hold dangling references
        for (var c in components) {
          if (c.currentSetup == setup) {
            c.currentSetup = null;
          }
        }
      }
      determineCurrentSetups();
      determinePreviousSetups();
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
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
        components.remove(component);
      }
    });

    await FileExport.saveData(
      bikes: bikes,
      setups: setups,
      components: components,
    );
  }
  
  Future<void> addBike() async {
    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => const BikePage()),
    );
    if (bike == null) return;
  
    setState(() {
      bikes.add(bike);
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
  }

  Future<void> _addComponent() async {
    if (bikes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Add a bike first"), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    final component = await Navigator.push<Component>(
      context,
      MaterialPageRoute(builder: (context) => ComponentPage(bikes: filteredBikes)),
    );
    if (component == null) return;
  
    setState(() {
      components.add(component);
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
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
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
  }

  Future<void> editComponent(Component component) async {
    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage(component: component, bikes: filteredBikes),
      ),
    );
    if (editedComponent == null) {
      setState(() {}); // update adjustments
      return;
    }

    setState(() {
      final index = components.indexOf(component);
      if (index != -1) {
        components[index] = editedComponent;
      }
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
  }

  Future<void> duplicateComponent(Component component) async {
    final newComponent = component.deepCopy();
    setState(() {
      components.add(newComponent);
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
    editComponent(newComponent);
  }

  Future<void> onReorderComponents(int oldIndex, int newIndex) async {
    if (_selectedBike != null) {
      final filteredComponents = components.where((c) => c.bike == _selectedBike).toList();
      final componentToMove = filteredComponents[oldIndex];
      oldIndex = components.indexOf(componentToMove);
      final targetComponent = newIndex < filteredComponents.length
          ? filteredComponents[newIndex]
          : null;
      newIndex = targetComponent == null
          ? components.length 
          : components.indexOf(targetComponent);
    }

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) {
      adjustedNewIndex -= 1;
    }

    setState(() {
      final component = components.removeAt(oldIndex);
      components.insert(adjustedNewIndex, component);
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
  }

  Future<void> onReorderBikes(int oldIndex, int newIndex) async {
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) {
      adjustedNewIndex -= 1;
    }

    setState(() {
      final bike = bikes.removeAt(oldIndex);
      bikes.insert(adjustedNewIndex, bike);
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
  }

  Future<void> _addSetup() async {
    if (bikes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Add a bike first"), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (components.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Add a component first"), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage(components: components, bikes: filteredBikes)),
    );
    if (newSetup == null) return;
    
    setState(() {
      setups.add(newSetup);
      setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      determineCurrentSetups();
      determinePreviousSetups();
      updateSetupsAfter(newSetup);
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);
  }

  Future<void> editSetup(Setup setup) async {
    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupPage(setup: setup, components: components, bikes: filteredBikes),
      ),
    );
    if (editedSetup != null) {
      setState(() {
        final index = setups.indexOf(setup);
        if (index != -1) {
          setups[index] = editedSetup;
        }
        setups.sort((a, b) => a.datetime.compareTo(b.datetime));
        determineCurrentSetups();
        determinePreviousSetups();
        updateSetupsAfter(editedSetup);
      });
      await FileExport.saveData(bikes: bikes, setups: setups, components: components);
    }
  }

  Future<void> restoreSetup(Setup setup) async {
    final newSetup = Setup(
      name: setup.name, 
      bike: setup.bike,
      datetime: DateTime.now(),
      adjustmentValues: setup.adjustmentValues,
      isCurrent: true,
    );  //FIXME: Location and waether data is null --> maybe add default constructor?

    setState(() {
      setups.add(newSetup);
      setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      determineCurrentSetups();
      determinePreviousSetups();
    });
    await FileExport.saveData(bikes: bikes, setups: setups, components: components);

    editSetup(newSetup);
  }

  Future<void> determineCurrentSetups() async {
    for (final setup in setups) {
      setup.isCurrent = false;
    }
    final remainingBikes = Set.of(bikes);
    for (final setup in setups.reversed) {
      final bike = setup.bike;
      if (remainingBikes.contains(bike)) {
        setup.isCurrent = true;
        for (final component in components.where((c) => c.bike == bike)) {
          component.currentSetup = setup;
        }
        remainingBikes.remove(bike);
        if (remainingBikes.isEmpty) break;
      }
    }
  }

  Future<void> determinePreviousSetups() async {
    Map<Bike, Setup> previousSetups = {}; 
    for (final setup in setups) {
      final bike = setup.bike;
      final previousSetup = previousSetups[bike];
      if (previousSetup == null) {
        setup.previousSetup = null;
      } else {
        setup.previousSetup = previousSetup;
      }
      previousSetups[bike] = setup;
    }
  }

  Future<void> updateSetupsAfter(Setup setup) async {
    // Call after sorting setups!
    // Handles case: New Component, New Setup with new component with date in the past
    // --> Bug: component references current setup with missing values for new component
    if (setup.isCurrent) return;
    final index = setups.indexOf(setup);
    if (index == -1) return;
    if (index == setups.length -1) return; // ==isCurrent
    final afterSetups = setups.sublist(index + 1);
    final afterBikeSetups = afterSetups.where((s) => s.bike == setup.bike);
    for (final adjustmentValue in setup.adjustmentValues.entries) {
      final adjustment = adjustmentValue.key;
      final value = adjustmentValue.value;
      for (final afterBikeSetup in afterBikeSetups) {
        if (afterBikeSetup.adjustmentValues.containsKey(adjustment)) continue;
        afterBikeSetup.adjustmentValues[adjustment] = value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredComponents = _selectedBike == null
        ? components
        : components.where((c) => c.bike == _selectedBike).toList();
    final filteredSetups = _selectedBike == null
        ? setups
        : setups.where((s) => s.bike == _selectedBike).toList();
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            height: 30, 
            width: 30,
            child: ClipOval(
              child: Image.asset(
                'assets/icons/logo_1024.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: Text(
          widget.title, 
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'import':
                  loadJsonFileData();
                  break;
                case 'export':
                  FileExport.downloadJson(
                    context: context,
                    bikes: bikes,
                    setups: setups,
                    components: components,
                  );
                  break;
                case 'share':
                  FileExport.shareJson(
                    context: context,
                    bikes: bikes,
                    setups: setups,
                    components: components,
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Import Data'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Data'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Bikes", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 20),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                onPressed: addBike,
              ),
            ]
          ),

          BikeList(bikes: bikes, selectedBike: _selectedBike, onBikeTap: onBikeTap, editBike: editBike, removeBike: removeBike, onReorderBikes: onReorderBikes),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Components", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 20),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                onPressed: _addComponent,
                tooltip: 'Add Component',
              ),
            ]
          ),

          ComponentList(
            components: filteredComponents,
            setups: setups,
            editComponent: editComponent,
            duplicateComponent: duplicateComponent,
            removeComponent: removeComponent,
            onReorder: onReorderComponents,
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Setup History", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 20),
              FilterChip(
                label: const Text("Only Changes"),
                selected: _displayOnlyChanges,
                onSelected: (bool selected) {
                  setState(() {
                    _displayOnlyChanges = selected;
                  });
                },
              ),
              const SizedBox(width: 20),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                onPressed: _addSetup,
                tooltip: 'Add Setup',
              ),
            ]
          ),

          SetupList(
            setups: filteredSetups,
            components: components,
            editSetup: editSetup,
            restoreSetup: restoreSetup,
            removeSetup: removeSetup,
            displayOnlyChanges: _displayOnlyChanges,
          ),

          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "addSetup",
        onPressed: _addSetup,
        label: const Text('Add Setup'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
