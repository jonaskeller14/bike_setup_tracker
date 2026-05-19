import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? infoText;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.infoText, this.trailing});

  @override
  Widget build(BuildContext context) {
    // Stack instead of a plain Row: placing [trailing] directly in the Row would
    // increase the Row's height whenever the trailing widget is taller than the
    // title text (e.g. an IconButton with its touch target), causing unequal
    // vertical gaps around the dividers that precede each section. By using a
    // Stack, the height is determined solely by the Padding+Row (text only).
    // The trailing is Positioned so it doesn't affect layout height but remains
    // fully tappable. A SizedBox(width: 20) in the Row reserves the horizontal
    // space so the title text never overlaps the trailing widget.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.primary
                )),
              ),
              if (infoText != null)
                Tooltip(
                  message: infoText,
                  triggerMode: TooltipTriggerMode.tap,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  showDuration: const Duration(seconds: 5),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                  ),
                ),
              if (trailing != null) const SizedBox(width: 20),
            ],
          ),
        ),
        if (trailing case final t?)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(child: t),
          ),
      ],
    );
  }
}
