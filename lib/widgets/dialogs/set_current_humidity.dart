import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/weather.dart';

Future<double?> showSetCurrentHumidityDialog(BuildContext context, Weather? currentWeather) async {
  return await showDialog<double?>(
    context: context,
    builder: (BuildContext context) {
      final currentTempFormKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: currentWeather?.currentHumidity?.toString() ?? '');
      return AlertDialog(
        scrollable: true,
        title: const Text('Set Humidity'),
        content: Form(
          key: currentTempFormKey,
          child: Column(
            children: <Widget>[
              const Text("Enter the current relative air humidity as a percentage."),
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
                  hintText: 'Humidity',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: '%',
                  icon: const Icon(Weather.currentHumidityIconData),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a value';
                  }
                  final parsedValue = double.tryParse(value);
                  if (parsedValue == null) return "Please enter valid number";
                  if (parsedValue < 0 || parsedValue > 100) return "Enter a valid value in the range 0..100 %";
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (!currentTempFormKey.currentState!.validate()) return;
                  Navigator.of(context).pop(double.parse(controller.text.trim()));
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
              if (!currentTempFormKey.currentState!.validate()) return;
              Navigator.of(context).pop(double.parse(controller.text.trim()));
            },
            child: const Text("Submit"),
          ),
        ],
      );
    }
  );
}
