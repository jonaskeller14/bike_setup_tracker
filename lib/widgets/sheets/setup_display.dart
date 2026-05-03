import 'package:flutter/material.dart';
import '../../models/setup.dart';
import '../../pages/details/setup_details_page.dart';

Future<void> showSetupDetailsSheet({required BuildContext context, required Setup setup}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (BuildContext context) => SafeArea(
      child: SetupDetailsPageContent(setup: setup)
    ),
  );
}
