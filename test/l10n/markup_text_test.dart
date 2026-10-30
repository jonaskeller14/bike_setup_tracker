import 'package:bike_setup_tracker/l10n/markup_text.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('markupTextSpan', () {
    test('keeps plain text as a single span', () {
      final span = markupTextSpan('Plain text');

      expect(span.children, hasLength(1));
      expect((span.children!.single as TextSpan).text, 'Plain text');
      expect(span.toPlainText(), 'Plain text');
    });

    test('sets bold and italic words in place', () {
      final span = markupTextSpan('Add <b>bikes</b> and see <i>Bike Setup Tracker.</i>');
      final children = span.children!.cast<TextSpan>();

      expect(span.toPlainText(), 'Add bikes and see Bike Setup Tracker.');
      expect(children.map((s) => s.text), ['Add ', 'bikes', ' and see ', 'Bike Setup Tracker.']);
      expect(children[1].style?.fontWeight, FontWeight.bold);
      expect(children[3].style?.fontStyle, FontStyle.italic);
      expect(children[0].style, isNull);
    });

    test('handles a marker at the start and repeated markers', () {
      final span = markupTextSpan('<b>A</b> b <b>C</b>');

      expect(span.toPlainText(), 'A b C');
      expect(span.children, hasLength(3));
    });

    test('keeps line breaks', () {
      expect(markupTextSpan('One\nTwo <i>three</i>').toPlainText(), 'One\nTwo three');
    });
  });
}
