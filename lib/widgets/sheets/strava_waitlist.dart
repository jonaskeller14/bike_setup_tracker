import 'package:flutter/material.dart';

import '../../icons/simple_icons.dart';
import 'sheet_header.dart';

class StravaWaitlist extends StatelessWidget {
  const StravaWaitlist({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SheetHeader(
            title: 'Strava Sync',
            leadingIcon: Icon(SimpleIcons.strava, color: Color(0xFFFC4C02)),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Strava Sync is at capacity",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Strava's API limits how many active users we can sync at once. "
                    "We're temporarily not accepting new subscriptions to keep sync "
                    "reliable for current users. We'll open new spots as soon as we can.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }
}
