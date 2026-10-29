import 'package:flutter/foundation.dart';

import '../models/component/component.dart';
import '../repositories/app_repository.dart';
import '../repositories/component_catalog_repository.dart';
import '../utils/catalog_revisions.dart';

class CatalogMigrationService {
  /// Applies the silent catalog fixes to every component linked to an older
  /// revision of its brand file. Reviews stay pending until the rider accepts
  /// or dismisses them on the component page.
  static Future<void> run(AppRepository repository, ComponentCatalogRepository catalog) async {
    try {
      final updates = <Component>[];
      for (final component in repository.components.values.toList()) {
        final preset = component.preset;
        if (preset == null) continue;
        final resolved = await catalog.resolve(preset);
        if (resolved == null || preset.revision >= resolved.catalog.revision) continue;
        // Trashed setups count too: restoring one must not bring back a value
        // outside a corrected range.
        final recordedValues = {
          for (final adjustment in component.adjustments)
            adjustment.id: [for (final recorded in await repository.recordedValues(adjustment.id)) recorded.value],
        };
        final migrated = migrateCatalogFixes(component, resolved, recordedValues);
        if (migrated != null) updates.add(migrated);
      }
      await repository.editComponents(updates);
    } catch (e, st) {
      debugPrint('Catalog migration failed: $e\n$st');
    }
  }
}
