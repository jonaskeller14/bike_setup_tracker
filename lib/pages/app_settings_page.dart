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
    'HH:mm (20:07)': 'HH:mm',
    'h:mm a (8:07 PM)': 'h:mm a',
  };

  // Unit settings updated to save the displayable string directly.
  static const Map<String, String> _tempUnitOptions = {
    'Celsius (°C)': '°C',
    'Fahrenheit (°F)': '°F',
    'Kelvin (K)': 'K',
  };

  static const Map<String, String> _windSpeedUnitOptions = {
    'Kilometers per hour (km/h)': 'km/h',
    'Miles per hour (mph)': 'mph',
    'Meters per second (m/s)': 'm/s',
    'Knots (kt)': 'kt',
  };

  static const Map<String, String> _altitudeUnitOptions = {
    'Meters (m)': 'm',
    'Feet (ft)': 'ft',
  };

  static const Map<String, String> _precipitationUnitOptions = {
    'Millimeters (mm)': 'mm',
    'Inches (in)': 'in',
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
  
  List<DropdownMenuItem<String>> _buildDropdownItems(Map<String, String> options) {
    return options.entries.map((e) {
      return DropdownMenuItem(
        value: e.value,
        child: Text(e.key),
      );
    }).toList();
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
            leading: Icon(Icons.color_lens),
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
                appSettingsWriter.setThemeMode(newValue);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.calendar_month),
            title: const Text("Date Format"),
            trailing: DropdownButton<String>(
              value: appSettingsReader.dateFormat,
              items: _buildDropdownItems(_dateFormatOptions),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                appSettingsWriter.setDateFormat(newValue);
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.access_time),
            title: const Text("Time Format"),
            trailing: DropdownButton<String>(
              value: appSettingsReader.timeFormat,
              items: _buildDropdownItems(_timeFormatOptions),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                appSettingsWriter.setTimeFormat(newValue);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.arrow_upward),
            title: const Text("Altitude Unit"),
            trailing: DropdownButton<String>(
              value: appSettingsReader.altitudeUnit,
              items: _buildDropdownItems(_altitudeUnitOptions),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                appSettingsWriter.setAltitudeUnit(newValue);
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.thermostat),
            title: const Text("Temperature Unit"),
            trailing: DropdownButton<String>(
              value: appSettingsReader.temperatureUnit,
              items: _buildDropdownItems(_tempUnitOptions),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                appSettingsWriter.setTemperatureUnit(newValue);
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.air),
            title: const Text("Wind Speed Unit"),
            trailing: DropdownButton<String>(
              value: appSettingsReader.windSpeedUnit,
              items: _buildDropdownItems(_windSpeedUnitOptions),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                appSettingsWriter.setWindSpeedUnit(newValue);
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.water_drop),
            title: const Text("Precipitation Unit"),
            trailing: DropdownButton<String>(
              value: appSettingsReader.precipitationUnit,
              items: _buildDropdownItems(_precipitationUnitOptions),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                appSettingsWriter.setPrecipitationUnit(newValue);
              },
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
