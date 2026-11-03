import 'package:bike_setup_tracker/utils/number_input_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

/// Types [edits] one after the other and returns the field text after each.
List<String> _type(TextInputFormatter formatter, List<String> edits) {
  var current = TextEditingValue.empty;
  return [
    for (final edit in edits) (current = formatter.formatEditUpdate(current, _value(edit))).text,
  ];
}

void main() {
  group('parseLocalizedDouble', () {
    test('accepts comma and dot as decimal separator', () {
      expect(parseLocalizedDouble('2,5'), 2.5);
      expect(parseLocalizedDouble('2.5'), 2.5);
    });

    test('rejects a number grouped with spaces instead of guessing', () {
      expect(parseLocalizedDouble('1 234,5'), isNull);
      expect(parseLocalizedDouble('1\u00A0234,5'), isNull);
      expect(parseLocalizedDouble('1\u202F234,5'), isNull);
    });

    test('accepts a separator at either end, as a half-typed value has', () {
      expect(parseLocalizedDouble('2,'), 2);
      expect(parseLocalizedDouble('2.'), 2);
      expect(parseLocalizedDouble(',5'), 0.5);
      expect(parseLocalizedDouble('.5'), 0.5);
    });

    test('keeps the sign', () {
      expect(parseLocalizedDouble('-0,3'), -0.3);
      expect(parseLocalizedDouble('-0.3'), -0.3);
      expect(parseLocalizedDouble('+1'), 1);
    });

    test('reads the minus variants of numeric keyboards', () {
      for (final minus in ['−', '–', '—']) {
        expect(parseLocalizedDouble('${minus}0,3'), -0.3);
      }
    });

    test('trims surrounding whitespace', () {
      expect(parseLocalizedDouble('  2,5 '), 2.5);
    });

    test('reads the scientific notation of a pre-filled double', () {
      expect(parseLocalizedDouble(1e-7.toString()), 1e-7);
      expect(parseLocalizedDouble(1e21.toString()), 1e21);
    });

    test('rejects more than one separator', () {
      for (final input in ['1,2,3', '1.2.3', '1,2.3', '1.234,5', '1,234.5', '1,,2', ',,']) {
        expect(parseLocalizedDouble(input), isNull, reason: input);
      }
    });

    test('rejects empty and whitespace-only input', () {
      expect(parseLocalizedDouble(''), isNull);
      expect(parseLocalizedDouble('   '), isNull);
    });

    test('rejects text that is no number', () {
      for (final input in [',', '.', '-', '-,', 'abc', '2,5 bar', '1 000']) {
        expect(parseLocalizedDouble(input), isNull, reason: input);
      }
    });
  });

  group('normalizeMinusSign', () {
    test('maps each variant to the ASCII hyphen-minus', () {
      expect(normalizeMinusSign('−1'), '-1');
      expect(normalizeMinusSign('–1'), '-1');
      expect(normalizeMinusSign('—1'), '-1');
    });

    test('leaves other text alone', () {
      expect(normalizeMinusSign('-1,5'), '-1,5');
    });
  });

  group('SignedDecimalInputFormatter', () {
    const formatter = SignedDecimalInputFormatter();

    test('lets a value with either separator be typed key by key', () {
      expect(_type(formatter, ['-', '-1', '-1,', '-1,5']), ['-', '-1', '-1,', '-1,5']);
      expect(_type(formatter, ['-', '-1', '-1.', '-1.5']), ['-', '-1', '-1.', '-1.5']);
      expect(_type(formatter, [',', ',5']), [',', ',5']);
    });

    test('rejects a second separator and keeps the text', () {
      expect(_type(formatter, ['1,5', '1,5,']), ['1,5', '1,5']);
      expect(_type(formatter, ['1,5', '1,5.']), ['1,5', '1,5']);
      expect(_type(formatter, ['1.5', '1.5,']), ['1.5', '1.5']);
    });

    test('rejects everything else', () {
      expect(_type(formatter, ['1', '1a']), ['1', '1']);
      expect(_type(formatter, ['1', '1-']), ['1', '1']);
      expect(_type(formatter, ['1', '1 ']), ['1', '1']);
    });

    test('rejects the grouping spaces of French and the Slavic languages', () {
      expect(_type(formatter, ['1', '1\u00A0']), ['1', '1']);
      expect(_type(formatter, ['1', '1\u202F']), ['1', '1']);
      expect(_type(formatter, ['1 234,5']), ['']);
    });

    test('normalizes minus variants', () {
      expect(_type(formatter, ['−0,5']), ['-0,5']);
      expect(_type(formatter, ['–0.5']), ['-0.5']);
      expect(_type(formatter, ['—1']), ['-1']);
    });

    test('keeps the cursor when normalizing', () {
      final result = formatter.formatEditUpdate(TextEditingValue.empty, _value('−1,5'));
      expect(result.selection, const TextSelection.collapsed(offset: 4));
    });
  });

  group('UnsignedDecimalInputFormatter', () {
    const formatter = UnsignedDecimalInputFormatter();

    test('lets a value with either separator be typed key by key', () {
      expect(_type(formatter, ['1', '12', '12,', '12,5']), ['1', '12', '12,', '12,5']);
      expect(_type(formatter, ['1', '12', '12.', '12.5']), ['1', '12', '12.', '12.5']);
    });

    test('rejects a sign', () {
      expect(_type(formatter, ['-']), ['']);
      expect(_type(formatter, ['1', '-1']), ['1', '1']);
    });

    test('rejects a second separator without emptying the field', () {
      expect(_type(formatter, ['1,5', '1,5,']), ['1,5', '1,5']);
      expect(_type(formatter, ['1.5', '1.5,']), ['1.5', '1.5']);
    });

    test('allows emptying the field', () {
      expect(_type(formatter, ['1', '']), ['1', '']);
    });
  });

  group('SignedIntegerInputFormatter', () {
    const formatter = SignedIntegerInputFormatter();

    test('lets a value be typed key by key', () {
      expect(_type(formatter, ['-', '-1', '-12']), ['-', '-1', '-12']);
    });

    test('rejects separators and keeps the text', () {
      expect(_type(formatter, ['-1', '-1,']), ['-1', '-1']);
      expect(_type(formatter, ['-1', '-1.']), ['-1', '-1']);
    });

    test('rejects a misplaced sign without emptying the field', () {
      expect(_type(formatter, ['12', '1-2']), ['12', '12']);
    });

    test('normalizes minus variants', () {
      expect(_type(formatter, ['−1']), ['-1']);
      expect(_type(formatter, ['–1']), ['-1']);
      expect(_type(formatter, ['—1']), ['-1']);
    });
  });
}
