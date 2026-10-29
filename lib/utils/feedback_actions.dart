import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bike.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../pages/forms/feedback_page.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';

class FeedbackActions {
  /// Whether a feedback was saved.
  static Future<bool> addFeedback(
    BuildContext context, {
    Bike? initialBike,
    DateTime? initialDateTimeUtc,
    DateTime? initialDateTimeLocal,
    String? heroTag,
    StravaActivity? stravaActivity,
  }) {
    return _pushAndAdd(
      context,
      (_) => FeedbackPage.add(
        initialBike: initialBike,
        initialDateTimeUtc: initialDateTimeUtc,
        initialDateTimeLocal: initialDateTimeLocal,
        heroTag: heroTag,
        stravaActivity: stravaActivity,
      ),
    );
  }

  static Future<bool> addFeedbackFromStravaActivity(BuildContext context, {required StravaActivity stravaActivity}) {
    return _pushAndAdd(
      context,
      (context) => FeedbackPage.addFromStravaActivity(context: context, stravaActivity: stravaActivity),
    );
  }

  static Future<bool> _pushAndAdd(BuildContext context, FeedbackPage Function(BuildContext) page) async {
    final appRepository = context.read<AppRepository>();

    final newFeedback = await Navigator.push<RideFeedback>(context, MaterialPageRoute(builder: page));
    if (newFeedback == null) return false;

    await appRepository.addFeedbacks([newFeedback]);
    return true;
  }

  /// Feedback on [setup]: dated now while it is the bike's active setup,
  /// otherwise at its start, so the new feedback resolves to it.
  static Future<bool> addFeedbackForSetup(
    BuildContext context, {
    required Setup setup,
    String? heroTag,
    StravaActivity? stravaActivity,
  }) {
    final appRepository = context.read<AppRepository>();
    final (utc, local) = feedbackTimeFor(appRepository, setup, stravaActivity: stravaActivity);
    return addFeedback(
      context,
      initialBike: appRepository.bikes[setup.bike],
      initialDateTimeUtc: utc,
      initialDateTimeLocal: local,
      heroTag: heroTag,
      stravaActivity: stravaActivity,
    );
  }

  /// For a feedback on [setup] of a [stravaActivity], the ride's own time when
  /// that resolves to [setup], so the ride's last setup is dated within the ride.
  static (DateTime utc, DateTime local) feedbackTimeFor(
    AppRepository appRepository,
    Setup setup, {
    DateTime? now,
    StravaActivity? stravaActivity,
  }) {
    final ride = stravaActivity?.feedbackTime(now: now);
    if (ride != null && appRepository.resolveSetupId(bikeId: setup.bike, atUtc: ride.$1) == setup.id) return ride;

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
