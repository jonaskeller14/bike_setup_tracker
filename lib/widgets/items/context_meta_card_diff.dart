import 'package:flutter/material.dart';

import '../../models/attachment.dart';
import '../../services/attachment_storage_service.dart';
import '../attachment_strip.dart';
import '../notes_text.dart';

class ContextMetaCardDiff extends StatelessWidget {
  final String? notesA;
  final Set<String> tagsA;
  final List<Attachment> attachmentsA;

  final String? notesB;
  final Set<String> tagsB;
  final List<Attachment> attachmentsB;

  const ContextMetaCardDiff({
    super.key,
    required this.notesA,
    required this.tagsA,
    required this.attachmentsA,
    required this.notesB,
    required this.tagsB,
    required this.attachmentsB,
  });

  @override
  Widget build(BuildContext context) {
    final hasNotesA = notesA?.trim().isNotEmpty ?? false;
    final hasNotesB = notesB?.trim().isNotEmpty ?? false;
    final notesDiffer = notesA != notesB;
    final hasNotes = hasNotesA || hasNotesB || notesDiffer;

    final hasTags = tagsA.isNotEmpty || tagsB.isNotEmpty;

    final hasAttachments = attachmentsA.isNotEmpty || attachmentsB.isNotEmpty;

    if (!hasNotes && !hasTags && !hasAttachments) return const SizedBox.shrink();

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasNotes)
            ListTile(
              leading: const Icon(Icons.notes),
              titleAlignment: ListTileTitleAlignment.titleHeight,
              title: _ComparisonRow(
                childA: hasNotesA
                    ? NotesText(notesA!, maxLines: 5)
                    : const Text('-'),
                childB: hasNotesB
                    ? NotesText(notesB!, maxLines: 5)
                    : const Text('-'),
              ),
              dense: true,
            ),
          if (hasTags)
            ListTile(
              leading: const Icon(Icons.tag),
              titleAlignment: ListTileTitleAlignment.titleHeight,
              title: _ComparisonRow(
                childA: Text(
                  tagsA.isEmpty ? '-' : (tagsA.toList()..sort()).join('\n'),
                ),
                childB: Text(
                  tagsB.isEmpty ? '-' : (tagsB.toList()..sort()).join('\n'),
                ),
              ),
              dense: true,
            ),
          if (hasAttachments)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: AttachmentStorageService().getAttachmentsPath(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return SizedBox(
                            height: 80,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _ComparisonRow(
                          childA: _AttachmentSide(
                            attachments: attachmentsA,
                            attachmentsDir: snapshot.data!,
                            heroTagPrefix: 'compare-attachments-a',
                            emptyColor: null,
                          ),
                          childB: _AttachmentSide(
                            attachments: attachmentsB,
                            attachmentsDir: snapshot.data!,
                            heroTagPrefix: 'compare-attachments-b',
                            emptyColor: null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final Widget childA;
  final Widget childB;

  const _ComparisonRow({required this.childA, required this.childB});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Expanded(child: childA),
        Expanded(child: childB),
      ],
    );
  }
}

class _AttachmentSide extends StatelessWidget {
  final List<Attachment> attachments;
  final String attachmentsDir;
  final String heroTagPrefix;
  final Color? emptyColor;

  const _AttachmentSide({
    required this.attachments,
    required this.attachmentsDir,
    required this.heroTagPrefix,
    required this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return SizedBox(
        height: 80,
        child: Align(
          alignment: Alignment.topLeft,
          child: Text('-', style: TextStyle(color: emptyColor)),
        ),
      );
    }
    return AttachmentStrip(
      attachments: attachments,
      attachmentsDir: attachmentsDir,
      heroTagPrefix: heroTagPrefix,
    );
  }
}
