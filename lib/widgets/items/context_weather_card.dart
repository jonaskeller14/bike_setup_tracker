import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_weather.dart';

class ContextWeatherCard extends StatelessWidget {
  final ContextWeather? weather;

  const ContextWeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    if (weather == null) return const SizedBox.shrink();

    final appSettings = context.watch<AppSettings>();

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpansionTile(
            dense: true,
            shape: const Border(),
            collapsedShape: const Border(),
            leading: Icon(weather!.getIconData()),
            title: Text("Weather: ${weather!.getWeatherCodeLabel() ?? '-'}"),
            children: [
              ListTile(
                leading: const Icon(ContextWeather.currentTemperatureIconData),
                title: SelectableText(
                  "Temperature: ${ContextWeather.convertTemperatureFromCelsius(weather!.currentTemperature, appSettings.temperatureUnit)?.round() ?? '-'} ${appSettings.temperatureUnit}",
                ),
                dense: true,
                enabled: weather!.currentTemperature != null,
              ),
              ListTile(
                leading: const Icon(ContextWeather.dayAccumulatedPrecipitationIconData),
                title: SelectableText(
                  "Precipitation: ${ContextWeather.convertPrecipitationFromMm(weather!.dayAccumulatedPrecipitation, appSettings.precipitationUnit)?.round() ?? '-'} ${appSettings.precipitationUnit}",
                ),
                dense: true,
                enabled: weather!.dayAccumulatedPrecipitation != null,
              ),
              ListTile(
                leading: const Icon(ContextWeather.currentHumidityIconData),
                title: SelectableText("Humidity: ${weather!.currentHumidity?.round() ?? '-'} %"),
                dense: true,
                enabled: weather!.currentHumidity != null,
              ),
              ListTile(
                leading: const Icon(ContextWeather.currentWindSpeedIconData),
                title: SelectableText(
                  "Windspeed: ${ContextWeather.convertWindSpeedFromKmh(weather!.currentWindSpeed, appSettings.windSpeedUnit)?.round() ?? '-'} ${appSettings.windSpeedUnit}",
                ),
                dense: true,
                enabled: weather!.currentWindSpeed != null,
              ),
              ListTile(
                leading: const Icon(ContextWeather.currentSoilMoisture0to7cmIconData),
                title: SelectableText(
                  "Soil Moisture: ${weather!.currentSoilMoisture0to7cm?.toStringAsFixed(2) ?? '-'} m³/m³",
                ),
                dense: true,
                enabled: weather!.currentSoilMoisture0to7cm != null,
              ),
            ],
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              weather!.condition?.iconData ?? Icons.question_mark_sharp,
              color: weather!.condition?.color,
            ),
            title: SelectableText('Condition: ${weather!.condition?.value ?? "-"}'),
            dense: true,
            enabled: weather!.condition != null,
          ),
        ],
      ),
    );
  }
}
