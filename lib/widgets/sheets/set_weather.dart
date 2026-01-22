import 'package:bike_setup_tracker/models/weather.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/weather_service.dart';
import '../soil_moisture_legend_table.dart';
import 'sheet.dart';

//FIXME: Check if submit is necessary
//FIXME: Allow partially submit --> or remove values; change validators

Future<Weather?> showSetWeatherSheet({
  required BuildContext context,
  required WeatherService weatherService, 
  required Weather? currentWeather,
  required LocationService locationService,
  required LocationData? currentLocation,
  required DateTime selectedDateTime,
  }) async {
  return showModalBottomSheet<Weather?>(
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
    ); //FIXME: Overwrite condition?
    setFieldsFromWeather();
  }

  @override
  void dispose() {
    _currentTemperatureController.dispose(); 
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final appSettings = context.read<AppSettings>();

    _currentWeather ??= Weather(currentDateTime: widget.selectedDateTime);
    _currentWeather = _currentWeather!.copyWith(
      currentTemperature: Weather.convertTemperatureToCelsius(double.tryParse(_currentTemperatureController.text.trim()), appSettings.temperatureUnit),
      currentHumidity: double.tryParse(_currentHumidityController.text.trim()),
      currentWindSpeed: Weather.convertWindSpeedToKmh(double.tryParse(_currentWindSpeedController.text.trim()), appSettings.windSpeedUnit),
      dayAccumulatedPrecipitation: Weather.convertPrecipitationToMm(double.tryParse(_dayAccumulatedPrecipitationController.text.trim()), appSettings.precipitationUnit),
      currentSoilMoisture0to7cm: double.tryParse(_currentSoilMoisture0to7cmController.text.trim()),
      currentWeatherCode: null, //FIXME
      currentIsDay: null, //TODO
    );

    Navigator.of(context).pop(_currentWeather);
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    return ListenableBuilder(
      listenable: Listenable.merge([widget.locationService, widget.weatherService]),
      builder: (context, child) {
        //FIXME enableFields for dropdowns
        final enableFields = widget.weatherService.status != WeatherStatus.searching && widget.locationService.status != LocationStatus.searching;
        final enableUpdate = enableFields && widget.currentLocation?.latitude != null && widget.currentLocation?.latitude != null;
        return SingleChildScrollView(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
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
                  if ( widget.currentLocation?.latitude == null || widget.currentLocation?.latitude == null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: const Text("Update Weather is not possible without location."),
                      dense: true,
                      contentPadding: const EdgeInsets.only(bottom: 16),
                    ),
                  FilledButton.icon(
                    onPressed: enableUpdate ? updateWeather : null,
                    icon: widget.weatherService.status == WeatherStatus.searching 
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ) 
                        : const Icon(Icons.sync),
                    label: const Text("Update Weather by location"),
                  ),
                  const SizedBox(height: 16),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      suffixText: appSettings.temperatureUnit,
                      icon: Icon(Weather.currentTemperatureIconData),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsedValue = double.tryParse(value);
                      if (parsedValue == null) return "Please enter valid number";
                      return null;
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      suffixText: appSettings.precipitationUnit,
                      icon: Icon(Weather.dayAccumulatedPrecipitationIconData),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsedValue = double.tryParse(value);
                      if (parsedValue == null) return "Please enter valid number";
                      if (parsedValue < 0) return "Value cannot be negative";
                      return null;
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      suffixText: '%',
                      icon: const Icon(Weather.currentHumidityIconData),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsedValue = double.tryParse(value);
                      if (parsedValue == null) return "Please enter valid number";
                      if (parsedValue < 0 || parsedValue > 100) return "Enter a valid value in the range 0..100 %";
                      return null;
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      suffixText: appSettings.windSpeedUnit,
                      icon: const Icon(Weather.currentWindSpeedIconData),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsedValue = double.tryParse(value);
                      if (parsedValue == null) return "Please enter valid number";
                      if (parsedValue < 0) return "Value cannot be negative";
                      return null;
                    },
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 12),  
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("The Average soil water content in the top layer of the soil is expressed as the volumetric mixing ratio—the ratio of the volume of water to the total volume of soil. This value is dynamically calculated based on recent rainfall and evaporation rates, and it serves here as a measurable indicator for determining current trail conditions."),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SoilMoistureLegendTable(),
                        const Text(
                          "Note: Real conditions vary based on soil type (sand, clay, ...) and local effects.", 
                          style: TextStyle(fontStyle: FontStyle.italic)
                        ),
                      ],
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.all(0),
                  ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      suffixText: 'm³/m³',
                      icon: const Icon(Weather.currentSoilMoisture0to7cmIconData),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsedValue = double.tryParse(value);
                      if (parsedValue == null) return "Please enter valid number";
                      if (parsedValue < 0) return "Value cannot be negative";
                      return null;
                    },
                    onFieldSubmitted: (_) => _save(),
                  ),                  
                  const SizedBox(height: 12),
                  //TODO: Add dropdown for weather code
                  const SizedBox(height: 12),
                  //TODO: isDay switch?
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text("Submit"),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}