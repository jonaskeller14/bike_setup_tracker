import '../models/component/component_catalog.dart';

/// Dart corrections a brand file's `changes:` names as `fix: { adjuster: <id>, step: <step id> }`,
/// for what a field fix cannot express: a condition on the rider's own value, a
/// partial edit of a text, a range chosen against the recorded values.
///
/// A step id is frozen once a released brand file names it. The step only
/// decides; the scope (`when:`, the adjuster) and the safety checks are the
/// framework's, see [CatalogStepFix].
const Map<String, CatalogMigrationStep> catalogMigrationSteps = {};
