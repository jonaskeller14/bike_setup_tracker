import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/rating.dart';
import '../models/setup.dart';
import '../models/component.dart';
import '../models/app_settings.dart';
import '../models/app_data.dart';
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
  bool _setupListOnlyChanges = false;
  bool _setupListBikeAdjustmentValues = true;
  bool _setupListPersonAdjustmentValues = false;
  bool _setupListRatingAdjustmentValues = false;
  bool _setupListSortAccending = false;

  int currentPageIndex = 0;

  late GoogleDriveService _googleDriveService;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      final data = context.read<AppData>();
      final settings = context.read<AppSettings>();

      _googleDriveService = GoogleDriveService(
        getDataToUpload: () => data.toJson(),
        onDataDownloaded: (AppData remoteData) {
          FileImport.merge(remoteData: remoteData, localData: data);
          if (!data.bikes.values.contains(data.selectedBike)) data.onBikeTap(null);
        },
      );
      if (settings.enableGoogleDrive) _googleDriveService.silentSetup();

      data.onBikeTap(null);
      data.filter();

      FileImport.cleanupIsDeleted(data: data);
      FileExport.saveData(data: data);
      FileExport.saveBackup(data: data);
      FileExport.deleteOldBackups();
    });
  }

  Future<void> _importData() async {
    final ImportSheetOptions? importChoice = await showImportSheet(context);

    if (!mounted) return;
    AppData? remoteData;
    switch (importChoice) {
      case ImportSheetOptions.file:
        remoteData = await FileImport.readJsonFileData(context);
      case ImportSheetOptions.backup:
        final backup = await Navigator.push<Backup?>(context, MaterialPageRoute(builder: (context) => BackupPage(
          googleDriveService: (mounted && context.read<AppSettings>().enableGoogleDrive) ? _googleDriveService : null
        )));
        if (backup == null) return;
        if (!mounted) return;

        switch (backup) {
          case LocalBackup(): remoteData = await FileImport.readBackup(context: context, path: backup.filepath);
          case GoogleDriveBackup(): remoteData = await _googleDriveService.readBackup(context: context, fileId: backup.fileId);
        }
      case null:
        debugPrint("showImportSheet canceled");
        return;
    }
    if (remoteData == null) return;

    if (!mounted) return;
    final selectedRemoteData = await showDataSelectSheet(context: context, data: remoteData);
    if (selectedRemoteData == null) return;

    if (!mounted) return;
    final data = context.read<AppData>();
    final ImportMergeOverwriteSheetOptions? mergeOverwriteChoice = await showImportMergeOverwriteSheet(context);
    switch (mergeOverwriteChoice) {
      case ImportMergeOverwriteSheetOptions.overwrite:
        setState(() {
          FileImport.overwrite(remoteData: remoteData!, localData: data);
        });
        data.onBikeTap(null);
      case ImportMergeOverwriteSheetOptions.merge:
        setState(() {
          FileImport.merge(remoteData: remoteData!, localData: data);
        });
      case null:
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
    final ExportSheetOptions? choice = await showExportSheet(context: context);
    
    if (!mounted) return;
    switch (choice) {
      case ExportSheetOptions.file:
        final selectedData = await showDataSelectSheet(context: context, data: context.read<AppData>());
        if (selectedData == null) return;

        if (!mounted) return;
        await FileExport.downloadJson(
          context: context,
          data: selectedData,
        );
      case ExportSheetOptions.backup:
        await FileExport.saveBackup(context: context, data: context.read<AppData>(), force: true);
      case ExportSheetOptions.googleDriveBackup:
        await _googleDriveService.saveBackup(context: context, force: true);
      case null:
        debugPrint("showExportSheet canceled.");
        return;
    }
  }

  Future<void> _shareData() async {
    final selectedData = await showDataSelectSheet(context: context, data: context.read<AppData>());    
    if (selectedData == null) return;
    
    if (!mounted) return;
    FileExport.shareJson(
      context: context,
      data: selectedData,
    );
  }

  Future<void> removeBike(Bike bike) async {
    final data = context.read<AppData>();

    final confirmed = await showConfirmationDialog(context, content: "All components and setups which belong to this bike will be deleted as well.");
    if (!confirmed) return;

    final obsoleteComponents = data.components.values.where((c) => c.bike == bike.id);
    final obsoleteSetups = data.setups.values.where((s) => s.bike == bike.id);

    data.removeBike(bike);

    removeComponents(obsoleteComponents, confirm: false);
    removeSetups(obsoleteSetups, confirm: false);

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _removePerson(Person person) async {
    final data = context.read<AppData>();
    data.removePerson(person);

    final snackBar = SnackBar(
      content: Text("Person '${person.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => data.restorePerson(person),
      ),
    );

    final SnackBarClosedReason reason = await ScaffoldMessenger.of(context).showSnackBar(snackBar).closed;
    if (reason == SnackBarClosedReason.action) return; // Not save and sync

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _removeRating(Rating rating) async {
    final data = context.read<AppData>();
    data.removeRating(rating);

    final snackBar = SnackBar(
      content: Text("Rating '${rating.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          data.restoreRating(rating);
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

  Future<void> removeSetups(Iterable<Setup> toRemoveSetups, {bool confirm = true}) async {
    if (toRemoveSetups.isEmpty) return;
    final data = context.read<AppData>();
    data.removeSetups(toRemoveSetups);

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
          onPressed: () => data.restoreSetups(toRemoveSetups),
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

  Future<void> removeComponents(Iterable<Component> toRemoveComponents, {bool confirm = true}) async {
    if (toRemoveComponents.isEmpty) return;

    final data = context.read<AppData>();
    data.removeComponents(toRemoveComponents);

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
          onPressed: () => data.restoreComponents(toRemoveComponents),
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
    final data = context.read<AppData>();

    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => const BikePage()),
    );
    if (bike == null) return;

    data.addBike(bike);
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

    if (!mounted) return;
    final data = context.read<AppData>();

    data.addPerson(person);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addRating() async {
    final data = context.read<AppData>();

    final newRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => const RatingPage(),
      ),
    );
    if (newRating == null) return;

    data.addRating(newRating);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addComponent() async {
    final data = context.read<AppData>();
    
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
      MaterialPageRoute(builder: (context) => const ComponentPage()),
    );
    if (component == null) return;

    data.addComponent(component);

    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> editBike(Bike bike) async {
    final data = context.read<AppData>();

    final editedBike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(
        builder: (context) => BikePage(bike: bike),
      ),
    );
    if (editedBike == null) return;

    data.editBike(editedBike);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _editPerson(Person person) async {
    final data = context.read<AppData>();

    final editedPerson = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (context) => PersonPage(person: person),
      ),
    );
    if (editedPerson == null) return;

    data.editPerson(editedPerson);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _editRating(Rating rating) async {
    final data = context.read<AppData>();

    final editedRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage(rating: rating),
      ),
    );
    if (editedRating == null) return;

    data.editRating(editedRating);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> editComponent(Component component) async {
    final data = context.read<AppData>();

    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage(component: component),
      ),
    );
    if (editedComponent == null) {
      data.filterComponents();
      return;
    }

    data.editComponent(editedComponent);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> duplicateComponent(Component component) async {
    final data = context.read<AppData>();

    final newComponent = component.deepCopy();
    data.addComponent(newComponent);
    
    editComponent(newComponent);  // data.filterComponents();
  }

  Future<void> _duplicatePerson(Person person) async {
    final data = context.read<AppData>();

    final newPerson = person.deepCopy();
    data.addPerson(newPerson);

    _editPerson(newPerson);
  }

  Future<void> _duplicateRating(Rating rating) async {
    final data = context.read<AppData>();

    final newRating = rating.deepCopy();
    data.addRating(newRating);

    _editRating(newRating);
  }

  Future<void> onReorderComponents(int oldIndex, int newIndex) async {
    final data = context.read<AppData>();
    data.reorderComponent(oldIndex, newIndex);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> onReorderBikes(int oldIndex, int newIndex) async {
    final data = context.read<AppData>();
    data.reorderBike(oldIndex, newIndex);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _onReorderPerson(int oldIndex, int newIndex) async {
    final data = context.read<AppData>();
    data.reorderPerson(oldIndex, newIndex);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _onReorderRating(int oldIndex, int newIndex) async {
    final data = context.read<AppData>();
    data.reorderRating(oldIndex, newIndex);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> _addSetup() async {
    final data = context.read<AppData>();

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
    if (data.components.values.where((c) => !c.isDeleted).isEmpty) {
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
      MaterialPageRoute(builder: (context) => SetupPage(getPreviousSetupbyDateTime: getPreviousSetupbyDateTime)),
    );
    if (newSetup == null) return;
    
    data.addSetup(newSetup);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> editSetup(Setup setup) async {
    final data = context.read<AppData>();

    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage(setup: setup, getPreviousSetupbyDateTime: getPreviousSetupbyDateTime)),
    );
    if (editedSetup == null) return;

    data.editSetup(editedSetup);
    FileExport.saveData(data: data);
    FileExport.saveBackup(data: data);
    if (mounted && context.read<AppSettings>().enableGoogleDrive) {_googleDriveService.scheduleSilentSync(); _googleDriveService.saveBackup(context: context);}
  }

  Future<void> duplicateSetup(Setup setup) async {
    final data = context.read<AppData>();

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

    data.addSetup(newSetup);

    editSetup(newSetup); // Sorting setups, filterSetups(), etc.
  }

  Setup? getPreviousSetupbyDateTime({required DateTime datetime, String? bike, String? person}) {
    final data = context.read<AppData>();

    return data.setups.values.lastWhereOrNull((s) => !s.isDeleted && s.datetime.isBefore(datetime) && (bike == null || s.bike == bike) && (person == null || s.person == person));
  }

  FilterChip _bikeFilterWidget() {
    final data = context.watch<AppData>();

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

  FilterChip _setupListSortWidget() {
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes the 48px constraint
      labelPadding: EdgeInsets.symmetric(vertical: 2),
      avatar: _setupListSortAccending ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward),
      label: const SizedBox.shrink(), 
      onSelected: (bool value) => setState(() => _setupListSortAccending = value),
      selected: _setupListSortAccending,
      showCheckmark: false,
    );
  }

  SingleChildScrollView _bikeListFilterWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
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
        spacing: 6,
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
        spacing: 6,
        children: [
          _bikeFilterWidget(),
          _setupListSortWidget(),
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
              label: const Icon(Person.iconData, size: 20),
              selected: _setupListPersonAdjustmentValues,
              onSelected: (bool selected) {setState(() => _setupListPersonAdjustmentValues = selected);},
              tooltip: "Show person related values",
            ),
          if (context.read<AppSettings>().enableRating)
            FilterChip(
              label: const Icon(Rating.iconData, size: 20),
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
    final appSettings = context.watch<AppSettings>();
    final data = context.watch<AppData>();
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
                    onChanged: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) { // Called when HomePage is not locked anymore
                        if (!mounted) return;
                        data.resolveData();
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
          const NavigationDestination(icon: Icon(Component.iconData), label: 'Components'),
          const NavigationDestination(icon: Icon(Setup.iconData), label: 'Setups'),
          if (appSettings.enablePerson)
            const NavigationDestination(icon: Icon(Person.iconData), label: "Profile"),
          if (appSettings.enableRating)
            const NavigationDestination(icon: Icon(Rating.iconData), label: "Ratings"),
        ],
      ),
      body: <Widget>[
        BikeList(
          bikes: data.bikes.values.where((bike) => !bike.isDeleted).toList(), //include bikes which are not filtered for
          persons: data.filteredPersons,
          selectedBike: data.selectedBike,
          onBikeTap: data.onBikeTap,
          editBike: editBike,
          removeBike: removeBike,
          onReorderBikes: onReorderBikes,
          filterWidget: _bikeListFilterWidget(),
        ),
        ComponentList(
          bikes: data.filteredBikes,
          components: data.filteredComponents,
          setups: data.setups,
          editComponent: editComponent,
          duplicateComponent: duplicateComponent,
          removeComponent: removeComponent,
          onReorderComponent: onReorderComponents,
          filterWidget: _componentListFilterWidget(),
        ),
        SetupList(
          persons: data.filteredPersons,
          ratings: data.filteredRatings,
          bikes: data.filteredBikes,
          setups: data.filteredSetups,
          components: data.filteredComponents,
          editSetup: editSetup,
          restoreSetup: duplicateSetup,
          removeSetup: removeSetup,
          displayOnlyChanges: _setupListOnlyChanges,
          displayBikeAdjustmentValues: _setupListBikeAdjustmentValues,
          displayPersonAdjustmentValues: _setupListPersonAdjustmentValues,
          displayRatingAdjustmentValues: _setupListRatingAdjustmentValues,
          filterWidget: _setupListFilterWidget(),
          accending: _setupListSortAccending,
        ),
        if (context.read<AppSettings>().enablePerson)
          PersonList(
            bikes: Map.fromEntries(data.bikes.entries.where((entry) => !entry.value.isDeleted)),
            persons: data.filteredPersons,
            setups: Map.fromEntries(data.setups.entries.where((s) => !s.value.isDeleted)),
            editPerson: _editPerson,
            duplicatePerson: _duplicatePerson,
            removePerson: _removePerson,
            onReorderPerson: _onReorderPerson,
            filterWidget: const SizedBox.shrink(),
          ),
        if (context.read<AppSettings>().enableRating)
          RatingList(
            persons: data.filteredPersons,
            bikes: data.filteredBikes,
            components: Map.fromEntries(data.components.entries.where((entry) => !entry.value.isDeleted)),
            ratings: data.filteredRatings,
            editRating: _editRating,
            duplicateRating: _duplicateRating,
            removeRating: _removeRating,
            onReorderRating: _onReorderRating,
            filterWidget: const SizedBox.shrink(),
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
