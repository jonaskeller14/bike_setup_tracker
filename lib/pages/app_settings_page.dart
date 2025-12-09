import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  static const Map<String, String> _dateFormatOptions = {
    'dd.MM.yyyy (09.12.2025)': 'dd.MM.yyyy',
    'dd/MM/yyyy (09/12/2025)': 'dd/MM/yyyy',
    'MM/dd/yyyy (12/09/2025)': 'MM/dd/yyyy',
    'yyyy-MM-dd (2025-12-09)': 'yyyy-MM-dd',
    'dd MMM yyyy (09 Dec 2025)': 'dd MMM yyyy',
  };

  static const Map<String, String> _timeFormatOptions = {
    'HH:mm (20:07)': 'HH:mm', // 24-hour format
    'h:mm a (8:07 PM)': 'h:mm a', // 12-hour format
  };

  Widget _getThemeModeChild(ThemeMode mode) {
    IconData icon;
    String name;
    switch (mode) {
      case ThemeMode.dark:
        icon = Icons.dark_mode;
        name = 'Dark';
        break;
      case ThemeMode.light:
        icon = Icons.light_mode;
        name = 'Light';
        break;
      case ThemeMode.system:
        icon = Icons.settings;
        name = 'System';
        break;
    }
    return Row(
      spacing: 8,
      children: [
        Icon(icon),
        Text(name),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettingsWriter = context.read<AppSettings>();
    final appSettingsReader = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.color_lens, color: Theme.of(context).colorScheme.primary),
            title: const Text("App Theme Mode"),
            trailing: DropdownButton<ThemeMode>(
              value: appSettingsReader.themeMode,
              items: ThemeMode.values.map((ThemeMode mode) {
                return DropdownMenuItem<ThemeMode>(
                  value: mode,
                  child: _getThemeModeChild(mode),
                );
              }).toList(),
              onChanged: (ThemeMode? newValue) {
                if (newValue == null) return;
                setState(() {
                  appSettingsWriter.setThemeMode(newValue);
                });
              },
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
            title: const Text("Date Format"),
            trailing: DropdownButton<String>(
              value: appSettingsReader.dateFormat,
              items: _dateFormatOptions.entries.map((e) {
                return DropdownMenuItem(
                  value: e.value,
                  child: Text(e.key),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                setState(() {
                  appSettingsWriter.setDateFormat(newValue);
                });
              },
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
            title: const Text("Time Format"),
            trailing: DropdownButton<String>(
              value: appSettingsReader.timeFormat,
              items: _timeFormatOptions.entries.map((e) {
                return DropdownMenuItem(
                  value: e.value,
                  child: Text(e.key),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                setState(() {
                  appSettingsWriter.setTimeFormat(newValue);
                });
              },
            ),
          ),
        ],
      )
    );
  }
}
