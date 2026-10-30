import 'package:flutter/painting.dart';

final RegExp _markup = RegExp(r'<(b|i)>(.*?)</\1>', dotAll: true);

/// Turns a translated message into a [TextSpan], with `<b>…</b>` set bold and
/// `<i>…</i>` set italic. Translators move the markers with the words they
/// emphasize, so the emphasis survives a different word order.
TextSpan markupTextSpan(String message) {
  final spans = <TextSpan>[];
  var cursor = 0;
  for (final match in _markup.allMatches(message)) {
    if (match.start > cursor) spans.add(TextSpan(text: message.substring(cursor, match.start)));
    spans.add(
      TextSpan(
        text: match.group(2),
        style: match.group(1) == 'b'
            ? const TextStyle(fontWeight: FontWeight.bold)
            : const TextStyle(fontStyle: FontStyle.italic),
      ),
    );
    cursor = match.end;
  }
  if (cursor < message.length) spans.add(TextSpan(text: message.substring(cursor)));
  return TextSpan(children: spans);
}
