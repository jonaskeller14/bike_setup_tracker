import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;

Future<geo.Location?> showSetLocationDialog(BuildContext context, ) async {
  return await showDialog<geo.Location?>(
    context: context,
    builder: (BuildContext context) {
      final currentTempFormKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      return AlertDialog(
        scrollable: true,
        title: Text('Set Location by Address'),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: currentTempFormKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'Address',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    icon: Icon(Icons.pin_drop),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter an address';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!currentTempFormKey.currentState!.validate()) return;
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
            onPressed: () async {
              if (!currentTempFormKey.currentState!.validate()) return;
              List<geo.Location> locations = await geo.locationFromAddress(controller.text.trim());
              if (!context.mounted) return;
              Navigator.of(context).pop(locations.firstOrNull);
            },
            child: const Text("Submit"),
          ),
        ],
      );
    }
  );
}
