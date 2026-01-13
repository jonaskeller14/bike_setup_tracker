import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/rating.dart';
import '../models/setup.dart';
import '../models/component.dart';
import '../models/app_settings.dart';
import '../models/data.dart';
import 'bike_page.dart';
import 'component_page.dart';
import 'setup_page.dart';
import 'person_page.dart';
import 'rating_page.dart';
import 'trash_page.dart';
import 'app_settings_page.dart';
import 'about_page.dart';
import 'backup_page.dart';
import '../utils/backup.dart';
import '../utils/file_export.dart';
import '../utils/file_import.dart';
import '../widgets/person_list.dart';
import '../widgets/rating_list.dart';
import '../widgets/bike_list.dart';
import '../widgets/component_list.dart';
import '../widgets/setup_list.dart';
import '../widgets/dialogs/confirmation.dart';
import '../widgets/sheets/import_merge_overwrite.dart';
import '../widgets/sheets/import.dart';
import '../widgets/sheets/export.dart';
import '../widgets/sheets/bike_filter.dart';
import '../widgets/sheets/data_select.dart';
import '../widgets/google_drive_sync_button.dart';
import '../services/google_drive_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _localDataLoaded = false;

  final Data data = Data(
    persons: {},
    bikes: {},
    setups: [],
    components: [],
    ratings: {},
  );

  bool _setupListOnlyChanges = false;
  bool _setupListBikeAdjustmentValues = true;
  bool _setupListPersonAdjustmentValues = false;
  bool _setupListRatingAdjustmentValues = false;

  int currentPageIndex = 0;

  late GoogleDriveService _googleDriveService;

  @override
  void initState() {
    super.initState();

    _googleDriveService = GoogleDriveService(
      getDataToUpload: () => data.toJson(),
      onDataDownloaded: (Data remoteData) {
        setState(() {
          FileImport.merge(remoteData: remoteData, localData: data);
          if (!data.bikes.values.contains(data.selectedBike)) data.onBikeTap(null);
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
    final remoteData = await FileImport.readData(context);
    if (remoteData == null) return;

    if (!mounted) return;
    setState(() {
      FileImport.overwrite(remoteData: remoteData, localData: data);
      data.onBikeTap(null);
      data.filteredPersons = Map.fromEntries(data.persons.entries.where((entry) => !entry.value.isDeleted));
      data.filteredRatings = Map.fromEntries(data.ratings.entries.where((entry) => !entry.value.isDeleted));
    });
    FileImport.cleanupIsDeleted(data: data);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
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
    final selectedRemoteData = await showDataSelectSheet(context: context, data: remoteData);
    if (selectedRemoteData == null) return;

    if (!mounted) return;
    final mergeOverwriteChoice = await showImportMergeOverwriteSheet(context);
    switch (mergeOverwriteChoice) {
      case 'overwrite':
        setState(() {
          FileImport.overwrite(remoteData: remoteData!, localData: data);
          data.onBikeTap(null);
        });
      case 'merge':
        setState(() {
          FileImport.merge(remoteData: remoteData!, localData: data);
        });
      default:
        debugPrint("showImportMergeOverwriteSheet canceled");
        return;
    }

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
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
        final selectedData = await showDataSelectSheet(context: context, data: data);
        if (selectedData == null) return;

        if (!mounted) return;
        await FileExport.downloadJson(
          context: context,
          data: selectedData,
        );
      case "backup":
        await FileExport.saveBackup(context: context, data: data, force: true);
      case "googleDriveBackup":
        await _googleDriveService.saveBackup(context: context, force: true);
      default:
        debugPrint("showExportSheet canceled.");
        return;
    }
  }

  Future<void> _shareData() async {
    final selectedData = await showDataSelectSheet(context: context, data: data);    
    if (selectedData == null) return;
    
    if (!mounted) return;
    FileExport.shareJson(
      context: context,
      data: selectedData,
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
      data.setups.clear();
      data.components.clear();
    });
  }

  Future<void> removeBike(Bike bike) async {
    final confirmed = await showConfirmationDialog(context, content: "All components and setups which belong to this bike will be deleted as well.");
    if (!confirmed) return;

    final obsoleteComponents = data.components.where((c) => c.bike == bike.id).toList();
    final obsoleteSetups = data.setups.where((s) => s.bike == bike.id).toList();

    setState(() {
      bike.isDeleted = true;
      bike.lastModified = DateTime.now();
      data.onBikeTap(null);
    });

    removeComponents(obsoleteComponents, confirm: false);
    removeSetups(obsoleteSetups, confirm: false);

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _removePerson(Person person) async {
    setState(() {
      person.isDeleted = true;
      person.lastModified = DateTime.now();
      data.filteredPersons = Map.fromEntries(data.persons.entries.where((entry) => !entry.value.isDeleted));
    });

    final snackBar = SnackBar(
      content: Text("Person '${person.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          setState(() {
            person.isDeleted = false;
            person.lastModified = DateTime.now();
            data.filteredPersons = Map.fromEntries(data.persons.entries.where((entry) => !entry.value.isDeleted));
          });
        },
      ),
    );

    final SnackBarClosedReason reason = await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
    if (reason == SnackBarClosedReason.action) return; // Not save and sync

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _removeRating(Rating rating) async {
    setState(() {
      rating.isDeleted = true;
      rating.lastModified = DateTime.now();
      data.filteredRatings = Map.fromEntries(data.ratings.entries.where((entry) => !entry.value.isDeleted));
    });

    final snackBar = SnackBar(
      content: Text("Rating '${rating.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          setState(() {
            rating.isDeleted = false;
            rating.lastModified = DateTime.now();
            data.filteredRatings = Map.fromEntries(data.ratings.entries.where((entry) => !entry.value.isDeleted));
          });
        },
      ),
    );

    final SnackBarClosedReason reason = await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
    if (reason == SnackBarClosedReason.action) return; // Not save and sync

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
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
      FileImport.determineCurrentSetups(setups: data.setups, bikes: data.bikes);
      FileImport.determinePreviousSetups(setups: data.setups);
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
              data.setups.sort((a, b) => a.datetime.compareTo(b.datetime)); // not really necessary
              FileImport.determineCurrentSetups(setups: data.setups, bikes: data.bikes);
              FileImport.determinePreviousSetups(setups: data.setups);
            });
          },
        ),
      );

      final SnackBarClosedReason reason = await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
      if (reason == SnackBarClosedReason.action) return; // Not save and sync
    }

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
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
              for (var component in toRemoveComponents) {
                component.isDeleted = false;
                component.lastModified = DateTime.now();
              }
            });
          },
        ),
      );

      final SnackBarClosedReason reason = await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
      if (reason == SnackBarClosedReason.action) return; // Not save and sync
    }

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }
  
  Future<void> addBike() async {
    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => BikePage(persons: data.filteredPersons)),
    );
    if (bike == null) return;
  
    setState(() {
      data.bikes[bike.id] = bike;
      if (data.selectedBike == null) data.onBikeTap(null);
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addPerson() async {
    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (context) => const PersonPage()),
    );
    if (person == null) return;
  
    setState(() {
      data.persons[person.id] = person;
      data.filteredPersons = Map.fromEntries(data.persons.entries.where((entry) => !entry.value.isDeleted));
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addRating() async {
    final newRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage(
          bikes: Map.fromEntries(data.bikes.entries.where((entry) => !entry.value.isDeleted)),
          components: data.components.where((c) => !c.isDeleted).toList(),
          persons: data.filteredPersons,
        ),
      ),
    );
    if (newRating == null) return;
  
    setState(() {
      data.ratings[newRating.id] = newRating;
      data.filteredRatings = Map.fromEntries(data.ratings.entries.where((entry) => !entry.value.isDeleted));
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addComponent() async {
    if (data.filteredBikes.isEmpty) {
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
      MaterialPageRoute(builder: (context) => ComponentPage(bikes: data.filteredBikes)),
    );
    if (component == null) return;
  
    setState(() {
      data.components.add(component);
    });

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> editBike(Bike bike) async {
    final editedBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage(bike: bike, persons: data.filteredPersons),
      ),
    );
    if (editedBike == null) return;
    setState(() {
      data.bikes[editedBike.id] = editedBike;
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _editPerson(Person person) async {
    final editedPerson = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (context) => PersonPage(person: person),
      ),
    );
    if (editedPerson == null) return;
    setState(() {
      data.persons[editedPerson.id] = editedPerson;
      data.filteredPersons = Map.fromEntries(data.persons.entries.where((entry) => !entry.value.isDeleted));
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _editRating(Rating rating) async {
    final editedRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage(
          rating: rating, 
          bikes: Map.fromEntries(data.bikes.entries.where((entry) => !entry.value.isDeleted)),
          components: data.components.where((c) => !c.isDeleted).toList(),
          persons: data.filteredPersons,
        ),
      ),
    );
    if (editedRating == null) return;
    setState(() {
      data.ratings[editedRating.id] = editedRating;
      data.filteredRatings = Map.fromEntries(data.ratings.entries.where((entry) => !entry.value.isDeleted));
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> editComponent(Component component) async {
    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage(component: component, bikes: data.filteredBikes),
      ),
    );
    if (editedComponent == null) {
      setState(() {}); // update adjustments
      return;
    }

    setState(() {
      final index = data.components.indexOf(component);
      if (index != -1) {
        data.components[index] = editedComponent;
      }
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> duplicateComponent(Component component) async {
    final newComponent = component.deepCopy();
    setState(() {
      data.components.add(newComponent);
    });
    editComponent(newComponent);
  }

  Future<void> _duplicatePerson(Person person) async {
    final newPerson = person.deepCopy();
    setState(() {
      data.persons[newPerson.id] = newPerson;
      data.filteredPersons = Map.fromEntries(data.persons.entries.where((entry) => !entry.value.isDeleted));
    });
    _editPerson(newPerson);
  }

  Future<void> _duplicateRating(Rating rating) async {
    final newRating = rating.deepCopy();
    setState(() {
      data.ratings[newRating.id] = newRating;
      data.filteredRatings = Map.fromEntries(data.ratings.entries.where((entry) => !entry.value.isDeleted));
    });
    _editRating(newRating);
  }

  Future<void> onReorderComponents(int oldIndex, int newIndex) async {
    // Applies reorder to 'components' on the basis of filtered components
    final filteredComponents = data.components.where((c) => c.bike == (data.selectedBike?.id ?? c.bike) && !c.isDeleted).toList();
    final componentToMove = filteredComponents[oldIndex];
    oldIndex = data.components.indexOf(componentToMove);
    final targetComponent = newIndex < filteredComponents.length
        ? filteredComponents[newIndex]
        : null;
    newIndex = targetComponent == null
        ? data.components.length 
        : data.components.indexOf(targetComponent);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    setState(() {
      final component = data.components.removeAt(oldIndex);
      data.components.insert(adjustedNewIndex, component);
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> onReorderBikes(int oldIndex, int newIndex) async {
    // Applies reorder to 'bikes' on the basis of filtered bikes
    final bikesList = data.bikes.values.toList();
    
    final filteredBikes = bikesList.where((b) => !b.isDeleted).toList();
    final bikeToMove = filteredBikes[oldIndex];
    oldIndex = bikesList.indexOf(bikeToMove);
    final targetBike = newIndex < filteredBikes.length
        ? filteredBikes[newIndex]
        : null;
    newIndex = targetBike == null
        ? data.bikes.length 
        : bikesList.indexOf(targetBike);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final bike = bikesList.removeAt(oldIndex);
    bikesList.insert(adjustedNewIndex, bike);

    setState(() {
      data.bikes.clear();
      data.bikes.addAll({for (var element in bikesList) element.id : element});
      data.onBikeTap(null);
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _onReorderPerson(int oldIndex, int newIndex) async {
    final personsList = data.persons.values.toList();
    
    final filteredPersons2 = personsList.where((b) => !b.isDeleted).toList();
    final personToMove = filteredPersons2[oldIndex];
    oldIndex = personsList.indexOf(personToMove);
    final targetPerson = newIndex < filteredPersons2.length
        ? filteredPersons2[newIndex]
        : null;
    newIndex = targetPerson == null
        ? data.persons.length 
        : personsList.indexOf(targetPerson);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final person = personsList.removeAt(oldIndex);
    personsList.insert(adjustedNewIndex, person);

    setState(() {
      data.persons.clear();
      data.persons.addAll({for (var element in personsList) element.id : element});
      data.filteredPersons = Map.fromEntries(data.persons.entries.where((entry) => !entry.value.isDeleted));
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _onReorderRating(int oldIndex, int newIndex) async {
    final ratingsList = data.ratings.values.toList();
    
    final filteredRatings2 = ratingsList.where((b) => !b.isDeleted).toList();
    final ratingToMove = filteredRatings2[oldIndex];
    oldIndex = ratingsList.indexOf(ratingToMove);
    final targetRating = newIndex < filteredRatings2.length
        ? filteredRatings2[newIndex]
        : null;
    newIndex = targetRating == null
        ? data.ratings.length 
        : ratingsList.indexOf(targetRating);

    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) adjustedNewIndex -= 1;

    final rating = ratingsList.removeAt(oldIndex);
    ratingsList.insert(adjustedNewIndex, rating);

    setState(() {
      data.ratings.clear();
      data.ratings.addAll({for (var element in ratingsList) element.id : element});
      data.filteredRatings = Map.fromEntries(data.ratings.entries.where((entry) => !entry.value.isDeleted));
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addSetup() async {
    if (data.bikes.values.where((b) => !b.isDeleted).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true, 
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text("Add a bike first", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      return;
    }
    if (data.components.where((c) => !c.isDeleted).isEmpty) {
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
      MaterialPageRoute(builder: (context) => SetupPage(
        components: data.components.where((c) => !c.isDeleted).toList(), 
        bikes: data.filteredBikes, 
        persons: data.filteredPersons,
        ratings: data.filteredRatings,
        getPreviousSetupbyDateTime: getPreviousSetupbyDateTime,
      )),
    );
    if (newSetup == null) return;
    
    setState(() {
      data.setups.add(newSetup);
      data.setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      FileImport.determineCurrentSetups(setups: data.setups, bikes: data.bikes);
      FileImport.determinePreviousSetups(setups: data.setups);
      FileImport.updateSetupsAfter(setups: data.setups, setup: newSetup);
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> editSetup(Setup setup) async {
    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage(
          setup: setup, 
          components: data.components.where((c) => !c.isDeleted).toList(), 
          bikes: data.filteredBikes, 
          persons: data.filteredPersons, 
          ratings: data.filteredRatings,
          getPreviousSetupbyDateTime: getPreviousSetupbyDateTime,
      )),
    );
    if (editedSetup == null) return;

    setState(() {
      final index = data.setups.indexOf(setup);
      if (index != -1) {
        data.setups[index] = editedSetup;
      }
      data.setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      FileImport.determineCurrentSetups(setups: data.setups, bikes: data.bikes);
      FileImport.determinePreviousSetups(setups: data.setups);
      FileImport.updateSetupsAfter(setups: data.setups, setup: editedSetup);
    });
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> restoreSetup(Setup setup) async {
    final newSetup = Setup(
      name: setup.name, 
      bike: setup.bike,
      person: data.bikes[setup.bike]?.person,
      datetime: DateTime.now(),
      bikeAdjustmentValues: setup.bikeAdjustmentValues,
      personAdjustmentValues: setup.personAdjustmentValues, //FIXME: this could lead to dangling person adj-values if bike owner has changed in the meantime
      ratingAdjustmentValues: {},
      isCurrent: true,
    );  //TODO: Location and waether data is null --> maybe add default constructor?

    setState(() {
      data.setups.add(newSetup);
      data.setups.sort((a, b) => a.datetime.compareTo(b.datetime));
      FileImport.determineCurrentSetups(setups: data.setups, bikes: data.bikes);
      FileImport.determinePreviousSetups(setups: data.setups);
    });
    editSetup(newSetup);
  }

  Setup? getPreviousSetupbyDateTime({required DateTime datetime, String? bike, String? person}) {
    return data.setups.lastWhereOrNull((s) => !s.isDeleted && s.datetime.isBefore(datetime) && (bike == null || s.bike == bike) && (person == null || s.person == person));
  }

  FilterChip _bikeFilterWidget() {
    return FilterChip(
      avatar: const Icon(Bike.iconData),
      label: data.selectedBike == null ? const Text("All Bikes") : Text(data.selectedBike!.name),
      selected: data.selectedBike != null,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        final List<Bike>? newSelectedBikes = await showBikeFilterSheet(
          context: context,
          bikes: data.bikes.values.where((b) => !b.isDeleted),
          selectedBike: data.selectedBike,
        );
        if (newSelectedBikes == null) return;
        if (newSelectedBikes.isEmpty) {
          setState(() => data.onBikeTap(null));
        } else if (newSelectedBikes[0] != data.selectedBike) {
          setState(() => data.onBikeTap(newSelectedBikes[0]));
        }
      },
      onDeleted: data.selectedBike == null 
          ? null 
          : () => setState(() => data.onBikeTap(null)),
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

  SingleChildScrollView _setupListFilterWidget(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12,
        children: [
          _bikeFilterWidget(),
          FilterChip(
            label: const Text("Only Changes"),
            selected: _setupListOnlyChanges,
            onSelected: (bool selected) {setState(() => _setupListOnlyChanges = selected);},
            tooltip: "Show only changed values",
          ),
          if (context.read<AppSettings>().enablePerson || context.read<AppSettings>().enableRating)
          FilterChip(
            label: const Icon(Bike.iconData, size: 20),
            selected: _setupListBikeAdjustmentValues,
            onSelected: (bool selected) {setState(() => _setupListBikeAdjustmentValues = selected);},
            tooltip: "Show bike/component related values",
          ),
          if (context.read<AppSettings>().enablePerson)
            FilterChip(
              label: Icon(Icons.person, size: 20),
              selected: _setupListPersonAdjustmentValues,
              onSelected: (bool selected) {setState(() => _setupListPersonAdjustmentValues = selected);},
              tooltip: "Show person related values",
            ),
          if (context.read<AppSettings>().enableRating)
            FilterChip(
              label: Icon(Icons.star, size: 20),
              selected: _setupListRatingAdjustmentValues,
              onSelected: (bool selected) {setState(() => _setupListRatingAdjustmentValues = selected);},
              tooltip: "Show rating related values",
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredComponents = data.selectedBike == null
        ? data.components.where((c) => !c.isDeleted).toList()
        : data.components.where((c) => !c.isDeleted && c.bike == data.selectedBike?.id).toList();
    final filteredSetups = data.selectedBike == null
        ? data.setups.where((s) => !s.isDeleted).toList()
        : data.setups.where((s) => !s.isDeleted && s.bike == data.selectedBike?.id).toList();
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
          if (appSettings.enablePerson)
            const Text("Profile"),
          if (appSettings.enableRating)
            const Text("Ratings"),
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
                  _shareData();
                  break;
                case "trash":
                  Navigator.push<void>(context, MaterialPageRoute(builder: (context) => TrashPage(
                    persons: data.persons, 
                    bikes: data.bikes, 
                    components: data.components, 
                    setups: data.setups,
                    ratings: data.ratings,
                    onChanged: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) { // Called when HomePage is not locked anymore
                        if (!mounted) return;
                        setState(() {
                          data.setups.sort((a, b) => a.datetime.compareTo(b.datetime));
                          FileImport.determineCurrentSetups(setups: data.setups, bikes: data.bikes);
                          FileImport.determinePreviousSetups(setups: data.setups);
                          for (final setup in data.setups) {
                            FileImport.updateSetupsAfter(setups: data.setups, setup: setup);
                          }
                          data.filteredPersons = Map.fromEntries(data.persons.entries.where((entry) => !entry.value.isDeleted));
                          data.filteredRatings = Map.fromEntries(data.ratings.entries.where((entry) => !entry.value.isDeleted));
                        });
                        FileExport.saveData(data: data);
                        FileExport.saveBackup(data: data);
                        if (mounted && appSettings.enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
                      });
                    }
                  )));
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
          NavigationDestination(icon: Badge(isLabelVisible: data.selectedBike != null, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Bike.iconData)), label: 'Bikes'),
          NavigationDestination(icon: Icon(Icons.grid_view_sharp), label: 'Components'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Setups'),
          if (appSettings.enablePerson)
            NavigationDestination(icon: const Icon(Icons.person), label: "Profile"),
          if (appSettings.enableRating)
            NavigationDestination(icon: const Icon(Icons.star), label: "Ratings"),
        ],
      ),
      body: <Widget>[
        BikeList(
          bikes: data.bikes.values.where((bike) => !bike.isDeleted).toList(), //include bikes which are not filtered for
          persons: data.filteredPersons,
          selectedBike: data.selectedBike,
          onBikeTap: (Bike? bike) {setState(() => data.onBikeTap(bike));},
          editBike: editBike,
          removeBike: removeBike,
          onReorderBikes: onReorderBikes,
          filterWidget: _bikeListFilterWidget(),
        ),
        ComponentList(
          bikes: data.filteredBikes,
          components: filteredComponents,
          setups: data.setups,
          editComponent: editComponent,
          duplicateComponent: duplicateComponent,
          removeComponent: removeComponent,
          onReorder: onReorderComponents,
          filterWidget: _componentListFilterWidget(),
        ),
        SetupList(
          persons: data.filteredPersons,
          ratings: data.filteredRatings,
          bikes: data.filteredBikes,
          setups: filteredSetups,
          components: filteredComponents,
          editSetup: editSetup,
          restoreSetup: restoreSetup,
          removeSetup: removeSetup,
          displayOnlyChanges: _setupListOnlyChanges,
          displayBikeAdjustmentValues: _setupListBikeAdjustmentValues,
          displayPersonAdjustmentValues: _setupListPersonAdjustmentValues,
          displayRatingAdjustmentValues: _setupListRatingAdjustmentValues,
          filterWidget: _setupListFilterWidget(context),
        ),
        if (context.read<AppSettings>().enablePerson)
          PersonList(
            bikes: Map.fromEntries(data.bikes.entries.where((entry) => !entry.value.isDeleted)),
            persons: data.filteredPersons,
            setups: data.setups.where((s) => !s.isDeleted).toList(),
            editPerson: _editPerson,
            duplicatePerson: _duplicatePerson,
            removePerson: _removePerson,
            onReorderPerson: _onReorderPerson,
          ),
        if (context.read<AppSettings>().enableRating)
          RatingList(
            persons: data.filteredPersons,
            bikes: data.filteredBikes,
            components: data.components.where((c) => !c.isDeleted).toList(),
            ratings: data.filteredRatings,
            editRating: _editRating,
            duplicateRating: _duplicateRating,
            removeRating: _removeRating,
            onReorderRating: _onReorderRating,
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
        if (appSettings.enablePerson)
          FloatingActionButton(
            heroTag: "addPerson",
            onPressed: _addPerson,
            tooltip: 'Add Person',
            child: const Icon(Icons.add),
          ),
        if (appSettings.enableRating)
          FloatingActionButton(
            heroTag: "addRating",
            onPressed: _addRating,
            tooltip: 'Add Rating',
            child: const Icon(Icons.add),
          ),
      ][currentPageIndex],
    );
  }
}
