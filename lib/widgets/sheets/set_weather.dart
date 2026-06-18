import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_weather.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';
import '../../utils/url.dart';
import '../dialogs/discard_changes.dart';
import 'sheet.dart';

Future<ContextWeather?> showSetWeatherSheet({
  required BuildContext context,
  required WeatherService weatherService, 
  required ContextWeather? currentWeather,
  required LocationService locationService,
  required LocationData? currentLocation,
  required DateTime selectedDateTime,
  }) async {
  return showModalBottomSheet<ContextWeather?>(
    useSafeArea: true,
    showDragHandle: true,
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
  final LocationData? currentLocation;
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

    _currentTemperatureController.text = ContextWeather.convertTemperatureFromCelsius(_currentWeather?.currentTemperature, appSettings.temperatureUnit)?.toString() ?? '';
    _dayAccumulatedPrecipitationController.text = ContextWeather.convertPrecipitationFromMm(_currentWeather?.dayAccumulatedPrecipitation, appSettings.precipitationUnit)?.toString() ?? '';
    _currentHumidityController.text = _currentWeather?.currentHumidity?.toString() ?? '';
    _currentWindSpeedController.text = ContextWeather.convertWindSpeedFromKmh(_currentWeather?.currentWindSpeed, appSettings.windSpeedUnit)?.toString() ?? '';
    _currentSoilMoisture0to7cmController.text = _currentWeather?.currentSoilMoisture0to7cm?.toString() ?? '';
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
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        sheetTitle(context, 'Weather Context'),
                        sheetCloseButton(context),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if ( widget.currentLocation?.latitude == null || widget.currentLocation?.longitude == null)
                              ListTile(
                                leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                title: const Text("Update Weather is not possible without location."),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (widget.weatherService.status case WeatherError(:final message) when message.isNotEmpty)
                              ListTile(
                                leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                title: Text(message),
                                dense: true,
                                contentPadding: const EdgeInsets.only(bottom: 16),
                              ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: _currentWeather?.currentWeatherCode,
                              isExpanded: true,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: 'Weather Code',
                                border: const OutlineInputBorder(),
                                hintText: "Choose Weather Code",
                                fillColor: Colors.orange.withValues(alpha: 0.08),
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
                                        child: Text(ContextWeather.getStaticWeatherCodeLabel(code) ?? "?", overflow: TextOverflow.ellipsis),
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
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
                              controller: _currentTemperatureController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Current Air Temperature in ${appSettings.temperatureUnit}.",
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: 'Temperature',
                                suffixText: appSettings.temperatureUnit,
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: _currentWeather?.currentTemperature != widget.currentWeather?.currentTemperature,
                                icon: const Icon(ContextWeather.currentTemperatureIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = double.tryParse(value);
                                if (parsedValue == null) return "Please enter valid number";
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather!.copyWith(currentTemperature: ContextWeather.convertTemperatureToCelsius(double.tryParse(_currentTemperatureController.text.trim()), appSettings.temperatureUnit));
                                });
                              },
                              onFieldSubmitted: (_) => _save,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                              controller: _dayAccumulatedPrecipitationController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: 'Accumulated Precipitation since midnight in ${appSettings.precipitationUnit}',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: 'Precipitation',
                                suffixText: appSettings.precipitationUnit,
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.currentWeather?.dayAccumulatedPrecipitation != _currentWeather?.dayAccumulatedPrecipitation,
                                icon: const Icon(ContextWeather.dayAccumulatedPrecipitationIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = double.tryParse(value);
                                if (parsedValue == null) return "Please enter valid number";
                                if (parsedValue < 0) return "Value cannot be negative";
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather?.copyWith(dayAccumulatedPrecipitation: ContextWeather.convertPrecipitationToMm(double.tryParse(_dayAccumulatedPrecipitationController.text.trim()), appSettings.precipitationUnit));
                                });
                              },
                              onFieldSubmitted: (_) => _save(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                              controller: _currentHumidityController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Current Relative Air Humidity as percentage value",
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: 'Humidity',
                                suffixText: '%',
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.currentWeather?.currentHumidity != _currentWeather?.currentHumidity,
                                icon: const Icon(ContextWeather.currentHumidityIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = double.tryParse(value);
                                if (parsedValue == null) return "Please enter valid number";
                                if (parsedValue < 0 || parsedValue > 100) return "Enter a valid value in the range 0..100 %";
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather?.copyWith(currentHumidity: double.tryParse(_currentHumidityController.text.trim()));
                                });
                              },
                              onFieldSubmitted: (_) => _save(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                              controller: _currentWindSpeedController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Current Wind Speed in ${appSettings.windSpeedUnit}",
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: 'Wind Speed',
                                suffixText: appSettings.windSpeedUnit,
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.currentWeather?.currentWindSpeed != _currentWeather?.currentWindSpeed,
                                icon: const Icon(ContextWeather.currentWindSpeedIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = double.tryParse(value);
                                if (parsedValue == null) return "Please enter valid number";
                                if (parsedValue < 0) return "Value cannot be negative";
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather?.copyWith(currentWindSpeed: ContextWeather.convertWindSpeedToKmh(double.tryParse(_currentWindSpeedController.text.trim()), appSettings.windSpeedUnit));
                                });
                              },
                              onFieldSubmitted: (_) => _save(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                              controller: _currentSoilMoisture0to7cmController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Average Soil Moisture 0-7cm",
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: 'Soil Moisture',
                                suffixText: 'm³/m³',
                                fillColor: Colors.orange.withValues(alpha: 0.08),
                                filled: widget.currentWeather?.currentSoilMoisture0to7cm != _currentWeather?.currentSoilMoisture0to7cm,
                                icon: const Icon(ContextWeather.currentSoilMoisture0to7cmIconData),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = double.tryParse(value);
                                if (parsedValue == null) return "Please enter valid number";
                                if (parsedValue < 0) return "Value cannot be negative";
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentWeather ??= ContextWeather(currentDateTime: widget.selectedDateTime);
                                  _currentWeather = _currentWeather?.copyWith(currentSoilMoisture0to7cm: double.tryParse(_currentSoilMoisture0to7cmController.text.trim()));
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
                                  "Weather data by Open-Meteo.com",
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
                    Row(
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
                            label: const Text("Update Weather by Location"),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          fit: FlexFit.tight,
                          child: FilledButton(
                            onPressed: _currentWeather == widget.currentWeather ? null : _save,
                            child: const Text("Save"),
                          ),
                        ),
                      ],
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