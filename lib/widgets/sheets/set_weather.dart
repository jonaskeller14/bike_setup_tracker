import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_position.dart';
import '../../models/context/context_weather.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';
import '../../theme.dart';
import '../../utils/localized_number.dart';
import '../../utils/number_input_formatters.dart';
import '../../utils/url.dart';
import '../dialogs/discard_changes.dart';
import 'sheet_header.dart';

Future<ContextWeather?> showSetWeatherSheet({
  required BuildContext context,
  required WeatherService weatherService, 
  required ContextWeather? currentWeather,
  required LocationService locationService,
  required ContextPosition? currentLocation,
  required DateTime selectedDateTime,
  }) async {
  return showModalBottomSheet<ContextWeather?>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return SetWeatherSheetContent(
        weatherService: weatherService, 
        currentWeather: currentWeather,
        currentLocation: currentLocation,
        locationService: locationService,
        selectedDateTime: selectedDateTime,
      );
    },
  );
}

class SetWeatherSheetContent extends StatefulWidget {
  final WeatherService weatherService;
  final ContextWeather? currentWeather;
  final LocationService locationService;
  final ContextPosition? currentLocation;
  final DateTime selectedDateTime;

  const SetWeatherSheetContent({
    super.key, 
    required this.weatherService, 
    required this.currentWeather,
    required this.locationService,
    required this.currentLocation,
    required this.selectedDateTime,
  });

  @override
  State<SetWeatherSheetContent> createState() => _SetWeatherSheetContentState();
}

class _SetWeatherSheetContentState extends State<SetWeatherSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentTemperatureController = TextEditingController();
  final TextEditingController _dayAccumulatedPrecipitationController = TextEditingController();
  final TextEditingController _currentHumidityController = TextEditingController();
  final TextEditingController _currentWindSpeedController = TextEditingController();
  final TextEditingController _currentSoilMoisture0to7cmController = TextEditingController();

  late ContextWeather? _currentWeather;

  @override
  void initState() {
    super.initState();

    _currentWeather = widget.currentWeather;
    setFieldsFromWeather();
  }

  void setFieldsFromWeather() {
    final appSettings = context.read<AppSettings>();

    _currentTemperatureController.text = formatEditableDouble(ContextWeather.convertTemperatureFromCelsius(_currentWeather?.currentTemperature, appSettings.temperatureUnit));
    _dayAccumulatedPrecipitationController.text = formatEditableDouble(ContextWeather.convertPrecipitationFromMm(_currentWeather?.dayAccumulatedPrecipitation, appSettings.precipitationUnit));
    _currentHumidityController.text = formatEditableDouble(_currentWeather?.currentHumidity);
    _currentWindSpeedController.text = formatEditableDouble(ContextWeather.convertWindSpeedFromKmh(_currentWeather?.currentWindSpeed, appSettings.windSpeedUnit));
    _currentSoilMoisture0to7cmController.text = formatEditableDouble(_currentWeather?.currentSoilMoisture0to7cm);
  }

  void updateWeather() async {
    _currentWeather = await widget.weatherService.fetchWeather(
      lat: widget.currentLocation!.latitude!, 
      lon: widget.currentLocation!.longitude!, 
      datetime: widget.selectedDateTime,
    );
    setFieldsFromWeather();
  }

  @override
  void dispose() {
    _currentTemperatureController.dispose();
    _dayAccumulatedPrecipitationController.dispose();
    _currentHumidityController.dispose();
    _currentSoilMoisture0to7cmController.dispose();
    _currentWindSpeedController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_currentWeather);
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    final hasChanges = _currentWeather != widget.currentWeather;
    if (!hasChanges) {
      Navigator.of(context).pop(null);
      return;
    }

    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    return ListenableBuilder(
      listenable: Listenable.merge([widget.locationService, widget.weatherService]),
      builder: (context, child) {
        final enableFields = widget.weatherService.status is! WeatherSearching && widget.locationService.status != LocationStatus.searching;
        final enableUpdate = enableFields && widget.currentLocation?.latitude != null && widget.currentLocation?.longitude != null;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: _handlePopInvoked,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SheetHeader(title: context.l10n.weatherSheetTitle),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ( widget.currentLocation?.latitude == null || widget.currentLocation?.longitude == null)
                              ListTile(
                                leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                title: Text(context.l10n.weatherNeedsLocation),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (widget.weatherService.status case final WeatherError error)
                              ListTile(
                                leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                title: Text(error.message(context.l10n)),
                                dense: true,
                                contentPadding: const EdgeInsets.only(bottom: 16),
                              ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: _currentWeather?.currentWeatherCode,
                              isExpanded: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.weatherCodeLabel,
                                border: const OutlineInputBorder(),
                                hintText: context.l10n.weatherCodeHint,
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: widget.currentWeather?.currentWeatherCode != _currentWeather?.currentWeatherCode,
                                icon: const Icon(Icons.sunny, size: 16),
                              ),
                              items: [0,1,2,3,45,48,51,53,55,56,57,61,63,65,66,67,71,73,75,77,80,81,82,85,86,95,96,99].map((code) {
                                return DropdownMenuItem<int>(
                                  value: code,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    spacing: 12,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: FittedBox(
                                          child: Icon(ContextWeather.getStaticIconData(code)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(ContextWeather.getStaticWeatherCodeLabel(code, context.l10n) ?? "?", overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: enableFields ? (int? newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather!.copyWith(currentWeatherCode: newValue);
                                });
                              } : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              inputFormatters: const [SignedDecimalInputFormatter()],
                              controller: _currentTemperatureController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.weatherTemperatureLabel(appSettings.temperatureUnit),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: context.l10n.weatherTemperatureHint,
                                suffixText: appSettings.temperatureUnit,
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: _currentWeather?.currentTemperature != widget.currentWeather?.currentTemperature,
                                icon: const Icon(ContextWeather.currentTemperatureIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = parseLocalizedDouble(value);
                                if (parsedValue == null) return context.l10n.setNumberInvalid;
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather!.copyWith(currentTemperature: ContextWeather.convertTemperatureToCelsius(parseLocalizedDouble(_currentTemperatureController.text), appSettings.temperatureUnit));
                                });
                              },
                              onFieldSubmitted: (_) => _save,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: const [UnsignedDecimalInputFormatter()],
                              controller: _dayAccumulatedPrecipitationController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.weatherPrecipitationLabel(appSettings.precipitationUnit),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: context.l10n.weatherPrecipitationHint,
                                suffixText: appSettings.precipitationUnit,
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: widget.currentWeather?.dayAccumulatedPrecipitation != _currentWeather?.dayAccumulatedPrecipitation,
                                icon: const Icon(ContextWeather.dayAccumulatedPrecipitationIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = parseLocalizedDouble(value);
                                if (parsedValue == null) return context.l10n.setNumberInvalid;
                                if (parsedValue < 0) return context.l10n.weatherValueNegative;
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather?.copyWith(dayAccumulatedPrecipitation: ContextWeather.convertPrecipitationToMm(parseLocalizedDouble(_dayAccumulatedPrecipitationController.text), appSettings.precipitationUnit));
                                });
                              },
                              onFieldSubmitted: (_) => _save(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: const [UnsignedDecimalInputFormatter()],
                              controller: _currentHumidityController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.weatherHumidityLabel,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: context.l10n.weatherHumidityHint,
                                suffixText: '%',
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: widget.currentWeather?.currentHumidity != _currentWeather?.currentHumidity,
                                icon: const Icon(ContextWeather.currentHumidityIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = parseLocalizedDouble(value);
                                if (parsedValue == null) return context.l10n.setNumberInvalid;
                                if (parsedValue < 0 || parsedValue > 100) return context.l10n.weatherHumidityRange;
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather?.copyWith(currentHumidity: parseLocalizedDouble(_currentHumidityController.text));
                                });
                              },
                              onFieldSubmitted: (_) => _save(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: const [UnsignedDecimalInputFormatter()],
                              controller: _currentWindSpeedController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.weatherWindLabel(appSettings.windSpeedUnit),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: context.l10n.weatherWindHint,
                                suffixText: appSettings.windSpeedUnit,
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: widget.currentWeather?.currentWindSpeed != _currentWeather?.currentWindSpeed,
                                icon: const Icon(ContextWeather.currentWindSpeedIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = parseLocalizedDouble(value);
                                if (parsedValue == null) return context.l10n.setNumberInvalid;
                                if (parsedValue < 0) return context.l10n.weatherValueNegative;
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather?.copyWith(currentWindSpeed: ContextWeather.convertWindSpeedToKmh(parseLocalizedDouble(_currentWindSpeedController.text), appSettings.windSpeedUnit));
                                });
                              },
                              onFieldSubmitted: (_) => _save(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: const [UnsignedDecimalInputFormatter()],
                              controller: _currentSoilMoisture0to7cmController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.weatherSoilLabel,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: context.l10n.weatherSoilHint,
                                suffixText: 'm³/m³',
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: widget.currentWeather?.currentSoilMoisture0to7cm != _currentWeather?.currentSoilMoisture0to7cm,
                                icon: const Icon(ContextWeather.currentSoilMoisture0to7cmIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = parseLocalizedDouble(value);
                                if (parsedValue == null) return context.l10n.setNumberInvalid;
                                if (parsedValue < 0) return context.l10n.weatherValueNegative;
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather?.copyWith(currentSoilMoisture0to7cm: parseLocalizedDouble(_currentSoilMoisture0to7cmController.text));
                                });
                              },
                              onFieldSubmitted: (_) => _save(),
                            ),
                            
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () => launchAppUrl(context, url: 'https://open-meteo.com/'),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  context.l10n.weatherAttribution,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        spacing: 8,
                        children: [
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: OutlinedButton.icon(
                              onPressed: enableUpdate ? updateWeather : null,
                              icon: widget.weatherService.status is WeatherSearching
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(context.l10n.weatherUpdateByLocation),
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: FilledButton(
                              onPressed: _currentWeather == widget.currentWeather ? null : _save,
                              child: Text(context.l10n.save),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
