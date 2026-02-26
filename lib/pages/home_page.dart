import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/rating.dart';
import '../models/setup.dart';
import '../models/component.dart';
import '../models/app_settings.dart';
import '../models/app_data.dart';
import '../models/filtered_data.dart';
import '../widgets/chips/bike_and_tags_filter.dart';
import '../widgets/garage_list.dart';
import '../widgets/sheets/setup_list_values_filter.dart';
import '../widgets/strava_sync_button.dart';
import 'bike_page.dart';
import 'component_page.dart';
import 'map_page.dart';
import 'setup_display_page.dart';
import 'setup_page.dart';
import 'person_page.dart';
import 'rating_page.dart';
import 'trash_page.dart';
import 'app_settings_page.dart';
import 'about_page.dart';
import '../widgets/person_list.dart';
import '../widgets/rating_list.dart';
import '../widgets/bike_list.dart';
import '../widgets/component_list.dart';
import '../widgets/setup_list.dart';
import '../widgets/setup_list_card.dart';
import '../widgets/sheets/import.dart';
import '../widgets/sheets/export.dart';
import '../widgets/sheets/share.dart';
import '../widgets/google_drive_sync_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  static Future<void> addSetup(BuildContext context) async {
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
      MaterialPageRoute(builder: (context) => SetupPage.add()),
    );
    if (newSetup == null) return;
    
    data.addSetup(newSetup);
  }
}

class _HomePageState extends State<HomePage> {
  bool _setupListOnlyChanges = false;
  bool _setupListBikeAdjustmentValues = true;
  bool _setupListPersonAdjustmentValues = true;
  bool _setupListRatingAdjustmentValues = true;
  bool _setupListSortAccending = false;

  int currentPageIndex = 0;

  Future<void> _removePerson(Person person) async {
    final data = context.read<AppData>();
    final filteredData = context.read<FilteredData>();

    final obsoleteRatings = filteredData.ratings.values.where((r) => r.filterType == FilterType.person && r.filter == person.id);

    data.removePerson(person);
    data.removeRatings(obsoleteRatings);

    String message = "Person '${person.name}' moved to trash.";
    if (obsoleteRatings.isNotEmpty && context.read<AppSettings>().enableRating) {
      message += "\n${obsoleteRatings.length} Ratings which belong to this person are deleted as well.";
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
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
    data.removeRatings([rating]);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Rating '${rating.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          data.restoreRatings([rating]);
        },
      ),
    ));
  }

  Future<void> _removeSetup(Setup setup) async {
    final data = context.read<AppData>();
    data.removeSetups([setup]);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Setup '${setup.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => data.restoreSetups([setup]),
      ),
    ));
  }
  
  Future<void> _addBike() async {
    final data = context.read<AppData>();

    final bike = await Navigator.push<Bike>(
      context,
      MaterialPageRoute(builder: (context) => BikePage.add()),
    );
    if (bike == null) return;

    data.addBike(bike);
  }

  Future<void> _addPerson() async {
    final data = context.read<AppData>();

    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (context) => PersonPage.add()),
    );
    if (person == null) return;    

    data.addPerson(person);
  }

  Future<void> _addRating() async {
    final data = context.read<AppData>();

    final newRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage.add(),
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
      MaterialPageRoute(builder: (context) => ComponentPage.add()),
    );
    if (component == null) return;

    data.addComponent(component);
  }

  Future<void> _editPerson(Person person) async {
    final data = context.read<AppData>();

    final editedPerson = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (context) => PersonPage.edit(person: person),
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
        builder: (context) => RatingPage.edit(rating: rating),
      ),
    );
    if (editedRating == null) return;

    data.editRating(editedRating);
  }



  Future<void> _duplicatePerson(Person person) async {
    final data = context.read<AppData>();

    final newPerson = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (context) => PersonPage.duplicate(person: person.deepCopy()),
      ),
    );
    if (newPerson == null) return;

    data.addPerson(newPerson);
  }

  Future<void> _duplicateRating(Rating rating) async {
    final data = context.read<AppData>();

    final newRating = await Navigator.push<Rating>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage.duplicate(rating: rating.deepCopy()),
      ),
    );
    if (newRating == null) return;

    data.addRating(newRating);
  }

  Future<void> _onReorderComponents(int oldIndex, int newIndex) async {
    final data = context.read<AppData>();
    final filteredData = context.read<FilteredData>();
    data.reorderComponent(oldIndex: oldIndex, newIndex: newIndex, filteredComponentsList: filteredData.filteredComponents.values.toList());
  }

  Future<void> _onReorderBikes(int oldIndex, int newIndex) async {
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
    await HomePage.addSetup(context);
  }

  Future<void> _editSetup(Setup setup) async {
    final data = context.read<AppData>();

    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.edit(setup: setup)),
    );
    if (editedSetup == null) return;

    data.editSetup(editedSetup);
  }

  Future<void> _duplicateSetup(Setup setup) async {
    final data = context.read<AppData>();

    final now = DateTime.now();

    final setupCopy = setup.copyWith(
      id: null,
      lastModified: null,
      datetime: now.toUtc(),
      datetimeLocal: now,
      isCurrent: true,
      position: null,
      place: null,
      weather: null,
      ratingAdjustmentValues: {},
      previousBikeSetup: null,
      previousPersonSetup: null,
    );
    //TODO: Not copy personAdjustmentValues: Nutritition and Equipment
    //TOOD: trigger new fetch of position, place, weather
    
    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.duplicate(setup: setupCopy)),
    );
    if (newSetup == null) return;

    data.addSetup(newSetup);
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
        await showSetupListValuesFilterSheet(
          context: context,
          onlyChanges: _setupListOnlyChanges,
          bikeValues: _setupListBikeAdjustmentValues,
          personValues: _setupListPersonAdjustmentValues,
          ratingValues: _setupListRatingAdjustmentValues,
          onOnlyChangesChanged: (bool val) => setState(() => _setupListOnlyChanges = val),
          onBikeValuesChanged: (bool val) => setState(() => _setupListBikeAdjustmentValues = val),
          onPersonValuesChanged: (bool val) => setState(() => _setupListPersonAdjustmentValues = val),
          onRatingValuesChanged: (bool val) => setState(() => _setupListRatingAdjustmentValues = val),
        );
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

  Widget _setupListMapChip() {
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: const SizedBox.shrink(),
      labelPadding: EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.zero,
      avatar: Icon(Icons.map_outlined),
      showCheckmark: false,
      selected: false,
      onSelected: (_) async {
        await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => MapPage(
          editSetup: _editSetup,
        )));
      },
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
          return SetupListCard(
            setupId: setup.id, 
            onTap: () async {
              await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDisplayPage(
                setupIds: suggestedSetups.map((s) => s.id).toList(),
                initialSetup: setup,
                editSetup: _editSetup,
              )));
            },
            editSetup: _editSetup, 
            restoreSetup: _duplicateSetup, 
            removeSetup: _removeSetup, 
            displayOnlyChanges: _setupListOnlyChanges, 
            displayBikeAdjustmentValues:_setupListBikeAdjustmentValues, 
            displayPersonAdjustmentValues: _setupListPersonAdjustmentValues, 
            displayRatingAdjustmentValues: _setupListRatingAdjustmentValues,
          );
        });
      },
    );
  }

  SingleChildScrollView _setupListFilterWidget() {
    final appSettings = context.watch<AppSettings>();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 6,
        children: [
          _setupListSortWidget(),
          _setupListSearchWidget(),
          if (appSettings.enableMap)
          _setupListMapChip(),
          BikeAndTagsFilterChip(enableSetupTagFilter: appSettings.enableSetupTags),
          _setupListValueFilterWidget(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final filteredData = context.watch<FilteredData>();
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
          if (appSettings.enableGarage)
            const Text("Garage"),
          const Text("Bikes"),
          const Text("Components"),
          const Text("Setup History"),
          if (appSettings.enablePerson)
            const Text("Profile"),
          if (appSettings.enableRating)
            const Text("Ratings"),
        ][currentPageIndex],
        actions: [
          if (appSettings.enableStrava)
            const StravaSyncButton(),
          if (appSettings.enableGoogleDrive)
            const GoogleDriveSyncButton(),
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'import': importData(context);
                case 'export': exportData(context);
                case 'share': shareData(context);
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
          setState(() => currentPageIndex = index);
        },
        destinations: <Widget>[
          if (appSettings.enableGarage)
            NavigationDestination(icon: Badge(isLabelVisible: filteredData.selectedBike != null, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Bike.iconData)), label: 'Garage'),
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
        if (appSettings.enableGarage)
          GarageList(
            onReorderBikes: _onReorderBikes,
          ),
        BikeList(
          bikes: filteredData.bikes,  //include bikes which are not filtered for
          onReorderBikes: _onReorderBikes,
        ),
        ComponentList(
          components: filteredData.filteredComponents,
          onReorderComponent: _onReorderComponents,
        ),
        SetupList(
          editSetup: _editSetup,
          restoreSetup: _duplicateSetup,
          removeSetup: _removeSetup,
          displayOnlyChanges: _setupListOnlyChanges,
          displayBikeAdjustmentValues: _setupListBikeAdjustmentValues,
          displayPersonAdjustmentValues: _setupListPersonAdjustmentValues,
          displayRatingAdjustmentValues: _setupListRatingAdjustmentValues,
          filterWidget: _setupListFilterWidget(),
          accending: _setupListSortAccending,
        ),
        if (appSettings.enablePerson)
          PersonList(
            persons: filteredData.filteredPersons,
            editPerson: _editPerson,
            duplicatePerson: _duplicatePerson,
            removePerson: _removePerson,
            onReorderPerson: _onReorderPerson,
          ),
        if (appSettings.enableRating)
          RatingList(
            ratings: filteredData.filteredRatings,
            editRating: _editRating,
            duplicateRating: _duplicateRating,
            removeRating: _removeRating,
            onReorderRating: _onReorderRating,
          ),
      ][currentPageIndex],
      floatingActionButton: <Widget>[
        FloatingActionButton(
          heroTag: "addBike",
          onPressed: _addBike,
          tooltip: 'Add Bike',
          child: const Icon(Icons.add),
        ),
        FloatingActionButton(
          heroTag: "addBike",
          onPressed: _addBike,
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
