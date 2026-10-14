import 'package:flutter/material.dart';

import 'sheet_header.dart';

/// Sheet body shown while a long-running step runs; the sheet must not be closed meanwhile.
class SheetProgressContent extends StatelessWidget {
  final String title;
  final String message;

  const SheetProgressContent({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: title, showClose: false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  "This can take a moment for large datasets.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
