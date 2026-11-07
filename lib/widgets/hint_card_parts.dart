import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme.dart';

/// Status, title and chevron: the header of a collapsible hint-styled card,
/// tappable as a whole.
class HintCardHeader extends StatelessWidget {
  final Widget status;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  const HintCardHeader({
    super.key,
    required this.status,
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
        child: Row(
          spacing: 6,
          children: [
            status,
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: hint.accent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: onToggle,
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              color: hint.accent,
              tooltip: expanded ? context.l10n.collapse : context.l10n.expand,
            ),
          ],
        ),
      ),
    );
  }
}

/// The status slot of [HintCardHeader] while its content is still loading.
class HintCardLoadingIndicator extends StatelessWidget {
  const HintCardLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: CircularProgressIndicator(strokeWidth: 2, color: HintColors.of(context).accent),
      ),
    );
  }
}

/// [text] followed by a "Learn more" link. The whole text is the tap target,
/// since the link alone is too small to hit reliably.
class HintLearnMoreText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback onLearnMore;

  const HintLearnMoreText({super.key, required this.text, required this.style, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onLearnMore,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text.rich(
          TextSpan(
            style: style,
            children: [
              TextSpan(text: "$text "),
              TextSpan(
                text: context.l10n.hintLearnMore,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
