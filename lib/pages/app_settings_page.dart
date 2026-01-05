import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  static const Map<ThemeMode, String> _themeModeOptions = {
    ThemeMode.system: "System",
    ThemeMode.light: "Light",
    ThemeMode.dark: "Dark",
  };

  static const Map<ThemeMode, Widget> _themeModeOptionWidgets = {
    ThemeMode.system: Row(spacing: 8, children: [Icon(Icons.settings), Text("System")]),
    ThemeMode.light: Row(spacing: 8, children: [Icon(Icons.light_mode), Text("Light")]),
    ThemeMode.dark: Row(spacing: 8, children: [Icon(Icons.dark_mode), Text("Dark")]),
  };

  static const Map<String, String> _dateFormatOptions = {
    'dd.MM.yyyy': 'dd.MM.yyyy (09.12.2025)',
    'dd/MM/yyyy': 'dd/MM/yyyy (09/12/2025)',
    'MM/dd/yyyy': 'MM/dd/yyyy (12/09/2025)',
    'yyyy-MM-dd': 'yyyy-MM-dd (2025-12-09)',
    'dd MMM yyyy': 'dd MMM yyyy (09 Dec 2025)',
  };

  static const Map<String, String> _timeFormatOptions = {
    'HH:mm': 'HH:mm (20:07)',
    'h:mm a': 'h:mm a (8:07 PM)',
  };

  static const Map<String, String> _tempUnitOptions = {
    '°C': 'Celsius (°C)',
    '°F': 'Fahrenheit (°F)',
    'K': 'Kelvin (K)',
  };

  static const Map<String, String> _windSpeedUnitOptions = {
    'km/h': 'Kilometers per hour (km/h)',
    'mph': 'Miles per hour (mph)',
    'm/s': 'Meters per second (m/s)',
    'kt': 'Knots (kt)',
  };

  static const Map<String, String> _altitudeUnitOptions = {
    'm': 'Meters (m)',
    'ft': 'Feet (ft)',
  };

  static const Map<String, String> _precipitationUnitOptions = {
    'mm': 'Millimeters (mm)',
    'in': 'Inches (in)',
  };

  @override
  Widget build(BuildContext context) {
    final appSettingsWriter = context.read<AppSettings>();
    final appSettingsReader = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.color_lens, color: Theme.of(context).colorScheme.primary),
              title: const Text("App Theme Mode"),
              subtitle: Text(_themeModeOptions[appSettingsReader.themeMode] ?? "-"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
              onTap: () => showModalBottomSheet<void>(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return RadioGroup<ThemeMode>(
                    groupValue: appSettingsReader.themeMode,
                    onChanged: (ThemeMode? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.setThemeMode(newValue);
                      Navigator.pop(context);
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("App Theme Mode", style: Theme.of(context).textTheme.titleLarge),
                          ),
                          const SizedBox(height: 16),
                          ..._themeModeOptionWidgets.entries.map((e) => RadioListTile(
                            value: e.key,
                            title: e.value,
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: Text(
                'Default Formats',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
              title: const Text("Date Format"),
              subtitle: Text(_dateFormatOptions[appSettingsReader.dateFormat] ?? "-"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
              onTap: () => showModalBottomSheet<void>(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return RadioGroup<String>(
                    groupValue: appSettingsReader.dateFormat,
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.setDateFormat(newValue);
                      Navigator.pop(context);
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Date Format", style: Theme.of(context).textTheme.titleLarge),
                          ),
                          const SizedBox(height: 16),
                          ..._dateFormatOptions.entries.map((e) => RadioListTile(
                            value: e.key,
                            title: Text(e.value)
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            ListTile(
              leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
              title: const Text("Time Format"),
              subtitle: Text(_timeFormatOptions[appSettingsReader.timeFormat] ?? "-"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
              onTap: () => showModalBottomSheet<void>(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return RadioGroup<String>(
                    groupValue: appSettingsReader.timeFormat,
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.setTimeFormat(newValue);
                      Navigator.pop(context);
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Time Format", style: Theme.of(context).textTheme.titleLarge),
                          ),
                          const SizedBox(height: 16),
                          ..._timeFormatOptions.entries.map((e) => RadioListTile(
                            value: e.key,
                            title: Text(e.value)
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: Text(
                'Default Units',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.primary),
              title: const Text("Altitude Unit"),
              subtitle: Text(_altitudeUnitOptions[appSettingsReader.altitudeUnit] ?? "-"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
              onTap: () => showModalBottomSheet<void>(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return RadioGroup<String>(
                    groupValue: appSettingsReader.altitudeUnit,
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.setAltitudeUnit(newValue);
                      Navigator.pop(context);
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Altitude Unit", style: Theme.of(context).textTheme.titleLarge),
                          ),
                          const SizedBox(height: 16),
                          ..._altitudeUnitOptions.entries.map((e) => RadioListTile(
                            value: e.key,
                            title: Text(e.value)
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            ListTile(
              leading: Icon(Icons.thermostat, color: Theme.of(context).colorScheme.primary),
              title: const Text("Temperature Unit"),
              subtitle: Text(_tempUnitOptions[appSettingsReader.temperatureUnit] ?? "-"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
              onTap: () => showModalBottomSheet<void>(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return RadioGroup<String>(
                    groupValue: appSettingsReader.temperatureUnit,
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.setTemperatureUnit(newValue);
                      Navigator.pop(context);
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Temperature Unit", style: Theme.of(context).textTheme.titleLarge),
                          ),
                          const SizedBox(height: 16),
                          ..._tempUnitOptions.entries.map((e) => RadioListTile(
                            value: e.key,
                            title: Text(e.value)
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            ListTile(
              leading: Icon(Icons.air, color: Theme.of(context).colorScheme.primary),
              title: const Text("Wind Speed Unit"),
              subtitle: Text(_windSpeedUnitOptions[appSettingsReader.windSpeedUnit] ?? "-"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
              onTap: () => showModalBottomSheet<void>(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return RadioGroup<String>(
                    groupValue: appSettingsReader.windSpeedUnit,
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.setWindSpeedUnit(newValue);
                      Navigator.pop(context);
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Wind Speed Unit", style: Theme.of(context).textTheme.titleLarge),
                          ),
                          const SizedBox(height: 16),
                          ..._windSpeedUnitOptions.entries.map((e) => RadioListTile(
                            value: e.key,
                            title: Text(e.value)
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            ListTile(
              leading: Icon(Icons.water_drop, color: Theme.of(context).colorScheme.primary),
              subtitle: Text(_precipitationUnitOptions[appSettingsReader.precipitationUnit] ?? "-"),
              title: const Text("Precipitation Unit"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
              onTap: () => showModalBottomSheet<void>(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return RadioGroup<String>(
                    groupValue: appSettingsReader.precipitationUnit,
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      appSettingsWriter.setPrecipitationUnit(newValue);
                      Navigator.pop(context);
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Precipitation Unit", style: Theme.of(context).textTheme.titleLarge),
                          ),
                          const SizedBox(height: 16),
                          ..._precipitationUnitOptions.entries.map((e) => RadioListTile(
                            value: e.key,
                            title: Text(e.value)
                          )),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
