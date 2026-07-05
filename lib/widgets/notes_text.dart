import 'dart:async';
import 'package:flutter/material.dart';
import 'package:see_more/see_more.dart';
import '../utils/url.dart';

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
    final linkColor = Theme.of(context).colorScheme.primary;
    final toggleStyle = TextStyle(
      color: linkColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
    return SeeMoreWidget(
      notes,
      trimMode: TrimMode.line,
      maxLines: maxLines,
      linkify: true,
      onLinkTap: (url) => unawaited(launchAppUrl(context, url: url)),
      textStyle: TextStyle(
        fontSize: fontSize,
        color: color,
      ),
      linkStyle: TextStyle(
        color: linkColor,
        fontSize: fontSize,
        decoration: TextDecoration.underline,
        decorationColor: linkColor,
        decorationThickness: 1.5,
      ),
      expandText: 'Show more',
      collapseText: 'Show less',
      expandTextStyle: toggleStyle,
      collapseTextStyle: toggleStyle,
    );
  }
}
