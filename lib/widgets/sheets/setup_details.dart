import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pages/details/setup_details_page.dart';
import '../../repositories/app_repository.dart';
import '../current_setup_highlight.dart';

Future<void> showSetupDetailsSheet({required BuildContext context, required String setupId}) async {
  final setup = context.read<AppRepository>().setups[setupId];

  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    backgroundColor: setup?.isCurrent ?? false
        ? CurrentSetupHighlight.opaqueFill(Theme.of(context).colorScheme)
        : Theme.of(context).colorScheme.surface,
    builder: (BuildContext context) => SafeArea(
      child: SetupDetailsPageContent.sheet(setupId: setupId),
    ),
  );
}
