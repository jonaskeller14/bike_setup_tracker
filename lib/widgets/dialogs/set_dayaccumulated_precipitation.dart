import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/weather.dart';

Future<double?> showSetDayAccumulatedPrecipitationDialog(BuildContext context, Weather? currentWeather) async {
  return await showDialog<double?>(
    context: context,
    builder: (BuildContext context) {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: currentWeather?.dayAccumulatedPrecipitation?.toString() ?? '');
      return AlertDialog(
        scrollable: true,
        title: Text('Set Precipitation'),
        content: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
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
                  suffixText: 'mm',
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
