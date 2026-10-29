import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/strava/strava_activity.dart';
import '../../repositories/app_repository.dart';
import '../../services/strava_service.dart';
import '../../utils/feedback_actions.dart';

/// "Add feedback" call to action for a ride that still needs one. Takes no
/// space otherwise, so it can sit in any column.
class StravaFeedbackPrompt extends StatelessWidget {
  final StravaActivity stravaActivity;
  final bool compact;

  const StravaFeedbackPrompt({super.key, required this.stravaActivity, this.compact = false});

  @override
  Widget build(BuildContext context) {
    // Checked first: the Strava service isn't needed while the feature is off.
    if (!context.select<AppSettings, bool>((s) => s.enableRating)) return const SizedBox.shrink();
    if (!context.select<StravaService, bool>((s) => s.isConnected)) return const SizedBox.shrink();
    if (!context.select<AppRepository, bool>((r) => r.activityNeedsFeedback(stravaActivity))) {
      return const SizedBox.shrink();
    }

    void onPressed() {
      unawaited(HapticFeedback.selectionClick());
      unawaited(FeedbackActions.addFeedbackFromStravaActivity(context, stravaActivity: stravaActivity));
    }

    if (compact) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(RideFeedback.iconData, size: 14),
        label: const Text('Add feedback'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(RideFeedback.iconData),
          label: const Text('Add feedback for this ride'),
        ),
      ),
    );
  }
}
