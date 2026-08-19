import 'package:flutter/material.dart';

import '../../services/image_storage_service.dart';
import '../image_strip.dart';
import '../notes_text.dart';

class ContextMetaCard extends StatelessWidget {
  final String? notes;
  final Set<String> tags;
  final List<String> images;

  const ContextMetaCard({
    super.key,
    required this.notes,
    required this.tags,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes?.trim().isNotEmpty ?? false;
    if (!hasNotes && tags.isEmpty && images.isEmpty) return const SizedBox.shrink();

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
              title: NotesText(notes!, maxLines: 10),
              dense: true,
            ),
          if (tags.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.tag),
              titleAlignment: ListTileTitleAlignment.titleHeight,
              title: Text(tags.join("\n")),
              dense: true,
            ),
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.photo_library_outlined),
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
                        return ImageStrip(
                          images: images,
                          imagesDir: snapshot.data!,
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
