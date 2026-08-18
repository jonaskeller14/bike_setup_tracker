import 'package:flutter/material.dart';

import '../../models/setup.dart';
import '../../pages/details/setup_details_page.dart';
import '../current_setup_highlight.dart';

Future<void> showSetupDetailsSheet({required BuildContext context, required Setup setup}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    backgroundColor: setup.isCurrent
        ? CurrentSetupHighlight.opaqueFill(Theme.of(context).colorScheme)
        : Theme.of(context).colorScheme.surface,
    builder: (BuildContext context) => SafeArea(
      child: SetupDetailsPageContent(setup: setup, showSheetActions: true, showCloseButton: true),
    ),
  );
}
