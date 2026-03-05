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
import '../widgets/garage_list.dart';
import '../widgets/strava_sync_button.dart';
import 'bike_page.dart';
import 'component_page.dart';
import 'setup_page.dart';
import 'person_page.dart';
import 'rating_page.dart';
import 'trash_page.dart';
import 'app_settings_page.dart';
import 'about_page.dart';
import 'todo_list.dart';
import '../widgets/person_list.dart';
import '../widgets/rating_list.dart';
import '../widgets/bike_list.dart';
import '../widgets/component_list.dart';
import '../widgets/setup_list.dart';
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
  int _currentPageIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final filteredData = context.watch<FilteredData>();
    
    _currentPageIndex = _currentPageIndex.clamp(0, (-1)+ (appSettings.enableGarage ? 1 : 2) + 1 + (appSettings.enablePerson ? 1 : 0) + (appSettings.enableRating ? 1: 0));
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
            const Text("Bikes")
          else ...[
            const Text("Bikes"),
            const Text("Components"),
          ],
          const Text("Setup History"),
          if (appSettings.enablePerson)
            const Text("Profile"),
          if (appSettings.enableRating)
            const Text("Ratings"),
        ][_currentPageIndex],
        actions: [
          if (appSettings.enableTodo)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Todos',
              onPressed: () {
                Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const TodoList()));
              },
            ),
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
        selectedIndex: _currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentPageIndex = index);
        },
        destinations: <Widget>[
          if (appSettings.enableGarage)
            NavigationDestination(icon: Badge(isLabelVisible: filteredData.selectedBike != null, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Bike.iconData)), label: 'Bikes')
          else ...[
            NavigationDestination(icon: Badge(isLabelVisible: filteredData.selectedBike != null, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Bike.iconData)), label: 'Bikes'),
            const NavigationDestination(icon: Icon(Component.iconData), label: 'Components'),
          ],
          const NavigationDestination(icon: Icon(Setup.iconData), label: 'Setups'),
          if (appSettings.enablePerson)
            const NavigationDestination(icon: Icon(Person.iconData), label: "Profile"),
          if (appSettings.enableRating)
            const NavigationDestination(icon: Icon(Rating.iconData), label: "Ratings"),
        ],
      ),
      body: SafeArea(
        child: <Widget>[
          if (appSettings.enableGarage)
            GarageList(
              onReorderBikes: _onReorderBikes,
            )
          else ...[
            BikeList(
              bikes: filteredData.bikes,  //include bikes which are not filtered for
              onReorderBikes: _onReorderBikes,
            ),
            ComponentList(
              components: filteredData.filteredComponents,
              onReorderComponent: _onReorderComponents,
            ),
          ],
          const SetupList(),
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
        ][_currentPageIndex],
      ),
      floatingActionButton: <Widget>[
        if (appSettings.enableGarage)
          FloatingActionButton(
            heroTag: "addBike",
            onPressed: _addBike,
            tooltip: 'Add Bike',
            child: const Icon(Icons.add),
          )
        else ... [
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
        ],
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
      ][_currentPageIndex],
    );
  }
}
