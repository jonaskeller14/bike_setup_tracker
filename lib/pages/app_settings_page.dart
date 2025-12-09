import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
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
            title: const Text("Theme Mode"),
            trailing: DropdownButton<ThemeMode>(
              value: appSettingsReader.themeMode,
              items: ThemeMode.values.map((ThemeMode mode) {
                return DropdownMenuItem<ThemeMode>(
                  value: mode,
                  child: Row(
                    spacing: 8,
                    children: [
                      if (mode == ThemeMode.dark)
                        Icon(Icons.dark_mode),
                      if (mode == ThemeMode.light)
                        Icon(Icons.light_mode),
                      if (mode == ThemeMode.system)
                        Icon(Icons.settings),
                      Text(mode.name)
                    ],
                  ),
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
          // Divider(),
        ],
      )
    );
  }
}
