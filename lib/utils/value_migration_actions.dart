import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../repositories/app_repository.dart';
import '../widgets/sheets/value_migration_sheet.dart';
import 'value_migration_proposal.dart';

/// What an adjustment or metric edit page needs to check recorded values: the
/// [saved] definition, and the proposal [pending] from an earlier edit of it in
/// the same parent form.
@immutable
class ValueMigrationContext {
  final Adjustment saved;
  final MigrationProposal? pending;

  const ValueMigrationContext(this.saved, {this.pending});

  /// The context for [id], or `null` when it was never saved and so has no
  /// recorded values.
  static ValueMigrationContext? of(String id, Map<String, Adjustment> saved, Map<String, MigrationProposal> pending) =>
      switch (saved[id]) {
        final adjustment? => ValueMigrationContext(adjustment, pending: pending[id]),
        null => null,
      };
}

/// What an edit page in edit mode hands back to its parent form: the edited
/// [value] and the proposal to keep [pending] until the parent form is saved,
/// replacing any earlier one; `null` when the edit leaves recorded values alone.
class AdjustmentEditResult<T> {
  final T value;
  final MigrationProposal? pending;

  const AdjustmentEditResult(this.value, {this.pending});
}

/// The save step of an adjustment or metric edit page: when turning the saved
/// definition into [after] affects recorded values, asks the rider what to do
/// with them. [before] is the definition the page opened with, and
/// [optionOrigins] maps each new categorical option to the text its row had
/// there.
///
/// The proposal always covers the net change from the saved definition, so an
/// earlier pending proposal is rebuilt, not added to. Returns the proposal to
/// keep pending (`null` inside the record when there is none), or `null` when
/// the rider cancelled, and the page then stays open.
Future<({MigrationProposal? pending})?> confirmValueMigrations(
  BuildContext context, {
  required ValueMigrationContext? migrationContext,
  required Adjustment before,
  required Adjustment after,
  Map<String, String?> optionOrigins = const {},
}) async {
  if (migrationContext == null) return (pending: null);
  final ValueMigrationContext(:saved, :pending) = migrationContext;
  final base = pending ?? MigrationProposal.build(before: saved, after: before, recorded: const []);
  final savedOrigins = base.savedOriginsFor(after, optionOrigins);
  if (!MigrationProposal.mayAffectValues(before: saved, after: after, optionOrigins: savedOrigins)) {
    return (pending: null);
  }

  final recorded = await context.read<AppRepository>().recordedValues(saved.id);
  if (!context.mounted) return null;
  final proposal = base.rebuild(after: after, pageOrigins: optionOrigins, recorded: recorded);
  // An empty proposal is still kept: it traces the options back to the saved ones.
  if (proposal.isEmpty) return (pending: proposal);

  final confirmed = await showValueMigrationSheet(
    context,
    adjustmentName: after.name,
    proposal: proposal,
    replacesEarlier: pending != null && !pending.isEmpty,
  );
  if (confirmed == null) return null;
  return (pending: confirmed);
}

/// The migrations to write when the parent form is saved. An empty proposal
/// only traces the options back to the saved ones and writes nothing.
List<ValueMigration> pendingValueMigrations(Map<String, MigrationProposal> pending) => [
  for (final proposal in pending.values)
    if (!proposal.isEmpty)
      if (proposal.toMigration() case final migration when !migration.isNoOp) migration,
];
