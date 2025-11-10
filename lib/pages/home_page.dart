import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/component_list.dart';
import '../widgets/setting_list.dart';
import 'add_component_page.dart';
import 'add_setting_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> components = [];
  final List<String> settings = [];

  @override
  void initState() {
    super.initState();
    _loadData(); // ⬅️ Load saved data when app starts
  }

  // --- Load data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedComponents = prefs.getStringList('components') ?? [];
    final savedSettings = prefs.getStringList('settings') ?? [];

    print('Loaded components: $savedComponents');
    print('Loaded settings: $savedSettings');

    setState(() {
      components.addAll(savedComponents);
      settings.addAll(savedSettings);
    });
  }

  // --- Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('components', components);
    await prefs.setStringList('settings', settings);
  }

  // --- Add a new component
  Future<void> _addComponent() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AddComponentPage()),
    );
    if (result != null) {
      setState(() {
        components.add(result);
      });
      _saveData(); // ⬅️ Save immediately after adding
    }
  }

  // --- Add a new setting
  Future<void> _addSetting() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AddSettingPage()),
    );
    if (result != null) {
      setState(() {
        settings.add(result);
      });
      _saveData(); // ⬅️ Save immediately after adding
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
              onPressed: _addComponent,
              tooltip: 'Add Component',
              label: const Text('Add Component'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: _addSetting,
              tooltip: 'Add Setting',
              label: const Text('Add Setting'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}