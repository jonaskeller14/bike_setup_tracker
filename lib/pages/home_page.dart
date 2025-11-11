import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/component_list.dart';
import '../widgets/setting_list.dart';
import 'add_component_page.dart';
import 'add_setting_page.dart';
import '../models/component.dart';
import '../models/setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Component> components = [];
  final List<Setting> settings = [];

@override
void initState() {
  super.initState();
  clearAllData();
    _loadData();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> clearAndReloadAllData() async {
    clearAllData();

    setState(() {
      components.clear();
      settings.clear();
    });
  }

  // --- Load data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedComponents = prefs.getStringList('components') ?? [];
    final savedSettings = prefs.getStringList('settings') ?? [];

    // Convert JSON strings to model objects
    final loadedComponents = savedComponents
        .map((c) => Component.fromJson(jsonDecode(c)))
        .toList();

    final loadedSettings = savedSettings
        .map((s) => Setting.fromJson(jsonDecode(s)))
        .toList();

    setState(() {
      components.addAll(loadedComponents);
      settings.addAll(loadedSettings);
    });
  }

  // --- Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('components', components.map((s) => jsonEncode(s.toJson())).toList(),);
    await prefs.setStringList('settings', settings.map((s) => jsonEncode(s.toJson())).toList(),);
  }

  Future<void> _addComponent() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AddComponentPage()),
    );
    if (result != null) {
      setState(() {
        components.add(Component(name: result));
      });
      _saveData();
    }
  }

  Future<void> _addSetting() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AddSettingPage()),
    );
    if (result != null) {
      setState(() {
        settings.add(Setting(name: result["name"], datetime: result["datetime"]));
      });
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(child: ComponentList(components: components)),
          Expanded(child: SettingList(settings: settings)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: "addComponent",
              onPressed: _addComponent,
              tooltip: 'Add Component',
              label: const Text('Add Component'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "addSetting",
              onPressed: _addSetting,
              tooltip: 'Add Setting',
              label: const Text('Add Setting'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "clearAndReloadAllData",
              onPressed: clearAndReloadAllData,
              tooltip: 'Clear All Data',
              label: const Text('#TODO Clear All Data'),
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }
}