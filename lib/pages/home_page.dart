import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_save_directory/file_save_directory.dart';
import '../widgets/component_list.dart';
import '../widgets/setting_list.dart';
import 'add_component_page.dart';
import 'edit_component_page.dart';
import 'add_setting_page.dart';
import 'edit_setting_page.dart';
import '../models/adjustment.dart';
import '../models/setting.dart';
import '../models/component.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Adjustment> adjustments = [];
  final List<Setting> settings = [];
  final List<Component> components = [];

  @override
  void initState() {
    super.initState();
    // loadData();
  }

  Future<void> loadData() async {
    try {
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data successfully loaded!')),
      );
    } catch (e, st) {
      // Log stacktrace to console to help debugging
      // (you can remove the print in production)
      debugPrint('Error loading data: $e\n$st');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
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
      adjustments.clear();
      settings.clear();
      components.clear();
    });
  }

  Future<void> removeSetting(Setting setting) async {
    final confirmed = await showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    setState(() {
      settings.remove(setting);
      // Also ensure components don't hold dangling references
      for (var c in components) {
        if (c.currentSetting == setting) {
          c.currentSetting = null;
        }
      }
    });
    await _saveData();
  }

  Future<void> removeComponent(Component component) async {
    final confirmed = await showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    setState(() {
      for (var adjustment in component.adjustments) {
        adjustments.remove(adjustment);
      }
      components.remove(component);
    });
    await _saveData();
  }

  // --- Load data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAdjustments = prefs.getStringList('adjustments') ?? <String>[];
    final savedSettings = prefs.getStringList('settings') ?? <String>[];
    final savedComponents = prefs.getStringList('components') ?? <String>[];

    // Convert JSON strings to model objects
    final loadedAdjustments = savedAdjustments
        .map((a) => Adjustment.fromJson(jsonDecode(a)))
        .toList();

    final loadedSettings = savedSettings
        .map((s) => Setting.fromJson(jsonDecode(s), loadedAdjustments))
        .toList();
    for (int i = 0; i < loadedSettings.length; i++) {
      loadedSettings[i].previousSettingFromJson(jsonDecode(savedSettings[i]), loadedSettings);
    }
    
    final loadedComponents = savedComponents
        .map((c) => Component.fromJson(jsonDecode(c), loadedAdjustments, loadedSettings))
        .toList();

    // Finally update state
    if (!mounted) return;
    setState(() {
      adjustments
        ..clear()
        ..addAll(loadedAdjustments);
      settings
        ..clear()
        ..addAll(loadedSettings);
      components
        ..clear()
        ..addAll(loadedComponents);
    });
  }

  // --- Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'adjustments',
      adjustments.map((a) => jsonEncode(a.toJson())).toList(),
    );
    await prefs.setStringList(
      'settings',
      settings.map((s) => jsonEncode(s.toJson())).toList(),
    );
    await prefs.setStringList(
      'components',
      components.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> _addComponent() async {
    final component = await Navigator.push<Component>(
      context,
      MaterialPageRoute(builder: (context) => const AddComponentPage()),
    );

    if (component != null) {
      setState(() {
        components.add(component);
        adjustments.addAll(component.adjustments);
      });
      await _saveData();
    }
  }

  Future<void> editComponent(Component component) async {
    //TODO: Update adjustments?
    final editedComponent = await Navigator.push<Component>(
      context,
      MaterialPageRoute(
        builder: (context) => EditComponentPage(component: component),
      ),
    );
    if (editedComponent != null) {
      setState(() {
        final index = components.indexOf(component);
        if (index != -1) {
          components[index] = editedComponent;
        }
      });
      await _saveData();
    }
  }

  Future<void> _addSetting() async {
    final setting = await Navigator.push<Setting>(
      context,
      MaterialPageRoute(builder: (context) => AddSettingPage(components: components)),
    );
    if (setting != null) {
      setState(() {
        for (var component in components) {
          component.currentSetting = setting;
        }
        settings.add(setting);
      });
      await _saveData();
    }
  }

  Future<void> editSetting(Setting setting) async {
    final editedSetting = await Navigator.push<Setting>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSettingPage(setting: setting),
      ),
    );
    if (editedSetting != null) {
      setState(() {
        final index = settings.indexOf(setting);
        if (index != -1) {
          settings[index] = editedSetting;
        }
      });
      await _saveData();
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Continue"),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void downloadJson() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    _downloadJson().then((result) {
      if (!mounted) return;

      if (result == null || result.path == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Export failed")),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Saved to: ${result.path}")),
        );
      }
    }).catchError((e, st) {
      debugPrint('Export failed: $e\n$st');
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    });
  }

  Future<FileSaveResult?> _downloadJson() async {
    try {
      final exportData = {
        'adjustments': adjustments.map((a) => a.toJson()).toList(),
        'settings': settings.map((s) => s.toJson()).toList(),
        'components': components.map((c) => c.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final bytes = utf8.encode(jsonString);

      final now = DateTime.now();
      final timestamp =
          '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final result = await FileSaveDirectory.instance.saveFile(
        fileName: '${timestamp}_export.json',
        fileBytes: bytes,
        location: SaveLocation.downloads,
        openAfterSave: false,
      );
      return result;
    } catch (e, st) {
      debugPrint('Error while exporting JSON: $e\n$st');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [IconButton(onPressed: downloadJson, icon: const Icon(Icons.download))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Components',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ComponentList(
            components: components,
            editComponent: editComponent,
            removeComponent: removeComponent,
          ),

          const Text(
            'Log',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          SettingList(
            settings: settings,
            editSetting: editSetting,
            removeSetting: removeSetting,
          ),

          const SizedBox(height: 200),
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
              heroTag: "clearData",
              onPressed: clearData,
              label: const Text('#TODO Clear Data'),
              icon: const Icon(Icons.delete),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "loadData",
              onPressed: loadData,
              label: const Text('#TODO Load Data'),
              icon: const Icon(Icons.file_upload),
            ),
          ],
        ),
      ),
    );
  }
}
