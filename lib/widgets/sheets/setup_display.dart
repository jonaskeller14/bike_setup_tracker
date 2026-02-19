import 'package:flutter/material.dart';
import '../../models/setup.dart';
import '../../pages/setup_display_page.dart';

Future<void> showSetupDisplaySheet({required BuildContext context, required Setup setup}) async {
  return await showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (BuildContext context) => SafeArea(
      child: SetupDisplayPageContent(setup: setup)
    ),
  );
}
