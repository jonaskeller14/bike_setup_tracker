import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/rating_entry.dart';
import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/setup_comparison_service.dart';
import '../../utils/setup_actions.dart';
import '../sheets/compare_setups.dart';

class SetupOptionsMenu extends StatelessWidget {
  final Setup setup;

  const SetupOptionsMenu({
    super.key,
    required this.setup,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final setups = context.read<AppRepository>().setups.values;

    return PopupMenuButton<_SetupOption>(
      onSelected: (option) => _handleSelection(context, option),
      itemBuilder: (context) => [
        for (final option in _SetupOption.values)
          if (_isVisible(option, setups, appSettings))
            PopupMenuItem<_SetupOption>(
              value: option,
              child: Row(
                spacing: 10,
                children: [
                  Icon(option.iconData, size: 20),
                  Text(option.label),
                ],
              ),
            ),
      ],
    );
  }

  bool _isVisible(
    _SetupOption option,
    Iterable<Setup> setups,
    AppSettings appSettings,
  ) {
    return switch (option) {
      _SetupOption.edit || _SetupOption.share || _SetupOption.restore || _SetupOption.remove => true,
      _SetupOption.addRating => appSettings.enableRating,
      _SetupOption.compare => SetupComparisonService.resolveTargets(setupB: setup, setups: setups) is SetupComparisonTargets,
    };
  }

  Future<void> _handleSelection(
    BuildContext context,
    _SetupOption option,
  ) async {
    switch (option) {
      case _SetupOption.edit:
        await SetupActions.editSetup(context, setup: setup);
      case _SetupOption.share:
        await SetupActions.shareSetup(context, setup: setup);
      case _SetupOption.restore:
        await SetupActions.duplicateSetup(context, setup: setup);
      case _SetupOption.compare:
        await showCompareSetupsSheet(context, setupA: null, setupB: setup);
      case _SetupOption.addRating:
        await SetupActions.addRatingEntryForSetup(context, setup: setup);
      case _SetupOption.remove:
        await SetupActions.removeSetup(context, setup: setup);
    }
  }
}

enum _SetupOption {
  edit('Edit', Icons.edit),
  share('Share', Icons.share),
  restore('Restore', Icons.restore),
  compare('Compare', Icons.compare),
  addRating('Add Rating', RatingEntry.iconData),
  remove('Remove', Icons.delete);

  final String label;
  final IconData iconData;

  const _SetupOption(this.label, this.iconData);
}
