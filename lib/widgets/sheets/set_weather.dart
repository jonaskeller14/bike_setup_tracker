import 'package:bike_setup_tracker/models/weather.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/weather_service.dart';
import 'sheet.dart';

Future<Weather?> showSetWeatherSheet({
  required BuildContext context,
  required WeatherService weatherService, 
  required Weather? currentWeather,
  required LocationService locationService,
  required LocationData? currentLocation,
  required DateTime selectedDateTime,
  }) async {
  return await showModalBottomSheet<Weather?>(
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
  final Weather? currentWeather;
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

  late Weather? _currentWeather;

  @override
  void initState() {
    super.initState();

    _currentWeather = widget.currentWeather;
    setFieldsFromWeather();
  }

  void setFieldsFromWeather() {
    final appSettings = context.read<AppSettings>();

    _currentTemperatureController.text = Weather.convertTemperatureFromCelsius(_currentWeather?.currentTemperature, appSettings.temperatureUnit)?.toString() ?? '';
    _dayAccumulatedPrecipitationController.text = Weather.convertPrecipitationFromMm(_currentWeather?.dayAccumulatedPrecipitation, appSettings.precipitationUnit)?.toString() ?? '';
    _currentHumidityController.text = _currentWeather?.currentHumidity?.toString() ?? '';
    _currentWindSpeedController.text = Weather.convertWindSpeedFromKmh(_currentWeather?.currentWindSpeed, appSettings.windSpeedUnit)?.toString() ?? '';
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

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    return ListenableBuilder(
      listenable: Listenable.merge([widget.locationService, widget.weatherService]),
      builder: (context, child) {
        final enableFields = widget.weatherService.status != WeatherStatus.searching && widget.locationService.status != LocationStatus.searching;
        final enableUpdate = enableFields && widget.currentLocation?.latitude != null && widget.currentLocation?.longitude != null;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom),
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
                          if (widget.weatherService.status == WeatherStatus.error)
                            ListTile(
                              leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                              title: const Text("Error occured during weather update."),
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
                              border: OutlineInputBorder(),
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
                                        child: Icon(Weather.getStaticIconData(code)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(Weather.getStaticWeatherCodeLabel(code) ?? "?", overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                _currentWeather ??= Weather(currentDateTime: widget.selectedDateTime);
                                _currentWeather = _currentWeather!.copyWith(currentWeatherCode: newValue);
                              });
                            },
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
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Temperature',
                              suffixText: appSettings.temperatureUnit,
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: _currentWeather?.currentTemperature != widget.currentWeather?.currentTemperature,
                              icon: Icon(Weather.currentTemperatureIconData),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final parsedValue = double.tryParse(value);
                              if (parsedValue == null) return "Please enter valid number";
                              return null;
                            },
                            onChanged: (String newValue) {
                              setState(() {
                                _currentWeather ??= Weather(currentDateTime: widget.selectedDateTime);
                                _currentWeather = _currentWeather!.copyWith(currentTemperature: Weather.convertTemperatureToCelsius(double.tryParse(_currentTemperatureController.text.trim()), appSettings.temperatureUnit));
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
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Precipitation',
                              suffixText: appSettings.precipitationUnit,
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.currentWeather?.dayAccumulatedPrecipitation != _currentWeather?.dayAccumulatedPrecipitation,
                              icon: Icon(Weather.dayAccumulatedPrecipitationIconData),
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
                                _currentWeather ??= Weather(currentDateTime: widget.selectedDateTime);
                                _currentWeather = _currentWeather?.copyWith(dayAccumulatedPrecipitation: Weather.convertPrecipitationToMm(double.tryParse(_dayAccumulatedPrecipitationController.text.trim()), appSettings.precipitationUnit));
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
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Humidity',
                              suffixText: '%',
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.currentWeather?.currentHumidity != _currentWeather?.currentHumidity,
                              icon: const Icon(Weather.currentHumidityIconData),
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
                                _currentWeather ??= Weather(currentDateTime: widget.selectedDateTime);
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
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Wind Speed',
                              suffixText: appSettings.windSpeedUnit,
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.currentWeather?.currentWindSpeed != _currentWeather?.currentWindSpeed,
                              icon: const Icon(Weather.currentWindSpeedIconData),
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
                                _currentWeather ??= Weather(currentDateTime: widget.selectedDateTime);
                                _currentWeather = _currentWeather?.copyWith(currentWindSpeed: Weather.convertWindSpeedToKmh(double.tryParse(_currentWindSpeedController.text.trim()), appSettings.windSpeedUnit));
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
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Soil Moisture',
                              suffixText: 'm³/m³',
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: widget.currentWeather?.currentSoilMoisture0to7cm != _currentWeather?.currentSoilMoisture0to7cm,
                              icon: const Icon(Weather.currentSoilMoisture0to7cmIconData),
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
                                _currentWeather ??= Weather(currentDateTime: widget.selectedDateTime);
                                _currentWeather = _currentWeather?.copyWith(currentSoilMoisture0to7cm: double.tryParse(_currentSoilMoisture0to7cmController.text.trim()));
                              });
                            },
                            onFieldSubmitted: (_) => _save(),
                          ),
                          
                          const SizedBox(height: 2),
                          Text(
                            "Weather data by Open-Meteo.com",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
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
                          icon: widget.weatherService.status == WeatherStatus.searching 
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
                          onPressed: _save,
                          child: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}