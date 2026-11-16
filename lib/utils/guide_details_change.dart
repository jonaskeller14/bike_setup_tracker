import '../l10n/l10n.dart';
import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/component_preset.dart';
import 'component_catalog_application.dart';
import 'component_preset_resolver.dart';

/// What choosing catalog details the setup guide was missing changes on a
/// component: its preset map, and a SAG without travel takes the catalog's.
/// Every other adjustment stays as the rider has it.
class GuideDetailsChange {
  final ComponentPreset preset;
  final List<Adjustment> adjustments;

  /// Catalog adjusters the chosen values bring that the previous selection
  /// didn't; the rider decides in the merge sheet how they combine.
  final List<Adjustment> added;
  final Set<String> unknownMaxKeys;
  final String productName;

  const GuideDetailsChange({
    required this.preset,
    required this.adjustments,
    required this.added,
    required this.unknownMaxKeys,
    required this.productName,
  });
}

/// [component], linked to [current], once [chosen] adds the missing details.
GuideDetailsChange planGuideDetailsChange(
  Component component,
  ResolvedPreset current,
  ResolvedPreset chosen,
  AppLocalizations l10n,
) {
  final app = buildCatalogApplication(chosen, l10n);
  final before = {for (final adjustment in buildCatalogApplication(current, l10n).adjustments) adjustment.presetKey};
  final travel = app.adjustments.whereType<SagAdjustment>().firstOrNull?.referenceTravelMm;
  return GuideDetailsChange(
    preset: app.preset,
    adjustments: [
      for (final adjustment in component.adjustments)
        // A SAG with its own travel keeps it: it gives every recorded value its millimetres.
        if (adjustment is SagAdjustment && adjustment.referenceTravelMm == null && travel != null)
          adjustment.copyWith(referenceTravelMm: travel)
        else
          adjustment,
    ],
    added: [
      for (final adjustment in app.adjustments)
        if (!before.contains(adjustment.presetKey)) adjustment,
    ],
    unknownMaxKeys: app.unknownMaxKeys,
    productName: app.name,
  );
}
