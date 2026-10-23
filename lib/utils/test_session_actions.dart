import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/feedback/test_session.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';

class TestSessionActions {
  static Future<void> restoreTestSession(BuildContext context, {required TestSession session}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await appRepository.restoreTestSessions([session]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Test session '${session.displayName}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeTestSessions([session]),
        ),
      ),
    );
  }
}
