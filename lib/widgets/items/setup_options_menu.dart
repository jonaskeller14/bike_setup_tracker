import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/setup.dart';
import '../../models/strava/strava_activity.dart';
import '../../utils/automation_ids.dart';
import '../../utils/feedback_actions.dart';
import '../../utils/setup_actions.dart';
import '../sheets/compare_setups.dart';

class SetupOptionsMenu extends StatelessWidget {
  final Setup setup;
  final String? heroTag; // Hero tag of the setup tile header
  final StravaActivity? stravaActivity;
  final bool enabled;

  const SetupOptionsMenu({
    super.key,
    required this.setup,
    this.heroTag,
    this.stravaActivity,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return PopupMenuButton<_SetupOption>(
      enabled: enabled,
      onSelected: (option) => _handleSelection(context, option),
      itemBuilder: (context) => [
        for (final option in _SetupOption.values)
          if (_isVisible(option, appSettings))
            PopupMenuItem<_SetupOption>(
              value: option,
              child: Row(
                spacing: 10,
                children: [
                  Icon(_iconData(option), size: 20),
                  Flexible(
                    child: Semantics(
                      identifier: option == _SetupOption.compare ? AutomationIds.setupActionsCompare : null,
                      child: Text(option.label(context.l10n), overflow: TextOverflow.ellipsis),
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

  bool _isVisible(_SetupOption option, AppSettings appSettings) {
    return switch (option) {
      _SetupOption.edit || _SetupOption.share || _SetupOption.restore || _SetupOption.compare || _SetupOption.remove => true,
      _SetupOption.bookmark => appSettings.enableSetupBookmark,
      _SetupOption.addFeedback => appSettings.enableRating,
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
        await FeedbackActions.addFeedbackForSetup(
          context,
          setup: setup,
          heroTag: heroTag,
          stravaActivity: stravaActivity,
        );
      case _SetupOption.remove:
        await SetupActions.removeSetup(context, setup: setup);
    }
  }
}

enum _SetupOption {
  edit(Icons.edit),
  bookmark(Icons.bookmark_add_outlined),
  share(Icons.share),
  restore(Icons.restore),
  compare(Icons.compare),
  addFeedback(RideFeedback.iconData),
  remove(Icons.delete);

  final IconData iconData;

  const _SetupOption(this.iconData);

  String label(AppLocalizations l10n) => switch (this) {
    edit => l10n.edit,
    bookmark => l10n.setupTooltipBookmark,
    share => l10n.share,
    restore => l10n.setupOptionRestore,
    compare => l10n.setupOptionCompare,
    addFeedback => l10n.setupOptionAddFeedback,
    remove => l10n.remove,
  };
}
