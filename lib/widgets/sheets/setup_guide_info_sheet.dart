import 'package:flutter/material.dart';

import '../../models/component/setup_guide.dart';
import '../../utils/url.dart';
import '../setup_guide_card.dart';
import '../setup_guide_status.dart';
import 'sheet_header.dart';

/// How the setup guide card finds its values, what its status pills mean, and
/// the guide behind each component.
Future<void> showSetupGuideInfoSheet(BuildContext context, {required List<SetupGuideSection> sections}) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _SetupGuideInfoSheet(sections: sections),
  );
}

class _SetupGuideInfoSheet extends StatelessWidget {
  final List<SetupGuideSection> sections;

  const _SetupGuideInfoSheet({required this.sections});

  static const _legend = [
    (GuideStatus(GuideStatusKind.matches, "Matches"), "Your value is the recommended value."),
    (
      GuideStatus(GuideStatusKind.inRange, "In range"),
      "Close to the recommendation: inside the range the manual gives, or less than halfway to the next weight step.",
    ),
    (GuideStatus(GuideStatusKind.off, "+6 psi"), "Further off. Shows how far your value is from the recommendation."),
    (GuideStatus(GuideStatusKind.notSet, "Not set"), "No value entered yet. Tap the row to use the recommendation."),
    (
      GuideStatus(GuideStatusKind.unavailable, "Can't apply"),
      "The recommendation doesn't fit your adjuster, e.g. it is beyond its range. Edit the adjuster first.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    // Several components can share one guide; list each guide once.
    final guides = <String, (SetupGuide, List<String>)>{};
    for (final section in sections) {
      final guide = section.guided.guide;
      (guides[guide.id] ??= (guide, [])).$2.add(section.guided.component.name);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: "Recommended values"),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    "Each value comes from the manufacturer's setup guide for your exact model and riding weight. "
                    "It is a starting point, check your manual.",
                    style: muted,
                  ),
                  _heading(context, "How values are found"),
                  Text(
                    "Manuals list settings per weight step, for example 70–80 kg and 80–90 kg. If your weight "
                    "falls between two steps, the value is worked out in between. Outside the weights a manual "
                    "covers, there is no recommendation.",
                    style: muted,
                  ),
                  Text(
                    "Clicks are counted from the end the manual counts from. If your adjuster counts the other "
                    "way, the value is converted to your dial.",
                    style: muted,
                  ),
                  _heading(context, "Status"),
                  for (final (status, meaning) in _legend)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: 112,
                          child: Align(alignment: Alignment.centerLeft, child: GuideStatusPill(status)),
                        ),
                        Expanded(child: Text(meaning, style: muted)),
                      ],
                    ),
                  _heading(context, guides.length == 1 ? "Source" : "Sources"),
                  for (final (guide, components) in guides.values)
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(guide.label),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("For ${components.join(', ')}"),
                            Text(
                              shortenUrlForDisplay(guide.source),
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                        onTap: () => launchAppUrl(context, url: guide.source),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
  );
}
