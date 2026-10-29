import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_settings.dart';
import '../../../models/feedback/test_session.dart';
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
    final showTestSessions = context.select<AppSettings, bool>((s) => s.enableRating);
    // Test sessions filter like tags, so one hint covers both.
    final hasChips =
        showBookmark ||
        (showTags && appRepository.setupTags.isNotEmpty) ||
        (showTestSessions && appRepository.testSessionNames.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetSectionTitle(title: showBookmark || showTestSessions ? "Setups" : "Setup Tags"),
        if (hasChips)
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
              if (showTestSessions)
                ...appRepository.testSessionNames.map((name) {
                  void select(bool selected) => filters.setup = filters.setup.copyWith(
                    testSessionNames: toggled(filters.setup.testSessionNames, name, selected: selected),
                  );
                  return FilterChip(
                    avatar: const Icon(TestSession.iconData),
                    label: Text(name),
                    selected: filters.setup.testSessionNames.contains(name),
                    showCheckmark: false,
                    onSelected: select,
                    onDeleted: filters.setup.testSessionNames.contains(name) ? () => select(false) : null,
                  );
                }),
            ],
          ),
        if (!hasChips && showTags)
          SheetFilterEmptyHint(
            icon: Icons.tag,
            title: "No setup tags yet",
            hint: showTestSessions
                ? "Add/Edit a Setup to add tags, or start a test session to filter its runs."
                : "Add/Edit a Setup to add tags.",
          )
        else if (!hasChips && showTestSessions)
          const SheetFilterEmptyHint(
            icon: TestSession.iconData,
            title: "No test sessions yet",
            hint: "Start a test session to filter its runs.",
          ),
      ],
    );
  }
}
