import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/image_storage_service.dart';
import '../../theme.dart';
import '../image_strip.dart';
import '../notes_text.dart';

class ContextMetaCardDiff extends StatelessWidget {
  final String? notesA;
  final Set<String> tagsA;
  final List<String> imagesA;

  final String? notesB;
  final Set<String> tagsB;
  final List<String> imagesB;

  const ContextMetaCardDiff({
    super.key,
    required this.notesA,
    required this.tagsA,
    required this.imagesA,
    required this.notesB,
    required this.tagsB,
    required this.imagesB,
  });

  @override
  Widget build(BuildContext context) {
    final hasNotesA = notesA?.trim().isNotEmpty ?? false;
    final hasNotesB = notesB?.trim().isNotEmpty ?? false;
    final notesDiffer = notesA != notesB;
    final hasNotes = hasNotesA || hasNotesB || notesDiffer;

    final hasTags = tagsA.isNotEmpty || tagsB.isNotEmpty;

    final hasImages = imagesA.isNotEmpty || imagesB.isNotEmpty;

    if (!hasNotes && !hasTags && !hasImages) return const SizedBox.shrink();

    final changedColor = Theme.of(context).extension<ValueHighlightColors>()!.changed;
    final tagsDiffer = !tagsA.containsAll(tagsB) || !tagsB.containsAll(tagsA);
    final imagesDiffer = !listEquals(imagesA, imagesB);

    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasNotes)
            ListTile(
              leading: Icon(Icons.notes, color: notesDiffer ? changedColor : null),
              titleAlignment: ListTileTitleAlignment.titleHeight,
              title: _ComparisonRow(
                childA: hasNotesA
                    ? NotesText(notesA!, maxLines: 10, color: notesDiffer ? changedColor : null)
                    : Text('-', style: TextStyle(color: notesDiffer ? changedColor : null)),
                childB: hasNotesB
                    ? NotesText(notesB!, maxLines: 10, color: notesDiffer ? changedColor : null)
                    : Text('-', style: TextStyle(color: notesDiffer ? changedColor : null)),
              ),
              dense: true,
            ),
          if (hasTags)
            ListTile(
              leading: Icon(Icons.tag, color: tagsDiffer ? changedColor : null),
              titleAlignment: ListTileTitleAlignment.titleHeight,
              title: _ComparisonRow(
                childA: Text(
                  tagsA.isEmpty ? '-' : (tagsA.toList()..sort()).join('\n'),
                  style: TextStyle(color: tagsDiffer ? changedColor : null),
                ),
                childB: Text(
                  tagsB.isEmpty ? '-' : (tagsB.toList()..sort()).join('\n'),
                  style: TextStyle(color: tagsDiffer ? changedColor : null),
                ),
              ),
              dense: true,
            ),
          if (hasImages)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: imagesDiffer ? changedColor : null,
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: ImageStorageService().getImagesPath(),
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
                          childA: _ImageSide(
                            images: imagesA,
                            imagesDir: snapshot.data!,
                            heroTagPrefix: 'compare-images-a',
                            emptyColor: imagesDiffer ? changedColor : null,
                          ),
                          childB: _ImageSide(
                            images: imagesB,
                            imagesDir: snapshot.data!,
                            heroTagPrefix: 'compare-images-b',
                            emptyColor: imagesDiffer ? changedColor : null,
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

class _ImageSide extends StatelessWidget {
  final List<String> images;
  final String imagesDir;
  final String heroTagPrefix;
  final Color? emptyColor;

  const _ImageSide({
    required this.images,
    required this.imagesDir,
    required this.heroTagPrefix,
    required this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return SizedBox(
        height: 80,
        child: Align(
          alignment: Alignment.topLeft,
          child: Text('-', style: TextStyle(color: emptyColor)),
        ),
      );
    }
    return ImageStrip(
      images: images,
      imagesDir: imagesDir,
      heroTagPrefix: heroTagPrefix,
    );
  }
}
