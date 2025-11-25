import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/weather.dart';

Future<double?> showSetCurrentWindSpeedDialog(BuildContext context, Weather? currentWeather) async {
  return await showDialog<double?>(
    context: context,
    builder: (BuildContext context) {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: currentWeather?.currentWindSpeed.toString() ?? '');
      return AlertDialog(
        scrollable: true,
        title: Text('Set Wind Speed'),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'Wind Speed',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    suffixText: 'km/h',
                    icon: Icon(Icons.air),
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
