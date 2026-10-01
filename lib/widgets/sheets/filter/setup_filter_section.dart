import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_settings.dart';
import '../../../repositories/app_repository.dart';
import '../../text/sheet_section_title.dart';
import '../sheet.dart';
import 'isolatable_chips.dart';

class SetupFilterSection extends StatelessWidget {
  const SetupFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final filters = appRepository.filters;
    final showBookmark = context.select<AppSettings, bool>((s) => s.enableSetupBookmark);
    final showTags = context.select<AppSettings, bool>((s) => s.enableSetupTags);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetSectionTitle(title: showBookmark ? "Setups" : "Setup Tags"),
        if (showBookmark || appRepository.setupTags.isNotEmpty)
          Wrap(
            spacing: 6,
            children: [
              if (showBookmark)
                FilterChip(
                  avatar: Icon(filters.setup.bookmarkedOnly ? Icons.bookmark : Icons.bookmark_border),
                  label: const Text("Bookmarked"),
                  selected: filters.setup.bookmarkedOnly,
                  showCheckmark: false,
                  onSelected: (bool newValue) => filters.setup = filters.setup.copyWith(bookmarkedOnly: newValue),
                  onDeleted: filters.setup.bookmarkedOnly
                      ? () => filters.setup = filters.setup.copyWith(bookmarkedOnly: false)
                      : null,
                ),
              if (showTags)
                ...appRepository.setupTags.map((tag) {
                  void select(bool selected) => filters.setup = filters.setup.copyWith(
                    tags: toggled(filters.setup.tags, tag, selected: selected),
                  );
                  return FilterChip(
                    avatar: const Icon(Icons.tag),
                    label: Text(tag),
                    selected: filters.setup.tags.contains(tag),
                    showCheckmark: false,
                    onSelected: select,
                    onDeleted: filters.setup.tags.contains(tag) ? () => select(false) : null,
                  );
                }),
            ],
          ),
        if (showTags && appRepository.setupTags.isEmpty)
          const SheetFilterEmptyHint(
            icon: Icons.tag,
            title: "No setup tags yet",
            hint: "Add/Edit a Setup to add tags.",
          ),
      ],
    );
  }
}
