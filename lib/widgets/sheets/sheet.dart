import 'package:flutter/material.dart';

Text sheetTitle(BuildContext context, String title) {
  return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
}

IconButton sheetCloseButton(BuildContext context) {
  return IconButton.filled(
    iconSize: 20, 
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.close), 
  );
}
