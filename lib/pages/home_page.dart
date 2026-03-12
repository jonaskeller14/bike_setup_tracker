import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/rating.dart';
import '../models/setup.dart';
import '../models/component.dart';
import '../models/app_settings.dart';
import '../repositories/app_repository.dart';
import '../utils/bike_actions.dart';
import '../utils/component_actions.dart';
import '../utils/person_actions.dart';
import '../utils/rating_actions.dart';
import '../utils/setup_actions.dart';
import '../widgets/garage_list.dart';
import '../widgets/strava_sync_button.dart';
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
}

class _HomePageState extends State<HomePage> {
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    
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
            NavigationDestination(icon: Badge(isLabelVisible: appRepository.selectedBike != null, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Bike.iconData)), label: 'Bikes')
          else ...[
            NavigationDestination(icon: Badge(isLabelVisible: appRepository.selectedBike != null, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Bike.iconData)), label: 'Bikes'),
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
            const GarageList()
          else ...[
            const BikeList(),
            const ComponentList(),
          ],
          const SetupList(),
          if (appSettings.enablePerson)
            const PersonList(),
          if (appSettings.enableRating)
            const RatingList(),
        ][_currentPageIndex],
      ),
      floatingActionButton: <Widget>[
        if (appSettings.enableGarage)
          FloatingActionButton(
            heroTag: "addBike",
            onPressed: () async {BikeActions.addBike(context);},
            tooltip: 'Add Bike',
            child: const Icon(Icons.add),
          )
        else ... [
          FloatingActionButton(
            heroTag: "addBike",
            onPressed: () async {BikeActions.addBike(context);},
            tooltip: 'Add Bike',
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: "addComponent",
            onPressed: () async {ComponentActions.addComponent(context);},
            tooltip: 'Add Component',
            child: const Icon(Icons.add),
          ),
        ],
        FloatingActionButton(
          heroTag: "addSetup",
          onPressed: () async {SetupActions.addSetup(context);},
          tooltip: 'Add Setup',
          child: const Icon(Icons.add),
        ),
        if (appSettings.enablePerson)
          FloatingActionButton(
            heroTag: "addPerson",
            onPressed: () async {PersonActions.addPerson(context);},
            tooltip: 'Add Person',
            child: const Icon(Icons.add),
          ),
        if (appSettings.enableRating)
          FloatingActionButton(
            heroTag: "addRating",
            onPressed: () async {RatingActions.addRating(context);},
            tooltip: 'Add Rating',
            child: const Icon(Icons.add),
          ),
      ][_currentPageIndex],
    );
  }
}
