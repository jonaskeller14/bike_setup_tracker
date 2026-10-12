import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/setup_actions.dart';

/// Prominent call to action in today's timeline section while no setup has
/// been recorded today.
class TodayAddSetupButton extends StatelessWidget {
  const TodayAddSetupButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () async {
            unawaited(HapticFeedback.lightImpact());
            await SetupActions.addSetup(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Setup'),
        ),
      ),
    );
  }
}
