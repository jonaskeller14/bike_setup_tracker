import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../icons/simple_icons.dart';
import '../../../models/app_settings.dart';
import '../../../models/filters/layer_filter.dart';
import '../../../models/rating/rating.dart';
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
    TimelineLayer.ratingEntries => Rating.iconData,
  };

  String _label(TimelineLayer layer) => switch (layer) {
    TimelineLayer.setups => "Setups",
    TimelineLayer.activities => section == FilterSection.mapLayers ? "Strava Activities" : "Activities",
    TimelineLayer.tasks => "Tasks",
    TimelineLayer.installations => "Installations",
    TimelineLayer.ratingEntries => "Ratings",
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
        const SheetSectionTitle(title: "Visibility"),
        IsolatableChips(
          options: [
            for (final layer in layers)
              IsolatableChipOption(
                icon: _icon(layer),
                label: _label(layer),
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
