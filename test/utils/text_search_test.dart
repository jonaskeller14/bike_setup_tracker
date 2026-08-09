import 'package:bike_setup_tracker/utils/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('text search', () {
    test('matches every query token regardless of order', () {
      final tokens = tokenizeSearchQuery('a b');

      expect(searchFieldsMatch(['b a'], tokens), isTrue);
      expect(searchFieldsMatch(['only a'], tokens), isFalse);
    });

    test('is case-insensitive and ignores repeated whitespace', () {
      final tokens = tokenizeSearchQuery('  FRONT   Fork ');

      expect(searchFieldsMatch(['Fork service', 'front suspension'], tokens), isTrue);
    });

    test('matches tokens across searchable fields', () {
      final tokens = tokenizeSearchQuery('Berlin downhill');

      expect(searchFieldsMatch(['Downhill setup', 'Berlin'], tokens), isTrue);
    });

    test('empty query matches all entries', () {
      expect(searchFieldsMatch(['Any setup'], tokenizeSearchQuery('  ')), isTrue);
    });
  });
}
