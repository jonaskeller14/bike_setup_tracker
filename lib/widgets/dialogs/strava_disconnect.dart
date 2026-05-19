import 'package:flutter/material.dart';
import 'dialog_action.dart';

Future<bool> showStravaDisconnectDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog.adaptive(
        title: const Text("Disconnect Strava?"),
        content: const Text(
          "This will revoke the app's access and delete all your synced activities from our secure storage. "
          "Your Strava account itself will not be affected.",
        ),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          adaptiveAction(
            context: context,
            isDestructive: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Disconnect"),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
