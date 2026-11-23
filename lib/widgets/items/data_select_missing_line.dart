import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/data_selection_dependencies.dart';
import 'tile_meta_row.dart';

/// A line on a data select row naming one referenced item that isn't
/// selected, e.g. "Component 'Fork' not selected", in the error colour.
class DataSelectMissingLine extends StatelessWidget {
  final DataKind kind;
  final String name;

  const DataSelectMissingLine({super.key, required this.kind, required this.name});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TileMetaRow(
      icon: Icons.warning_amber_rounded,
      text: switch (kind) {
        DataKind.person => l10n.dataSelectMissingPerson(name),
        DataKind.bike => l10n.dataSelectMissingBike(name),
        DataKind.component => l10n.dataSelectMissingComponent(name),
        DataKind.setup => l10n.dataSelectMissingSetup(name),
        DataKind.taskRule => l10n.dataSelectMissingTaskRule(name),
        DataKind.taskEntry => l10n.dataSelectMissingTaskEntry(name),
        DataKind.feedback => l10n.dataSelectMissingFeedback(name),
        DataKind.testSession => l10n.dataSelectMissingTestSession(name),
      },
      isError: true,
    );
  }
}
