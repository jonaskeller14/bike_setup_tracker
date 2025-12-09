import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/weather.dart';
import '../../models/app_settings.dart';

Future<double?> showSetDayAccumulatedPrecipitationDialog(BuildContext context, Weather? currentWeather) async {
  final appSettings = context.read<AppSettings>();

  return await showDialog<double?>(
    context: context,
    builder: (BuildContext context) {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: currentWeather?.dayAccumulatedPrecipitation == null ? null : Weather.convertPrecipitationFromMm(currentWeather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit).toString());
      return AlertDialog(
        scrollable: true,
        title: const Text('Set Precipitation'),
        content: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              Text("Enter the total rainfall accumulated since midnight (00:00) today in ${appSettings.precipitationUnit}."),
              SizedBox(height: 16),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),],
                controller: controller,
                autofocus: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Precipitation',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: appSettings.precipitationUnit,
                  icon: Icon(Icons.water_drop),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a value';
                  }
                  final parsedValue = double.tryParse(value);
                  if (parsedValue == null) return "Please enter valid number";
                  if (parsedValue < 0) return "Value cannot be negative";
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (!formKey.currentState!.validate()) return;
                  final newValue = double.parse(controller.text.trim());
                  Navigator.of(context).pop(Weather.convertPrecipitationToMm(newValue, appSettings.precipitationUnit));
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
