import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../icons/simple_icons.dart';
import '../../../l10n/l10n.dart';
import '../../../models/app_settings.dart';
import '../../../models/feedback/ride_feedback.dart';
import '../../../models/filters/layer_filter.dart';
import '../../../models/setup.dart';
import '../../../repositories/app_repository.dart';
import '../../../services/subscription_service.dart';
import '../../../utils/filter_actions.dart';
import '../../text/sheet_section_title.dart';
import '../filter.dart';
import 'isolatable_chips.dart';

class LayerFilterSection extends StatelessWidget {
  /// [FilterSection.mapLayers] or [FilterSection.timelineLayers].
  final FilterSection section;

  const LayerFilterSection({super.key, required this.section});

  IconData _icon(TimelineLayer layer) => switch (layer) {
    TimelineLayer.setups => Setup.iconData,
    TimelineLayer.activities => SimpleIcons.strava,
    TimelineLayer.tasks => Icons.check_box_outlined,
    TimelineLayer.installations => Icons.swap_horiz,
    TimelineLayer.feedback => RideFeedback.iconData,
  };

  String _label(AppLocalizations l10n, TimelineLayer layer) => switch (layer) {
    TimelineLayer.setups => l10n.filterLayerSetups,
    TimelineLayer.activities =>
      section == FilterSection.mapLayers ? l10n.filterLayerStravaActivities : l10n.filterLayerActivities,
    TimelineLayer.tasks => l10n.filterLayerTasks,
    TimelineLayer.installations => l10n.filterLayerInstallations,
    TimelineLayer.feedback => l10n.filterLayerFeedback,
  };

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<AppRepository>().filters;
    final appSettings = context.watch<AppSettings>();
    final stravaActive = appSettings.enableStrava && context.watch<SubscriptionService>().hasStravaEntitlement;
    final layers = FilterActions.availableLayers({section}, appSettings: appSettings, stravaActive: stravaActive);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetSectionTitle(title: context.l10n.filterVisibilityTitle),
        IsolatableChips(
          options: [
            for (final layer in layers)
              IsolatableChipOption(
                icon: _icon(layer),
                label: _label(context.l10n, layer),
                selected: filters.layers.shows(layer),
                onChanged: (selected) => filters.layers = filters.layers.copyWith(
                  hidden: toggled(filters.layers.hidden, layer, selected: !selected),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
