import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_hint.dart';
import '../../services/app_hint_service.dart';
import 'garage_list_hint.dart';

/// Maps hint IDs to their inline presentation, keeping eligibility out of screens.
class AppHintSlot extends StatelessWidget {
  const AppHintSlot({super.key, required this.placement});

  final AppHintPlacement placement;

  @override
  Widget build(BuildContext context) {
    final hint = context.watch<AppHintService>().activeHintFor(placement);
    return switch (hint) {
      AppHint.garageGesturesV1 => GarageListHint(
        onDismiss: () => unawaited(
          context.read<AppHintService>().dismiss(AppHint.garageGesturesV1),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
