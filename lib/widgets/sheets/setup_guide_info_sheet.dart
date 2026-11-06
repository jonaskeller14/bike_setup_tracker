import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
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

  static List<(GuideStatus, String)> _legend(AppLocalizations l10n) => [
    (const GuideStatus(GuideStatusKind.matches), l10n.guideLegendMatches),
    (const GuideStatus(GuideStatusKind.inRange), l10n.guideLegendInRange),
    (const GuideStatus(GuideStatusKind.off, text: "+6 psi"), l10n.guideLegendOff),
    (const GuideStatus(GuideStatusKind.notSet), l10n.guideLegendNotSet),
    (const GuideStatus(GuideStatusKind.unavailable), l10n.guideLegendUnavailable),
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
          SheetHeader(title: context.l10n.guideInfoTitle),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    context.l10n.guideInfoIntro,
                    style: muted,
                  ),
                  _heading(context, context.l10n.guideInfoHowHeading),
                  Text(
                    context.l10n.guideInfoHowSteps,
                    style: muted,
                  ),
                  Text(
                    context.l10n.guideInfoClicks,
                    style: muted,
                  ),
                  _heading(context, context.l10n.guideInfoStatusHeading),
                  for (final (status, meaning) in _legend(context.l10n))
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
                  _heading(context, guides.length == 1 ? context.l10n.guideInfoSource : context.l10n.guideInfoSources),
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
                            Text(context.l10n.guideInfoFor(components.join(', '))),
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
