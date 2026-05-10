import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? infoText;

  const SectionTitle({super.key, required this.title, this.infoText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }
}
