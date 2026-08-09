import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

import '../utils/url.dart';

final RegExp _urlPattern = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
final RegExp _urlTrailingTrim = RegExp(r'[.,;:!?)\]}>]+$');

class NotesText extends StatelessWidget {
  final String notes;
  final double? fontSize;
  final Color? color;
  final int maxLines;

  const NotesText(
    this.notes, {
    super.key,
    this.fontSize,
    this.color,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.trim().isEmpty) return const SizedBox.shrink();

    final linkColor = Theme.of(context).colorScheme.primary;
    final toggleStyle = TextStyle(
      color: linkColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );

    return ReadMoreText(
      notes,
      trimMode: TrimMode.Line,
      trimLines: maxLines,
      trimCollapsedText: 'Show more',
      trimExpandedText: ' Show less',
      moreStyle: toggleStyle,
      lessStyle: toggleStyle,
      style: TextStyle(fontSize: fontSize, color: color),
      annotations: [
        Annotation(
          regExp: _urlPattern,
          // Shows a shortened label (e.g. "example.com/…") while the tap
          // target stays the full matched URL, stripped of any trailing
          // sentence punctuation the regex greedily swallowed.
          spanBuilder: ({required String text, TextStyle? textStyle}) {
            var url = text;
            var suffix = '';
            final trailingMatch = _urlTrailingTrim.firstMatch(text);
            if (trailingMatch != null && trailingMatch.start > 0) {
              url = text.substring(0, trailingMatch.start);
              suffix = text.substring(trailingMatch.start);
            }
            return TextSpan(children: [
              TextSpan(
                text: shortenUrlForDisplay(url),
                style: (textStyle ?? const TextStyle()).copyWith(
                  color: linkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: linkColor,
                  decorationThickness: 1.5,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => unawaited(launchAppUrl(context, url: url)),
              ),
              if (suffix.isNotEmpty) TextSpan(text: suffix, style: textStyle),
            ]);
          },
        ),
      ],
    );
  }
}
