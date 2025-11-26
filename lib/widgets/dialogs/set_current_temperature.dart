import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/weather.dart';

Future<double?> showSetCurrentTemperatureDialog(BuildContext context, Weather? currentWeather) async {
  return await showDialog<double?>(
    context: context,
    builder: (BuildContext context) {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: currentWeather?.currentTemperature?.toString() ?? '');
      return AlertDialog(
        scrollable: true,
        title: Text('Set Temperature'),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: formKey,
            child: Column(
              children: <Widget>[
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
                    suffixText: '°C',
                    icon: Icon(Icons.thermostat),
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
                    Navigator.of(context).pop(double.parse(controller.text.trim()));
                  },
                ),
              ],
            ),
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
