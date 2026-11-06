import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/l10n/list_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  group('joinItems', () {
    test('joins in English with an Oxford comma', () {
      expect(joinItems(en, []), '');
      expect(joinItems(en, ['a']), 'a');
      expect(joinItems(en, ['a', 'b']), 'a and b');
      expect(joinItems(en, ['a', 'b', 'c']), 'a, b, and c');
      expect(joinItems(en, ['a', 'b', 'c', 'd']), 'a, b, c, and d');
    });

    test('joins in German without a comma before und', () {
      expect(joinItems(de, ['a', 'b']), 'a und b');
      expect(joinItems(de, ['a', 'b', 'c']), 'a, b und c');
    });
  });

  group('plural messages', () {
    test('bike trash summary follows the language', () {
      expect(en.bikeTrashedTasks(1), '1 task and its entries');
      expect(en.bikeTrashedTasks(3), '3 tasks and their entries');
      expect(de.bikeTrashedTasks(1), '1 Aufgabe mit ihren Einträgen');
      expect(de.bikeTrashedTasks(3), '3 Aufgaben mit ihren Einträgen');
    });

    test('quotes around names are kept', () {
      expect(en.bikeMovedToTrash(1, 'Trail'), "Bike 'Trail' moved to trash.");
      expect(en.bikeMovedToTrash(2, 'Trail'), '2 bikes moved to trash.');
      expect(de.bikeMovedToTrash(1, 'Trail'), 'Bike „Trail“ in den Papierkorb verschoben.');
    });

    test('the zero case of the preset snackbar is kept', () {
      expect(en.componentFormPresetLinked('Fox 38', 0), 'Linked to Fox 38 · no adjustments added');
      expect(en.componentFormPresetLinked('Fox 38', 1), 'Linked to Fox 38 · 1 adjustment added');
      expect(de.componentFormPresetLinked('Fox 38', 2), 'Mit Fox 38 verknüpft · 2 Einstellungen hinzugefügt');
    });
  });
}
