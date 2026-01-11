import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../models/setup.dart';
import '../models/component.dart';
import '../models/app_settings.dart';
import 'bike_page.dart';
import 'component_page.dart';
import 'setup_page.dart';
import 'trash_page.dart';
import 'app_settings_page.dart';
import 'about_page.dart';
import 'backup_page.dart';
import '../utils/data.dart';
import '../utils/backup.dart';
import '../utils/file_export.dart';
import '../utils/file_import.dart';
import '../widgets/bike_list.dart';
import '../widgets/component_list.dart';
import '../widgets/setup_list.dart';
import '../widgets/dialogs/confirmation.dart';
import '../widgets/sheets/import_merge_overwrite.dart';
import '../widgets/sheets/import.dart';
import '../widgets/sheets/export.dart';
import '../widgets/sheets/bike_filter.dart';
import '../widgets/google_drive_sync_button.dart';
import '../services/google_drive_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _localDataLoaded = false;

  final Map<String, Bike> bikes = {};
  final List<Setup> setups = [];
  final List<Component> components = [];

  Bike? _selectedBike;
  Map<String, Bike> filteredBikes = {};

  bool _displayOnlyChanges = false;

  int currentPageIndex = 0;

  late GoogleDriveService _googleDriveService;

  void onBikeTap(Bike? bike) {
    setState(() {
      _selectedBike = (bike == null || _selectedBike == bike) 
          ? null 
          : _selectedBike = bike;
      filteredBikes = _selectedBike == null 
          ? Map.fromEntries(bikes.entries.where((entry) => !entry.value.isDeleted))
          : Map.fromEntries(bikes.entries.where((entry) => !entry.value.isDeleted && entry.value == _selectedBike));
    });
  }

  @override
  void initState() {
    super.initState();

    _googleDriveService = GoogleDriveService(
      getDataToUpload: () {
        return {
          'bikes': bikes.values.map((b) => b.toJson()).toList(),
          'setups': setups.map((s) => s.toJson()).toList(),
          'components': components.map((c) => c.toJson()).toList(),
        };
      },
      onDataDownloaded: (Data remoteData) {
        setState(() {
          FileImport.merge(remoteData: remoteData, localBikes: bikes, localSetups: setups, localComponents: components);
          if (!bikes.values.contains(_selectedBike)) onBikeTap(null);
        });
      },
    );
    if (context.read<AppSettings>().enableGoogleDrive) _googleDriveService.silentSetup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_localDataLoaded) {
      loadData();
      _localDataLoaded = true;
    }
  }

  Future<void> loadData() async {
    final data = await FileImport.readData(context);
    if (data == null) return;

    if (!mounted) return;
    setState(() {
      FileImport.overwrite(remoteData: data, localBikes: bikes, localSetups: setups, localComponents: components);
      onBikeTap(null);
    });
    FileImport.cleanupIsDeleted(bikes: bikes, components: components, setups: setups);
    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    FileExport.deleteOldBackups();
    // Google Drive is synced in init
  }

  Future<void> _importData() async {
    final importChoice = await showImportSheet(context);

    if (!mounted) return;
    Data? remoteData;
    switch (importChoice) {
      case "file":
        remoteData = await FileImport.readJsonFileData(context);
      case "backup":
        final backup = await Navigator.push<Backup?>(context, MaterialPageRoute(builder: (context) => BackupPage(googleDriveService: (mounted && context.read<AppSettings>().enableGoogleDrive) ? _googleDriveService : null)));
        if (backup == null) return;
        if (!mounted) return;

        switch (backup) {
          case LocalBackup(): remoteData = await FileImport.readBackup(context: context, path: backup.filepath);
          case GoogleDriveBackup(): remoteData = await _googleDriveService.readBackup(context: context, fileId: backup.fileId);
        }
      default:
        debugPrint("showImportSheet canceled");
        return;
    }

    if (remoteData == null) return;

    if (!mounted) return;
    final mergeOverwriteChoice = await showImportMergeOverwriteSheet(context);

    switch (mergeOverwriteChoice) {
      case 'overwrite':
        setState(() {
          FileImport.overwrite(remoteData: remoteData!, localBikes: bikes, localSetups: setups, localComponents: components);
          onBikeTap(null);
        });
      case 'merge':
        setState(() {
          FileImport.merge(remoteData: remoteData!, localBikes: bikes, localSetups: setups, localComponents: components);
        });
      default:
        debugPrint("showImportMergeOverwriteSheet canceled");
        return;
    }

    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: false,
        showCloseIcon: true,
        content: Text(mergeOverwriteChoice == 'overwrite'
          ? 'Data overwritten successfully'
          : 'Data merged successfully'
        )),
    );
  }

  Future<void> _exportData() async {
    final choice = await showExportSheet(context: context);
    
    if (!mounted) return;
    switch (choice) {
      case "file":
        await FileExport.downloadJson(
          context: context,
          bikes: bikes,
          setups: setups,
          components: components,
        );
      case "backup":
        await FileExport.saveBackup(context: context, bikes: bikes, setups: setups, components: components, force: true);
      case "googleDriveBackup":
        await _googleDriveService.saveBackup(context: context, force: true);
      default:
        debugPrint("showExportSheet canceled.");
        return;
    }
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
    final confirmed = await showConfirmationDialog(context, content: "All components and setups which belong to this bike will be deleted as well.");
    if (!confirmed) return;

    final obsoleteComponents = components.where((c) => c.bike == bike.id).toList();
    final obsoleteSetups = setups.where((s) => s.bike == bike.id).toList();

    setState(() {
      bike.isDeleted = true;
      bike.lastModified = DateTime.now();
      onBikeTap(null);
    });

    removeComponents(obsoleteComponents, confirm: false);
    removeSetups(obsoleteSetups, confirm: false);

    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> removeSetup(Setup toRemoveSetup) async {
    removeSetups([toRemoveSetup]);
  }

  Future<void> removeSetups(List<Setup> toRemoveSetups, {bool confirm = true}) async {
    if (toRemoveSetups.isEmpty) return;

    setState(() {
      for (var setup in toRemoveSetups) {
        setup.isDeleted = true;
        setup.lastModified = DateTime.now();
      }
      FileImport.determineCurrentSetups(setups: setups, bikes: bikes);
      FileImport.determinePreviousSetups(setups: setups);
    });

    if (confirm) {
      final snackBar = SnackBar(
        content: Text(Intl.plural(
          toRemoveSetups.length,
          zero: "No setup moved to trash.",
          one: "One setup moved to trash.",
          other: '${toRemoveSetups.length} setups moved to trash.',
        )),
        duration: const Duration(seconds: 5),
        persist: false,
        showCloseIcon: true,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              for (var setup in toRemoveSetups) {
                setup.isDeleted = false;
                setup.lastModified = DateTime.now();
              }
              setups.sort((a, b) => a.datetime.compareTo(b.datetime)); // not really necessary
              FileImport.determineCurrentSetups(setups: setups, bikes: bikes);
              FileImport.determinePreviousSetups(setups: setups);
            });
          },
        ),
      );

      final SnackBarClosedReason reason = await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
      if (reason == SnackBarClosedReason.action) return; // Not save and sync
    }

    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> removeComponent(Component toRemoveComponent) async {
    removeComponents([toRemoveComponent]);
  }

  Future<void> removeComponents(List<Component> toRemoveComponents, {bool confirm = true}) async {
    if (toRemoveComponents.isEmpty) return;

    setState(() {
      for (var component in toRemoveComponents) {
        component.isDeleted = true;
        component.lastModified = DateTime.now();
      }
    });

    if (confirm) {
      final snackBar = SnackBar(
        content: Text(Intl.plural(
          toRemoveComponents.length,
          zero: "No components moved to trash.",
          one: "One component moved to trash.",
          other: '${toRemoveComponents.length} components moved to trash.',
        )),
        duration: const Duration(seconds: 5),
        persist: false,
        showCloseIcon: true,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              for (var setup in toRemoveComponents) {
                setup.isDeleted = false;
                setup.lastModified = DateTime.now();
              }
            });
          },
        ),
      );

      final SnackBarClosedReason reason = await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
      if (reason == SnackBarClosedReason.action) return; // Not save and sync
    }

    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }
  
  Future<void> addBike() async {
    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => const BikePage()),
    );
    if (bike == null) return;
  
    setState(() {
      bikes[bike.id] = bike;
      if (_selectedBike == null) onBikeTap(null);
    });
    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addComponent() async {
    if (filteredBikes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text("Add a bike first", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
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

    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
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
      bikes[editedBike.id] = editedBike;
    });
    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
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
    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> duplicateComponent(Component component) async {
    final newComponent = component.deepCopy();
    setState(() {
      components.add(newComponent);
    });
    editComponent(newComponent);
  }

  Future<void> onReorderComponents(int oldIndex, int newIndex) async {
    // Applies reorder to 'components' on the basis of filtered components
    final filteredComponents = components.where((c) => c.bike == (_selectedBike?.id ?? c.bike) && !c.isDeleted).toList();
    final componentToMove = filteredComponents[oldIndex];
    oldIndex = components.indexOf(componentToMove);
    final targetComponent = newIndex < filteredComponents.length
        ? filteredComponents[newIndex]
        : null;
    newIndex = targetComponent == null
        ? components.length 
        : components.indexOf(targetComponent);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    setState(() {
      final component = components.removeAt(oldIndex);
      components.insert(adjustedNewIndex, component);
    });
    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> onReorderBikes(int oldIndex, int newIndex) async {
    // Applies reorder to 'bikes' on the basis of filtered bikes
    final bikesList = bikes.values.toList();
    
    final filteredBikes = bikesList.where((b) => !b.isDeleted).toList();
    final bikeToMove = filteredBikes[oldIndex];
    oldIndex = bikesList.indexOf(bikeToMove);
    final targetBike = newIndex < filteredBikes.length
        ? filteredBikes[newIndex]
        : null;
    newIndex = targetBike == null
        ? bikes.length 
        : bikesList.indexOf(targetBike);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final bike = bikesList.removeAt(oldIndex);
    bikesList.insert(adjustedNewIndex, bike);

    setState(() {
      bikes.clear();
      bikes.addAll({for (var element in bikesList) element.id : element});
      onBikeTap(null);
    });
    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addSetup() async {
    if (bikes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true, 
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text("Add a bike first", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      return;
    }
    if (components.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true, 
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text("Add a component first", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      return;
    }

    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage(components: components.where((c) => !c.isDeleted).toList(), bikes: filteredBikes, getPreviousSetupbyDateTime: getPreviousSetupbyDateTime,)),
    );
    if (newSetup == null) return;
    
    setState(() {
      setups.add(newSetup);
      setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      FileImport.determineCurrentSetups(setups: setups, bikes: bikes);
      FileImport.determinePreviousSetups(setups: setups);
      FileImport.updateSetupsAfter(setups: setups, setup: newSetup);
    });
    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> editSetup(Setup setup) async {
    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupPage(setup: setup, components: components.where((c) => !c.isDeleted).toList(), bikes: filteredBikes, getPreviousSetupbyDateTime: getPreviousSetupbyDateTime,),
      ),
    );
    if (editedSetup == null) return;

    setState(() {
      final index = setups.indexOf(setup);
      if (index != -1) {
        setups[index] = editedSetup;
      }
      setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      FileImport.determineCurrentSetups(setups: setups, bikes: bikes);
      FileImport.determinePreviousSetups(setups: setups);
      FileImport.updateSetupsAfter(setups: setups, setup: editedSetup);
    });
    FileExport.saveData(bikes: bikes, setups: setups, components: components);
    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> restoreSetup(Setup setup) async {
    final newSetup = Setup(
      name: setup.name, 
      bike: setup.bike,
      datetime: DateTime.now(),
      adjustmentValues: setup.adjustmentValues,
      isCurrent: true,
    );  //TODO: Location and waether data is null --> maybe add default constructor?

    setState(() {
      setups.add(newSetup);
      setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      FileImport.determineCurrentSetups(setups: setups, bikes: bikes);
      FileImport.determinePreviousSetups(setups: setups);
    });
    editSetup(newSetup);
  }

  Setup? getPreviousSetupbyDateTime({required DateTime datetime, required String bike}) {
    return setups.lastWhereOrNull((s) => !s.isDeleted && s.datetime.isBefore(datetime) && s.bike == bike);
  }

  FilterChip _bikeFilterWidget() {
    return FilterChip(
      avatar: Icon(Icons.pedal_bike),
      label: _selectedBike == null ? const Text("All Bikes") : Text(_selectedBike!.name),
      selected: _selectedBike != null,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        final List<Bike>? newSelectedBikes = await showBikeFilterSheet(
          context: context,
          bikes: bikes.values.where((b) => !b.isDeleted),
          selectedBike: _selectedBike,
        );
        if (newSelectedBikes == null) return;
        if (newSelectedBikes.isEmpty) {
          onBikeTap(null);
        } else if (newSelectedBikes[0] != _selectedBike) {
          onBikeTap(newSelectedBikes[0]);
        }
      },
      onDeleted: _selectedBike == null 
          ? null 
          : () => onBikeTap(null),
    );
  }

  SingleChildScrollView _bikeListFilterWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12,
        children: [
          _bikeFilterWidget(),
        ],
      ),
    );
  }

  SingleChildScrollView _componentListFilterWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12,
        children: [
          _bikeFilterWidget(),
        ],
      ),
    );
  }

  SingleChildScrollView _setupListFilterWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12,
        children: [
          _bikeFilterWidget(),
          FilterChip(
            label: const Text("Only Changes"),
            selected: _displayOnlyChanges,
            onSelected: (bool selected) {
              setState(() {
                _displayOnlyChanges = selected;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredComponents = _selectedBike == null
        ? components.where((c) => !c.isDeleted).toList()
        : components.where((c) => !c.isDeleted && c.bike == _selectedBike?.id).toList();
    final filteredSetups = _selectedBike == null
        ? setups.where((s) => !s.isDeleted).toList()
        : setups.where((s) => !s.isDeleted && s.bike == _selectedBike?.id).toList();
    final appSettings = context.watch<AppSettings>();
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
        title: <Text>[
          const Text("Bikes"),
          const Text("Components"),
          const Text("Setup History"),
        ][currentPageIndex],
        actions: [
          if (appSettings.enableGoogleDrive)
            GoogleDriveSyncButton(googleDriveService: _googleDriveService),
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'import':
                  _importData();
                  break;
                case 'export':
                  _exportData();
                  break;
                case 'share':
                  FileExport.shareJson(
                    context: context,
                    bikes: bikes,
                    setups: setups,
                    components: components,
                  );
                  break;
                case "trash":
                  Navigator.push<void>(context, MaterialPageRoute(builder: (context) => TrashPage(bikes: bikes, components: components, setups: setups))).then((_) {
                    setState(() {
                      setups.sort((a, b) => a.datetime.compareTo(b.datetime));
                      FileImport.determineCurrentSetups(setups: setups, bikes: bikes);
                      FileImport.determinePreviousSetups(setups: setups);
                      for (final setup in setups) {
                        FileImport.updateSetupsAfter(setups: setups, setup: setup);
                      }
                    });
                    FileExport.saveData(bikes: bikes, setups: setups, components: components);
                    FileExport.saveBackup(bikes: bikes, setups: setups, components: components);
                    if (appSettings.enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
                  });
                  break;
                case "settings":
                  final tmpEnableGoogleDrive = context.read<AppSettings>().enableGoogleDrive;
                  Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AppSettingsPage()))
                    .then((_) {
                      final newEnable = appSettings.enableGoogleDrive;
                      if (newEnable && !tmpEnableGoogleDrive) _googleDriveService.silentSetup();
                    });
                case "about":
                  Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AboutPage()));
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
              const PopupMenuItem<String>(
                value: "trash",
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Trash'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: <Widget>[
          NavigationDestination(icon: Badge(isLabelVisible: _selectedBike != null, backgroundColor: Theme.of(context).primaryColor, child: Icon(Icons.pedal_bike)), label: 'Bikes'),
          NavigationDestination(icon: Icon(Icons.grid_view_sharp), label: 'Components', enabled: bikes.isNotEmpty),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Setups', enabled: filteredComponents.isNotEmpty && bikes.isNotEmpty),
        ],
      ),
      body: <Widget>[
        BikeList(
          bikes: bikes.values.where((bike) => !bike.isDeleted).toList(), //include bikes which are not filtered for
          selectedBike: _selectedBike,
          onBikeTap: onBikeTap,
          editBike: editBike,
          removeBike: removeBike,
          onReorderBikes: onReorderBikes,
          filterWidget: _bikeListFilterWidget(),
        ),
        ComponentList(
          bikes: filteredBikes,
          components: filteredComponents,
          setups: setups,
          editComponent: editComponent,
          duplicateComponent: duplicateComponent,
          removeComponent: removeComponent,
          onReorder: onReorderComponents,
          filterWidget: _componentListFilterWidget(),
        ),
        SetupList(
          bikes: filteredBikes,
          setups: filteredSetups,
          components: filteredComponents,
          editSetup: editSetup,
          restoreSetup: restoreSetup,
          removeSetup: removeSetup,
          displayOnlyChanges: _displayOnlyChanges,
          filterWidget: _setupListFilterWidget(),
        ),
      ][currentPageIndex],
      floatingActionButton: <Widget>[
        FloatingActionButton(
          heroTag: "addBike",
          onPressed: addBike,
          tooltip: 'Add Bike',
          child: const Icon(Icons.add),
        ),
        FloatingActionButton(
          heroTag: "addComponent",
          onPressed: _addComponent,
          tooltip: 'Add Component',
          child: const Icon(Icons.add),
        ),
        FloatingActionButton(
          heroTag: "addSetup",
          onPressed: _addSetup,
          tooltip: 'Add Setup',
          child: const Icon(Icons.add),
        ),
      ][currentPageIndex],
    );
  }
}
