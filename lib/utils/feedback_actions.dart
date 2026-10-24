import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bike.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/setup.dart';
import '../pages/forms/feedback_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';

class FeedbackActions {
  static Future<void> addFeedback(
    BuildContext context, {
    Bike? initialBike,
    DateTime? initialDateTimeUtc,
    DateTime? initialDateTimeLocal,
    String? heroTag,
  }) async {
    final appRepository = context.read<AppRepository>();

    final newFeedback = await Navigator.push<RideFeedback>(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackPage.add(
          initialBike: initialBike,
          initialDateTimeUtc: initialDateTimeUtc,
          initialDateTimeLocal: initialDateTimeLocal,
          heroTag: heroTag,
        ),
      ),
    );
    if (newFeedback == null) return;

    await appRepository.addFeedbacks([newFeedback]);
  }

  /// Feedback on [setup]: dated now while it is the bike's active setup,
  /// otherwise at its start, so the new feedback resolves to it.
  static Future<void> addFeedbackForSetup(BuildContext context, {required Setup setup, String? heroTag}) {
    final appRepository = context.read<AppRepository>();
    final (utc, local) = feedbackTimeFor(appRepository, setup);
    return addFeedback(
      context,
      initialBike: appRepository.bikes[setup.bike],
      initialDateTimeUtc: utc,
      initialDateTimeLocal: local,
      heroTag: heroTag,
    );
  }

  static (DateTime utc, DateTime local) feedbackTimeFor(AppRepository appRepository, Setup setup, {DateTime? now}) {
    final localNow = now ?? DateTime.now();
    if (appRepository.resolveSetupId(bikeId: setup.bike, atUtc: localNow.toUtc()) == setup.id) {
      return (localNow.toUtc(), localNow);
    }
    return (setup.datetime, setup.datetimeLocal);
  }

  static Future<void> editFeedback(BuildContext context, {required RideFeedback feedback}) async {
    final appRepository = context.read<AppRepository>();

    final edited = await Navigator.push<RideFeedback>(
      context,
      MaterialPageRoute(builder: (context) => FeedbackPage.edit(feedback: feedback)),
    );
    if (edited == null) return;

    await appRepository.editFeedback(edited);
  }

  static Future<void> removeFeedback(BuildContext context, {required RideFeedback feedback}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    unawaited(HapticFeedback.mediumImpact());
    await appRepository.removeFeedbacks([feedback]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        'Feedback moved to trash.',
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.restoreFeedbacks([feedback]),
        ),
      ),
    );
  }

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
