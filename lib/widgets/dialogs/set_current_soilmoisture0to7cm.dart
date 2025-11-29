import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/weather.dart';
import '../soil_moisture_legend_table.dart';

Future<double?> showSetCurrentSoilMoisture0to7cmDialog(BuildContext context, Weather? currentWeather) async {
  return await showDialog<double?>(
    context: context,
    builder: (BuildContext context) {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: currentWeather?.currentSoilMoisture0to7cm?.toString() ?? '');
      return AlertDialog(
        scrollable: true,
        title: Text('Set Soil Moisture 0-7cm'),
        content: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              const Text("The Average soil water content in the top layer of the soil is expressed as the volumetric mixing ratio—the ratio of the volume of water to the total volume of soil. This value is dynamically calculated based on recent rainfall and evaporation rates, and it serves here as a measurable indicator for determining current trail conditions."),
              const SoilMoistureLegendTable(),
              const Text(
                "Note: Real conditions vary based on soil type (sand, clay, ...) and local effects.", 
                style: TextStyle(fontStyle: FontStyle.italic)
              ),
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
                  hintText: 'Soil Moisture',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: 'm³/m³',
                  icon: Icon(Icons.spa),
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
