import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/context/context_weather.dart';

class ContextWeatherCardDiff extends StatelessWidget {
  final ContextWeather? weatherA;
  final ContextWeather? weatherB;

  const ContextWeatherCardDiff({
    super.key,
    required this.weatherA,
    required this.weatherB,
  });

  @override
  Widget build(BuildContext context) {
    if (weatherA == null && weatherB == null) return const SizedBox.shrink();

    final settings = context.watch<AppSettings>();
    final weatherCodeDiffer = weatherA?.getWeatherCodeLabel() != weatherB?.getWeatherCodeLabel();
    final conditionDiffer = weatherA?.condition != weatherB?.condition;

    String temperature(ContextWeather? weather) {
      final value = ContextWeather.convertTemperatureFromCelsius(
        weather?.currentTemperature,
        settings.temperatureUnit,
      );
      return value == null ? '-' : '${value.round()} ${settings.temperatureUnit}';
    }

    String precipitation(ContextWeather? weather) {
      final value = ContextWeather.convertPrecipitationFromMm(
        weather?.dayAccumulatedPrecipitation,
        settings.precipitationUnit,
      );
      return value == null ? '-' : '${value.round()} ${settings.precipitationUnit}';
    }

    String humidity(ContextWeather? weather) =>
        weather?.currentHumidity == null ? '-' : '${weather!.currentHumidity!.round()} %';

    String wind(ContextWeather? weather) {
      final value = ContextWeather.convertWindSpeedFromKmh(weather?.currentWindSpeed, settings.windSpeedUnit);
      return value == null ? '-' : '${value.round()} ${settings.windSpeedUnit}';
    }

    String soilMoisture(ContextWeather? weather) => weather?.currentSoilMoisture0to7cm == null
        ? '-'
        : '${weather!.currentSoilMoisture0to7cm!.toStringAsFixed(2)} m³/m³';

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpansionTile(
            key: const Key('compare-disclosure-conditions'),
            dense: true,
            shape: const Border(),
            collapsedShape: const Border(),
            leading: _DifferenceLeading(
              iconA: weatherA?.getIconData() ?? Icons.question_mark_sharp,
              iconB: weatherB?.getIconData() ?? Icons.question_mark_sharp,
              different: weatherCodeDiffer,
            ),
            title: _ComparisonTextRow(
              valueA: weatherA?.getWeatherCodeLabel() ?? '-',
              valueB: weatherB?.getWeatherCodeLabel() ?? '-',
            ),
            children: [
              _WeatherRow(
                icon: ContextWeather.currentTemperatureIconData,
                valueA: temperature(weatherA),
                valueB: temperature(weatherB),
              ),
              _WeatherRow(
                icon: ContextWeather.dayAccumulatedPrecipitationIconData,
                valueA: precipitation(weatherA),
                valueB: precipitation(weatherB),
              ),
              _WeatherRow(
                icon: ContextWeather.currentHumidityIconData,
                valueA: humidity(weatherA),
                valueB: humidity(weatherB),
              ),
              _WeatherRow(
                icon: ContextWeather.currentWindSpeedIconData,
                valueA: wind(weatherA),
                valueB: wind(weatherB),
              ),
              _WeatherRow(
                icon: ContextWeather.currentSoilMoisture0to7cmIconData,
                valueA: soilMoisture(weatherA),
                valueB: soilMoisture(weatherB),
              ),
            ],
          ),
          const Divider(height: 1),
          _WeatherRow(
            icon: weatherA?.condition?.iconData ?? Icons.question_mark_sharp,
            iconB: weatherB?.condition?.iconData ?? Icons.question_mark_sharp,
            iconColor: weatherA?.condition == weatherB?.condition ? weatherA?.condition?.color : null,
            valueA: weatherA?.condition?.value ?? '-',
            valueB: weatherB?.condition?.value ?? '-',
            different: conditionDiffer,
          ),
        ],
      ),
    );
  }
}

class _WeatherRow extends StatelessWidget {
  final IconData icon;
  final IconData? iconB;
  final Color? iconColor;
  final String valueA;
  final String valueB;
  final bool different;

  const _WeatherRow({
    required this.icon,
    this.iconB,
    this.iconColor,
    required this.valueA,
    required this.valueB,
    this.different = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _DifferenceLeading(
        iconA: icon,
        iconB: iconB,
        color: iconColor,
        different: different,
      ),
      title: _ComparisonTextRow(valueA: valueA, valueB: valueB),
      dense: true,
    );
  }
}

class _DifferenceLeading extends StatelessWidget {
  final IconData iconA;
  final IconData? iconB;
  final Color? color;
  final bool different;

  const _DifferenceLeading({
    required this.iconA,
    this.iconB,
    this.color,
    required this.different,
  });

  @override
  Widget build(BuildContext context) {
    if (different && iconB != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(iconA, size: 18, color: color),
          Icon(iconB, size: 18, color: color),
        ],
      );
    }
    return Icon(iconA, color: color);
  }
}

class _ComparisonTextRow extends StatelessWidget {
  final String valueA;
  final String valueB;

  const _ComparisonTextRow({required this.valueA, required this.valueB});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Expanded(
          child: SelectableText(valueA),
        ),
        Expanded(
          child: SelectableText(valueB),
        ),
      ],
    );
  }
}
