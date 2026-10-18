import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../repositories/app_repository.dart';
import '../widgets/sheets/value_migration_sheet.dart';
import 'value_migration_proposal.dart';

/// The save step of an adjustment or metric edit page: when changing [before]
/// into [after] affects recorded values, asks the rider what to do with them.
///
/// Returns the migrations to hand back in the page's `EditResult`: none when no
/// recorded value is affected, otherwise the confirmed one. Returns `null` when
/// the rider cancelled, and the page then stays open. [staged] is the migration
/// the parent form still has pending for this adjustment; [optionOrigins] maps
/// each new categorical option to the text its row started with.
Future<List<ValueMigration>?> confirmValueMigrations(
  BuildContext context, {
  required Adjustment before,
  required Adjustment after,
  Map<String, String?> optionOrigins = const {},
  ValueMigration? staged,
}) async {
  if (!MigrationProposal.mayAffectValues(before: before, after: after, optionOrigins: optionOrigins)) {
    return const [];
  }

  final recorded = await context.read<AppRepository>().recordedValues(before.id);
  if (!context.mounted) return null;
  final proposal = MigrationProposal.build(
    before: before,
    after: after,
    optionOrigins: optionOrigins,
    recorded: recorded,
    staged: staged,
  );
  if (proposal.isEmpty) return const [];

  final migration = await showValueMigrationSheet(context, adjustmentName: after.name, proposal: proposal);
  if (migration == null) return null;
  return migration.isNoOp ? const [] : [migration];
}
