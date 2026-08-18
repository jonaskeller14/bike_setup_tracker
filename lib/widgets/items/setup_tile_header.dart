import 'package:flutter/material.dart';

import '../../models/setup.dart';
import '../notes_text.dart';

class SetupTileHeader extends StatelessWidget {
  final Setup setup;
  final String dateTimeText;
  final List<Widget> metadata;
  final Widget? badge;
  final Widget? secondaryMetadata;
  final bool showSetupIcon;

  const SetupTileHeader({
    super.key,
    required this.setup,
    required this.dateTimeText,
    required this.metadata,
    required this.showSetupIcon,
    this.badge,
    this.secondaryMetadata,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final notesColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    final hasNotes = setup.notes?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSetupIcon) ...[
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Setup.iconData),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          setup.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                      ?badge,
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        dateTimeText,
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                      ?secondaryMetadata,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (metadata.isNotEmpty || hasNotes)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metadata.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: metadata,
                  ),
                if (hasNotes)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(Icons.notes, size: 12, color: notesColor),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: NotesText(
                          setup.notes!,
                          fontSize: 12,
                          color: notesColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
