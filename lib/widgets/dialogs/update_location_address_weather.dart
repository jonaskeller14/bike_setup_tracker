import 'package:flutter/material.dart';

Future<int?> showUpdateLocationAddressWeatherDialog(
  BuildContext context, {
  List<bool> buttonsEnabled = const [true, true, true],
}) async {
  final result = await showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text("Update?"),
        actionsOverflowAlignment: OverflowBarAlignment.start,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choose the type of update you would like to perform."),
            SizedBox(height: 12),
            Text(
              "1. Location: Required GPS to fetch latitude, longitude, and altitude.\n2. Address: Requires lat/lon to retrieve street address.\n3. Weather: Requires lat/lon to retrieve weather.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: buttonsEnabled[0] ? () => Navigator.of(context).pop(0) : null,
            child: Text("1. Find location via GPS"),
          ),
          ElevatedButton(
            onPressed: buttonsEnabled[1] ? () => Navigator.of(context).pop(1) : null,
            child: Text("2. Update Address from location"),
          ),
          ElevatedButton(
            onPressed: buttonsEnabled[2] ? () => Navigator.of(context).pop(2) : null,
            child: Text("3. Update Weather"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text("Cancel"),
          ),
        ],
      );
    },
  );
  return result;
}
