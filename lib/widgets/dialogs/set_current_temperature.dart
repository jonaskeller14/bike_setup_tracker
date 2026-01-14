import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/weather.dart';
import '../../models/app_settings.dart';

Future<double?> showSetCurrentTemperatureDialog(BuildContext context, Weather? currentWeather) async {
  final appSettings = context.read<AppSettings>();
  
  return await showDialog<double?>(
    context: context,
    builder: (BuildContext context) {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: currentWeather?.currentTemperature == null ? null : Weather.convertTemperatureFromCelsius(currentWeather!.currentTemperature!, appSettings.temperatureUnit).toString());
      return AlertDialog(
        scrollable: true,
        title: const Text('Set Temperature'),
        content: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              Text("Enter the current air temperature in ${appSettings.temperatureUnit}."),
              SizedBox(height: 16),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
                controller: controller,
                autofocus: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Temperature',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: appSettings.temperatureUnit,
                  icon: Icon(Weather.currentTemperatureIconData),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a value';
                  }
                  final parsedValue = double.tryParse(value);
                  if (parsedValue == null) return "Please enter valid number";
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (!formKey.currentState!.validate()) return;
                  final newValue = double.parse(controller.text.trim());
                  Navigator.of(context).pop(Weather.convertTemperatureToCelsius(newValue, appSettings.temperatureUnit));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {Navigator.of(context).pop(null);},
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop(double.parse(controller.text.trim()));
            },
            child: const Text("Submit"),
          ),
        ],
      );
    }
  );
}
