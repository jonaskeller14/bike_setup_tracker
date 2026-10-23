import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/feedback/ride_feedback.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';

class FeedbackActions {
  static Future<void> restoreFeedback(BuildContext context, {required RideFeedback feedback}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await appRepository.restoreFeedbacks([feedback]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        'Feedback restored from trash.',
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeFeedbacks([feedback]),
        ),
      ),
    );
  }
}
