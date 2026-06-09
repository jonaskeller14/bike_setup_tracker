import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/rating.dart';
import '../models/setup.dart';
import '../repositories/app_repository.dart';
import '../utils/bike_actions.dart';
import '../utils/component_actions.dart';
import '../utils/person_actions.dart';
import '../utils/rating_actions.dart';
import '../utils/setup_actions.dart';
import '../utils/task_actions.dart';
import '../widgets/google_drive_sync_button.dart';
import '../widgets/lists/bike_list.dart';
import '../widgets/lists/component_list.dart';
import '../widgets/lists/garage_list.dart';
import '../widgets/lists/person_list.dart';
import '../widgets/lists/rating_list.dart';
import '../widgets/lists/setup_list.dart';
import '../widgets/lists/task_list.dart';
import '../widgets/sheets/export.dart';
import '../widgets/sheets/import.dart';
import '../widgets/sheets/share.dart';
import '../widgets/strava_sync_button.dart';
import 'settings/app_settings_page.dart';
import 'trash_page.dart';

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
    final toDoTaskRulesCount = appRepository.openTaskRules.length;
    
    _currentPageIndex = _currentPageIndex.clamp(0, (-1)+ (appSettings.enableGarage ? 1 : 2) + 1 + (appSettings.enablePerson ? 1 : 0) + (appSettings.enableRating ? 1: 0) + (appSettings.enableTask ? 1 : 0));
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            height: 30, 
            width: 30,
            child: ClipOval(
              child: Image.asset(
                'assets/icons/logo_256.png',
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
          if (appSettings.enableTask)
            const Text("Tasks"),
        ][_currentPageIndex],
        actions: [
          if (appSettings.enableStrava)
            const StravaSyncButton(),
          if (appSettings.enableGoogleDrive)
            const GoogleDriveSyncButton(),
          PopupMenuButton<_AppOptions>(
            onSelected: (_AppOptions result) async {
              switch (result) {
                case _AppOptions.import: await importData(context);
                case _AppOptions.export: await exportData(context);
                case _AppOptions.share: await shareData(context);
                case _AppOptions.trash: await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const TrashPage()));
                case _AppOptions.settings: await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AppSettingsPage()));
              }
            },
            itemBuilder: (BuildContext context) => _AppOptions.values.map((appOption) {
              return PopupMenuItem<_AppOptions>(
                value: appOption,
                child: Row(
                  children: [
                    Icon(appOption.iconData),
                    const SizedBox(width: 8),
                    Text(appOption.label),
                  ],
                ),
              );
            }).toList(),
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
          if (appSettings.enableTask)
            NavigationDestination(
              icon: Badge.count(
                count: toDoTaskRulesCount,
                maxCount: 99,
                isLabelVisible: toDoTaskRulesCount > 0,
                backgroundColor: appRepository.openTaskRulesStatusType.getStatusColor(),
                child: const Icon(Icons.checklist),
              ),
              label: "Tasks",
            ),
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
          if (appSettings.enableTask)
            const TaskList(),
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
        if (appSettings.enableTask)
          FloatingActionButton(
            heroTag: "addTask",
            onPressed: () async {TaskActions.addTaskRule(context);},
            tooltip: 'Add Task',
            child: const Icon(Icons.add),
          ),
      ][_currentPageIndex],
    );
  }
}

enum _AppOptions {
  import('Import Data', Icons.file_upload),
  export('Export Data', Icons.file_download),
  share('Share Data', Icons.share),
  trash('Trash', Icons.delete),
  settings("Settings", Icons.settings);
  final String label;
  final IconData iconData;
  const _AppOptions(this.label, this.iconData);
}
