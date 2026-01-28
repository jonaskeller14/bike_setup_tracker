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
import '../models/filtered_data.dart';
import '../widgets/sheets/setup_list_values_filter.dart';
import 'bike_page.dart';
import 'component_page.dart';
import 'setup_display_page.dart';
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
  bool _setupListPersonAdjustmentValues = true;
  bool _setupListRatingAdjustmentValues = true;
  bool _setupListSortAccending = false;

  int currentPageIndex = 0;

  Future<void> _importData() async {
    final ImportSheetOptions? importChoice = await showImportSheet(context);

    if (!mounted) return;
    AppData? remoteData;
    switch (importChoice) {
      case ImportSheetOptions.file:
        remoteData = await FileImport.readJsonFileData(context);
      case ImportSheetOptions.backup:
        final backup = await Navigator.push<Backup?>(context, MaterialPageRoute(builder: (context) => const BackupPage()));
        if (backup == null) return;
        if (!mounted) return;

        switch (backup) {
          case LocalBackup(): remoteData = await FileImport.readBackup(context: context, path: backup.filepath);
          case GoogleDriveBackup(): remoteData = await context.read<GoogleDriveService>().readBackup(context: context, fileId: backup.fileId);
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
        FileImport.overwrite(remoteData: remoteData, localData: data);
      case ImportMergeOverwriteSheetOptions.merge:
        FileImport.merge(remoteData: remoteData, localData: data);
      case null:
        debugPrint("showImportMergeOverwriteSheet canceled");
        return;
    }
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: false,
        showCloseIcon: true,
        content: switch (mergeOverwriteChoice) {
          ImportMergeOverwriteSheetOptions.merge => const Text("Data merged successfully"),
          ImportMergeOverwriteSheetOptions.overwrite => const Text("Data overwritten successfully"),
          null => const Text("ERROR"), 
        } 
      )
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
        await context.read<GoogleDriveService>().saveBackup(context: context, force: true);
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
    final filteredData = context.read<FilteredData>();

    final obsoleteComponents = filteredData.components.values.where((c) => c.bike == bike.id).toList();
    final obsoleteSetups = filteredData.setups.values.where((s) => s.bike == bike.id).toList();

    data.removeBike(bike);
    data.removeComponents(obsoleteComponents);
    data.removeSetups(obsoleteSetups);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Bike '${bike.name}' moved to trash.\n${obsoleteComponents.length} components and ${obsoleteSetups.length} setups which belong to this bike are deleted as well."),
      duration: const Duration(seconds: 10),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          data.restoreBike(bike);
          data.restoreComponents(obsoleteComponents);
          data.restoreSetups(obsoleteSetups);
        },
      ),
    ));
  }

  Future<void> _removePerson(Person person) async {
    final data = context.read<AppData>();
    data.removePerson(person);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Person '${person.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => data.restorePerson(person),
      ),
    ));
  }

  Future<void> _removeRating(Rating rating) async {
    final data = context.read<AppData>();
    data.removeRating(rating);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    ));
  }

  Future<void> removeSetup(Setup toRemoveSetup) async {
    removeSetups([toRemoveSetup]);
  }

  Future<void> removeSetups(Iterable<Setup> toRemoveSetups, {bool confirm = true}) async {
    if (toRemoveSetups.isEmpty) return;
    final data = context.read<AppData>();
    data.removeSetups(toRemoveSetups);

    if (confirm) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
      ));
    }
  }

  Future<void> removeComponent(Component toRemoveComponent) async {
    removeComponents([toRemoveComponent]);
  }

  Future<void> removeComponents(Iterable<Component> toRemoveComponents, {bool confirm = true}) async {
    if (toRemoveComponents.isEmpty) return;

    final data = context.read<AppData>();
    data.removeComponents(toRemoveComponents);

    if (confirm) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
      ));
    }
  }
  
  Future<void> addBike() async {
    final data = context.read<AppData>();

    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => const BikePage()),
    );
    if (bike == null) return;

    data.addBike(bike);
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
  }

  Future<void> _addComponent() async {
    final data = context.read<AppData>();
    final filteredData = context.read<FilteredData>();
    if (filteredData.filteredBikes.isEmpty) {
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
  }

  Future<void> editComponent(Component component) async {
    final data = context.read<AppData>();

    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentPage(component: component),
      ),
    );
    if (editedComponent == null) return;

    data.editComponent(editedComponent);
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
    final filteredData = context.read<FilteredData>();
    data.reorderComponent(oldIndex: oldIndex, newIndex: newIndex, filteredComponentsList: filteredData.filteredComponents.values.toList());
  }

  Future<void> onReorderBikes(int oldIndex, int newIndex) async {
    final data = context.read<AppData>();
    final filteredData = context.read<FilteredData>();
    data.reorderBike(oldIndex: oldIndex, newIndex: newIndex, filteredBikesList: filteredData.bikes.values.toList());
  }

  Future<void> _onReorderPerson(int oldIndex, int newIndex) async {
    final data = context.read<AppData>();
    final filteredData = context.read<FilteredData>();
    data.reorderPerson(oldIndex: oldIndex, newIndex: newIndex, filteredPersonsList: filteredData.filteredPersons.values.toList());
  }

  Future<void> _onReorderRating(int oldIndex, int newIndex) async {
    final data = context.read<AppData>();
    final filteredData = context.read<FilteredData>();
    data.reorderRating(oldIndex: oldIndex, newIndex: newIndex, filteredRatingsList: filteredData.filteredRatings.values.toList());
  }

  Future<void> _addSetup() async {
    final data = context.read<AppData>();
    final filteredData = context.read<FilteredData>();

    if (filteredData.bikes.values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true, 
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text("Add a bike first", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
      return;
    }
    if (filteredData.components.values.isEmpty) {
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
  }

  Future<void> editSetup(Setup setup) async {
    final data = context.read<AppData>();

    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage(setup: setup, getPreviousSetupbyDateTime: getPreviousSetupbyDateTime)),
    );
    if (editedSetup == null) return;

    data.editSetup(editedSetup);
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
    final filteredData = context.read<FilteredData>();
    return filteredData.setups.values.lastWhereOrNull((s) => s.datetime.isBefore(datetime) && (bike == null || s.bike == bike) && (person == null || s.person == person));
  }

  FilterChip _bikeFilterWidget() {
    final filteredData = context.watch<FilteredData>();

    return FilterChip(
      avatar: const Icon(Bike.iconData),
      label: filteredData.selectedBike == null ? const Text("All Bikes") : Text(filteredData.selectedBike!.name),
      selected: filteredData.selectedBike != null,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        final List<Bike>? newSelectedBikes = await showBikeFilterSheet(
          context: context,
          bikes: filteredData.bikes.values,
          selectedBike: filteredData.selectedBike,
        );
        if (newSelectedBikes == null) return;
        if (newSelectedBikes.isEmpty) {
          filteredData.onBikeTap(null);
        } else if (newSelectedBikes[0] != filteredData.selectedBike) {
          filteredData.onBikeTap(newSelectedBikes[0]);
        }
      },
      onDeleted: filteredData.selectedBike == null 
          ? null 
          : () => filteredData.onBikeTap(null),
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

  FilterChip _setupListValueFilterWidget() {
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes the 48px constraint
      avatar: const Icon(Icons.list_alt),
      label: const Text("Values"),
      showCheckmark: false,
      selected: _setupListOnlyChanges || !_setupListBikeAdjustmentValues || !_setupListPersonAdjustmentValues || !_setupListRatingAdjustmentValues,
      onSelected: (bool value) async {
        final result = await showSetupListValuesFilterSheet(context: context, setupListValuesFilter: {
          SetupListValuesFilterOptions.onlyChanges: _setupListOnlyChanges,
          SetupListValuesFilterOptions.bikeValues: _setupListBikeAdjustmentValues,
          SetupListValuesFilterOptions.personValues: _setupListPersonAdjustmentValues,
          SetupListValuesFilterOptions.ratingValues: _setupListRatingAdjustmentValues,
        });
        if (result == null) return;
        setState(() {
          for (final resultEntry in result.entries) {
            switch (resultEntry.key) {
              case SetupListValuesFilterOptions.onlyChanges: _setupListOnlyChanges = resultEntry.value;
              case SetupListValuesFilterOptions.bikeValues: _setupListBikeAdjustmentValues = resultEntry.value;
              case SetupListValuesFilterOptions.personValues: _setupListPersonAdjustmentValues = resultEntry.value;
              case SetupListValuesFilterOptions.ratingValues: _setupListRatingAdjustmentValues = resultEntry.value;
            }
          }
        });
      },
      onDeleted: _setupListOnlyChanges || !_setupListBikeAdjustmentValues || !_setupListPersonAdjustmentValues || !_setupListRatingAdjustmentValues
          ? () {
              setState(() {
                _setupListOnlyChanges = false;
                _setupListBikeAdjustmentValues = true;
                _setupListPersonAdjustmentValues = true;
                _setupListRatingAdjustmentValues = true;
              });
            }
          : null,
    );
  }

  SearchAnchor _setupListSearchWidget() {
    return SearchAnchor(
      builder:(context, controller) {
        return FilterChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          // label: Text(controller.text),
          label: const SizedBox.shrink(),
          labelPadding: EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.zero,
          avatar: Icon(Icons.search),
          showCheckmark: false,
          // selected: controller.text.isNotEmpty,
          selected: false,
          onSelected: (bool newValue) {controller.text = ""; controller.openView();},
          // onDeleted: controller.text.isEmpty ? null : () => setState(() => controller.text = ""),
        );
      },
      viewBuilder: (Iterable<Widget> suggestions) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) => suggestions.elementAt(index),
        );
      },
      suggestionsBuilder: (context, controller) {
        final filteredData = context.read<FilteredData>();
        final controllerText = controller.text.trim().toLowerCase();
        final Iterable<Setup> setups = _setupListSortAccending
            ? filteredData.filteredSetups.values
            : filteredData.filteredSetups.values.toList().reversed;
        final Iterable<Setup> suggestedSetups = setups.where((s) {
          return s.name.toLowerCase().contains(controllerText) || 
              (s.notes ?? "").toLowerCase().contains(controllerText);
        });

        return suggestedSetups.map((setup) {
          return InkWell(
            onTap: () async {
              await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDisplayPage(
                setupIds: suggestedSetups.map((s) => s.id).toList(),
                initialSetup: setup,
                editSetup: editSetup,
              )));
            },
            child: SetupCard(
              setupId: setup.id, 
              editSetup: editSetup, 
              restoreSetup: duplicateSetup, 
              removeSetup: removeSetup, 
              displayOnlyChanges: _setupListOnlyChanges, 
              displayBikeAdjustmentValues:_setupListBikeAdjustmentValues, 
              displayPersonAdjustmentValues: _setupListPersonAdjustmentValues, 
              displayRatingAdjustmentValues: _setupListRatingAdjustmentValues,
            ),
          );
        });
      },
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
          _setupListSortWidget(),
          _setupListSearchWidget(),
          _bikeFilterWidget(),
          _setupListValueFilterWidget(),
        ],
      ),
    );
  }

  SingleChildScrollView _personListFilterWidget() {
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

  SingleChildScrollView _ratingListFilterWidget() {
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

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final filteredData = context.read<FilteredData>();
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
            const GoogleDriveSyncButton(),
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'import': _importData();
                case 'export': _exportData();
                case 'share': _shareData();
                case "trash": Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const TrashPage()));
                case "settings": Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AppSettingsPage()));
                case "about": Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AboutPage()));
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
          NavigationDestination(icon: Badge(isLabelVisible: filteredData.selectedBike != null, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Bike.iconData)), label: 'Bikes'),
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
          bikes: filteredData.bikes.values.toList(), //include bikes which are not filtered for
          selectedBike: filteredData.selectedBike,
          onBikeTap: filteredData.onBikeTap,
          editBike: editBike,
          removeBike: removeBike,
          onReorderBikes: onReorderBikes,
          filterWidget: _bikeListFilterWidget(),
        ),
        ComponentList(
          bikes: filteredData.bikes,
          components: filteredData.filteredComponents,
          setups: filteredData.setups,
          editComponent: editComponent,
          duplicateComponent: duplicateComponent,
          removeComponent: removeComponent,
          onReorderComponent: onReorderComponents,
          filterWidget: _componentListFilterWidget(),
        ),
        SetupList(
          setups: filteredData.filteredSetups,
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
            bikes: filteredData.bikes,
            persons: filteredData.filteredPersons,
            setups: filteredData.setups,
            editPerson: _editPerson,
            duplicatePerson: _duplicatePerson,
            removePerson: _removePerson,
            onReorderPerson: _onReorderPerson,
            filterWidget: _personListFilterWidget(),
          ),
        if (context.read<AppSettings>().enableRating)
          RatingList(
            ratings: filteredData.filteredRatings,
            editRating: _editRating,
            duplicateRating: _duplicateRating,
            removeRating: _removeRating,
            onReorderRating: _onReorderRating,
            filterWidget: _ratingListFilterWidget(),
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
