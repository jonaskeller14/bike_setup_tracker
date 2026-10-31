import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_weather.dart';
import '../../widgets/sheets/language_sheet.dart';
import '../../widgets/sheets/radio_group.dart';
import '../../widgets/text/section_title.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  static Map<ThemeMode, Row> _themeModeOptionWidgets(AppLocalizations l10n) => {
    ThemeMode.system: Row(
      spacing: 8,
      children: [const Icon(Icons.settings), Text(l10n.preferencesThemeSystem)],
    ),
    ThemeMode.light: Row(
      spacing: 8,
      children: [const Icon(Icons.light_mode), Text(l10n.preferencesThemeLight)],
    ),
    ThemeMode.dark: Row(
      spacing: 8,
      children: [const Icon(Icons.dark_mode), Text(l10n.preferencesThemeDark)],
    ),
  };

  /// The samples are formatted, so month names follow the app language.
  static Map<String, Text> _dateFormatOptionWidgets() {
    final sample = DateTime(2025, 12, 9);
    return {
      for (final pattern in const ['dd.MM.yyyy', 'dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd', 'dd MMM yyyy'])
        pattern: Text('$pattern (${DateFormat(pattern).format(sample)})'),
    };
  }

  static Map<String, Text> _timeFormatOptionWidgets() {
    final sample = DateTime(2025, 12, 9, 20, 7);
    return {
      for (final pattern in const ['HH:mm', 'h:mm a']) pattern: Text('$pattern (${DateFormat(pattern).format(sample)})'),
    };
  }

  static Map<int, Text> _firstDayOfWeekOptionWidgets(AppLocalizations l10n) => {
    DateTime.monday: Text(l10n.preferencesMonday),
    DateTime.sunday: Text(l10n.preferencesSunday),
  };

  static Map<String, Text> _tempUnitOptionWidgets(AppLocalizations l10n) => {
    '°C': Text(l10n.preferencesUnitCelsius),
    '°F': Text(l10n.preferencesUnitFahrenheit),
    'K': Text(l10n.preferencesUnitKelvin),
  };

  static Map<String, Text> _windSpeedUnitOptionWidgets(AppLocalizations l10n) => {
    'km/h': Text(l10n.preferencesUnitKmh),
    'mph': Text(l10n.preferencesUnitMph),
    'm/s': Text(l10n.preferencesUnitMs),
    'kt': Text(l10n.preferencesUnitKnots),
  };

  static Map<String, Text> _distanceUnitOptionWidgets(AppLocalizations l10n) => {
    'km': Text(l10n.preferencesUnitKilometers),
    'mi': Text(l10n.preferencesUnitMiles),
  };

  static Map<String, Text> _altitudeUnitOptionWidgets(AppLocalizations l10n) => {
    'm': Text(l10n.preferencesUnitMeters),
    'ft': Text(l10n.preferencesUnitFeet),
  };

  static Map<String, Text> _precipitationUnitOptionWidgets(AppLocalizations l10n) => {
    'mm': Text(l10n.preferencesUnitMillimeters),
    'in': Text(l10n.preferencesUnitInches),
  };

  static Map<bool, Text> _offOnOptionWidgets(AppLocalizations l10n) => {
    false: Text(l10n.valueOff),
    true: Text(l10n.valueOn),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSettings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: l10n.preferencesSectionAppearance),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: Text(l10n.preferencesThemeMode),
                subtitle: _themeModeOptionWidgets(l10n)[appSettings.themeMode]?.children[1] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<ThemeMode>(
                  context: context,
                  title: l10n.preferencesThemeMode,
                  value: appSettings.themeMode,
                  optionWidgets: _themeModeOptionWidgets(l10n),
                  onChanged: (ThemeMode? newValue) {
                    if (newValue == null) return;
                    appSettings.themeMode = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              if (appSettings.enableLanguageSelection)
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.preferencesLanguage),
                  subtitle: Text(languageName(l10n, appSettings.localeCode)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => languageSheet(
                    context: context,
                    localeCode: appSettings.localeCode,
                    onSelected: (newValue) => appSettings.localeCode = newValue,
                  ),
                ),
              const Divider(),
              SectionTitle(title: l10n.preferencesSectionFilters),
              ListTile(
                leading: const Icon(Icons.filter_alt),
                title: Text(l10n.preferencesRememberFilters),
                subtitle: _offOnOptionWidgets(l10n)[appSettings.rememberFilters],
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<bool>(
                  context: context,
                  title: l10n.preferencesRememberFilters,
                  value: appSettings.rememberFilters,
                  optionWidgets: _offOnOptionWidgets(l10n),
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    appSettings.rememberFilters = newValue;
                    Navigator.pop(context);
                  },
                  infoText: l10n.preferencesRememberFiltersInfo,
                ),
              ),
              const Divider(),
              SectionTitle(title: l10n.preferencesSectionFormats),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(l10n.preferencesDateFormat),
                subtitle: _dateFormatOptionWidgets()[appSettings.dateFormat] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<String>(
                  context: context,
                  title: l10n.preferencesDateFormat,
                  value: appSettings.dateFormat,
                  optionWidgets: _dateFormatOptionWidgets(),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.dateFormat = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(l10n.preferencesTimeFormat),
                subtitle: _timeFormatOptionWidgets()[appSettings.timeFormat] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<String>(
                  context: context,
                  title: l10n.preferencesTimeFormat,
                  value: appSettings.timeFormat,
                  optionWidgets: _timeFormatOptionWidgets(),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.timeFormat = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              if (appSettings.enableCalendar)
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(l10n.preferencesFirstDayOfWeek),
                  subtitle: _firstDayOfWeekOptionWidgets(l10n)[appSettings.firstDayOfWeek] ?? const Text("-"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => radioGroupSheet<int>(
                    context: context,
                    title: l10n.preferencesFirstDayOfWeek,
                    value: appSettings.firstDayOfWeek,
                    optionWidgets: _firstDayOfWeekOptionWidgets(l10n),
                    onChanged: (int? newValue) {
                      if (newValue == null) return;
                      appSettings.firstDayOfWeek = newValue;
                      Navigator.pop(context);
                    },
                  ),
                ),
              const Divider(),
              SectionTitle(title: l10n.preferencesSectionUnits),
              ListTile(
                leading: const Icon(Icons.route),
                title: Text(l10n.preferencesDistanceUnit),
                subtitle: _distanceUnitOptionWidgets(l10n)[appSettings.distanceUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<String>(
                  context: context,
                  title: l10n.preferencesDistanceUnit,
                  value: appSettings.distanceUnit,
                  optionWidgets: _distanceUnitOptionWidgets(l10n),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.distanceUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: Text(l10n.preferencesAltitudeUnit),
                subtitle: _altitudeUnitOptionWidgets(l10n)[appSettings.altitudeUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<String>(
                  context: context,
                  title: l10n.preferencesAltitudeUnit,
                  value: appSettings.altitudeUnit,
                  optionWidgets: _altitudeUnitOptionWidgets(l10n),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.altitudeUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(ContextWeather.currentTemperatureIconData),
                title: Text(l10n.preferencesTemperatureUnit),
                subtitle: _tempUnitOptionWidgets(l10n)[appSettings.temperatureUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<String>(
                  context: context,
                  title: l10n.preferencesTemperatureUnit,
                  value: appSettings.temperatureUnit,
                  optionWidgets: _tempUnitOptionWidgets(l10n),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.temperatureUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(ContextWeather.currentWindSpeedIconData),
                title: Text(l10n.preferencesWindSpeedUnit),
                subtitle: _windSpeedUnitOptionWidgets(l10n)[appSettings.windSpeedUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<String>(
                  context: context,
                  title: l10n.preferencesWindSpeedUnit,
                  value: appSettings.windSpeedUnit,
                  optionWidgets: _windSpeedUnitOptionWidgets(l10n),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.windSpeedUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(ContextWeather.dayAccumulatedPrecipitationIconData),
                title: Text(l10n.preferencesPrecipitationUnit),
                subtitle: _precipitationUnitOptionWidgets(l10n)[appSettings.precipitationUnit] ?? const Text("-"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => radioGroupSheet<String>(
                  context: context,
                  title: l10n.preferencesPrecipitationUnit,
                  value: appSettings.precipitationUnit,
                  optionWidgets: _precipitationUnitOptionWidgets(l10n),
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    appSettings.precipitationUnit = newValue;
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
