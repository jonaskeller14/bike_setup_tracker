import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/feedback/test_session.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../utils/automation_ids.dart';
import '../../utils/feedback_actions.dart';
import '../../utils/setup_actions.dart';
import '../../utils/test_session_actions.dart';
import '../sheets/compare_setups.dart';

class SetupOptionsMenu extends StatelessWidget {
  final Setup setup;

  /// Hero tag of the tile header, so "Add Feedback" flies it into the form.
  final String? heroTag;

  const SetupOptionsMenu({
    super.key,
    required this.setup,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    // A session starts from the setup the bike rides now, and a bike runs one at a time.
    final appRepository = context.watch<AppRepository>();
    final canStartSession =
        appRepository.setupHistory.isCurrent(setup.id) && appRepository.runningSessionFor(setup.bike) == null;

    return PopupMenuButton<_SetupOption>(
      onSelected: (option) => _handleSelection(context, option),
      itemBuilder: (context) => [
        for (final option in _SetupOption.values)
          if (_isVisible(option, appSettings, canStartSession: canStartSession))
            PopupMenuItem<_SetupOption>(
              value: option,
              child: Row(
                spacing: 10,
                children: [
                  Icon(_iconData(option), size: 20),
                  Flexible(
                    child: Semantics(
                      identifier: option == _SetupOption.compare ? AutomationIds.setupActionsCompare : null,
                      child: Text(option.label, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  IconData _iconData(_SetupOption option) =>
      option == _SetupOption.bookmark && setup.isBookmarked ? Icons.bookmark_remove : option.iconData;

  bool _isVisible(
    _SetupOption option,
    AppSettings appSettings, {
    required bool canStartSession,
  }) {
    return switch (option) {
      _SetupOption.edit || _SetupOption.share || _SetupOption.restore || _SetupOption.compare || _SetupOption.remove => true,
      _SetupOption.bookmark => appSettings.enableSetupBookmark,
      _SetupOption.addFeedback => appSettings.enableRating,
      _SetupOption.startTestSession => appSettings.enableRating && canStartSession,
    };
  }

  Future<void> _handleSelection(
    BuildContext context,
    _SetupOption option,
  ) async {
    switch (option) {
      case _SetupOption.edit:
        await SetupActions.editSetup(context, setup: setup);
      case _SetupOption.bookmark:
        await SetupActions.toggleBookmark(context, setup: setup);
      case _SetupOption.share:
        await SetupActions.shareSetup(context, setup: setup);
      case _SetupOption.restore:
        await SetupActions.duplicateSetup(context, setup: setup);
      case _SetupOption.compare:
        await showCompareSetupsSheet(context, setupA: null, setupB: setup);
      case _SetupOption.addFeedback:
        await FeedbackActions.addFeedbackForSetup(context, setup: setup, heroTag: heroTag);
      case _SetupOption.startTestSession:
        await TestSessionActions.startSession(
          context,
          initialBike: context.read<AppRepository>().bikes[setup.bike],
          baseSetup: setup,
        );
      case _SetupOption.remove:
        await SetupActions.removeSetup(context, setup: setup);
    }
  }
}

enum _SetupOption {
  edit('Edit', Icons.edit),
  bookmark('Bookmark', Icons.bookmark_add_outlined),
  share('Share', Icons.share),
  restore('Restore', Icons.restore),
  compare('Compare', Icons.compare),
  addFeedback('Add Feedback', RideFeedback.iconData),
  startTestSession('Start Test Session', TestSession.iconData),
  remove('Remove', Icons.delete);

  final String label;
  final IconData iconData;

  const _SetupOption(this.label, this.iconData);
}
