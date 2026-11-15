import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/syncable.dart';
import 'package:bike_setup_tracker/services/sync/sync_codec.dart';
import 'package:bike_setup_tracker/services/sync/sync_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_fixture.dart';

List<Syncable> _recordsOf(SelectedData data) => [
      ...data.persons.values,
      ...data.bikes.values,
      ...data.components.values,
      ...data.setups.values,
      ...data.taskRules.values,
      ...data.taskEntries.values,
      ...data.feedbacks.values,
      ...data.testSessions.values,
    ];

Map<String, AdjustmentType> _typesOf(SelectedData data) =>
    adjustmentTypesOf(components: data.components.values, persons: data.persons.values);

/// What Firestore accepts as a field value: no directly nested arrays and only
/// its own scalar, map, list, timestamp and sentinel types.
void _expectStorable(Object? value, {bool inList = false}) {
  switch (value) {
    case null || bool() || num() || String() || Timestamp() || FieldValue():
      break;
    case List():
      expect(inList, isFalse, reason: 'Firestore rejects an array directly inside an array');
      for (final item in value) {
        _expectStorable(item, inList: true);
      }
    case Map():
      for (final item in value.values) {
        _expectStorable(item);
      }
    default:
      fail('Unsupported Firestore value ${value.runtimeType}: $value');
  }
}

/// A document as the pull reads it back: the server has set `serverUpdatedAt`.
Map<String, dynamic> _pulled(Syncable record) => {
      ...SyncCodec.encode(record),
      'serverUpdatedAt': Timestamp.fromDate(DateTime.utc(2026, 6, 1)),
    };

void main() {
  late SelectedData data;
  late Map<String, AdjustmentType> adjustmentTypes;

  setUp(() {
    data = SelectedData.fromJson(syncFixtureJson());
    adjustmentTypes = _typesOf(data);
  });

  group('SyncCollection', () {
    test('covers the 8 root tables with their table names', () {
      expect(
        SyncCollection.values.map((c) => c.collectionName),
        ['persons', 'bikes', 'components', 'setups', 'task_rules', 'task_entries', 'feedbacks', 'test_sessions'],
      );
    });

    test('has no Strava or child collection', () {
      for (final name in ['adjustments', 'installations', 'strava_activities', 'strava_gears']) {
        expect(SyncCollection.fromCollectionName(name), isNull);
      }
    });

    test('collections that need adjustment types come after persons and components', () {
      for (final collection in SyncCollection.values.where((c) => c.needsAdjustmentTypes)) {
        expect(collection.index, greaterThan(SyncCollection.components.index));
        expect(collection.index, greaterThan(SyncCollection.persons.index));
      }
    });
  });

  group('SyncCodec round trip', () {
    test('the fixture has one record per collection', () {
      expect(_recordsOf(data), hasLength(SyncCollection.values.length));
    });

    // Index i of the fixture list is SyncCollection.values[i].
    for (final collection in SyncCollection.values) {
      test('${collection.name}: decode(encode(x)) == x and the document is storable', () {
        final record = _recordsOf(data)[collection.index];

        final back = SyncCodec.decode(collection, _pulled(record), adjustmentTypes: adjustmentTypes);

        expect(back, record);
        _expectStorable(SyncCodec.encode(record));
      });
    }

    test('children travel embedded in their root', () {
      final component = SyncCodec.encode(data.components['c1']!);
      expect(component['installations'], hasLength(2));
      expect(component['adjustments'], hasLength(3));

      expect(SyncCodec.encode(data.persons['p1']!)['adjustments'], hasLength(1));

      final setup = SyncCodec.encode(data.setups['s1']!);
      expect(setup['bikeAdjustmentValues'], containsPair('num', 85.5));
      expect(setup['personAdjustmentValues'], containsPair('pnum', 75.0));

      final feedback = SyncCodec.encode(data.feedbacks['fb1']!);
      expect(feedback['observations'], hasLength(1));
      expect(feedback['comparisons'], hasLength(1));
    });

    test('setup set-now marks travel with the setup', () {
      final setup = data.setups['s1']!;
      expect(SyncCodec.encode(setup)['setNowAdjustmentIds'], ['num']);

      final back = SyncCodec.decode(SyncCollection.setups, _pulled(setup), adjustmentTypes: adjustmentTypes);

      expect((back! as Setup).setNowAdjustmentIds, {'num'});
    });

    test('a deleted record keeps its tombstone', () {
      final tombstone = data.bikes['b1']!.copyWith(isDeleted: true);

      final back = SyncCodec.decode(SyncCollection.bikes, _pulled(tombstone));

      expect(back, tombstone);
      expect(back!.isDeleted, isTrue);
    });
  });

  group('SyncCodec envelope', () {
    test('writes lastModified as a Timestamp and adds a server timestamp', () {
      final encoded = SyncCodec.encode(data.components['c1']!);

      expect(encoded['lastModified'], isA<Timestamp>());
      expect(encoded['serverUpdatedAt'], isA<FieldValue>());
      expect(encoded['id'], 'c1');
      expect(encoded['isDeleted'], false);
    });

    test('lastModified keeps microseconds through the Timestamp', () {
      final component = data.components['c1']!;
      expect(component.lastModified.microsecond, 456);

      final back = SyncCodec.decode(SyncCollection.components, _pulled(component));

      expect(back!.lastModified, component.lastModified);
      expect(back.lastModified.isUtc, isTrue);
    });

    test('reads lastModified written as an ISO string', () {
      final bike = data.bikes['b1']!;
      final document = {...SyncCodec.encode(bike), 'lastModified': bike.lastModified.toIso8601String()};

      expect(SyncCodec.decode(SyncCollection.bikes, document), bike);
    });
  });

  group('SyncCodec versions', () {
    test('writes the model version, which decides what a client can read', () {
      expect(SyncCodec.encode(data.bikes['b1']!)['version'], data.bikes['b1']!.toJson()['version']);
    });

    test('skips a document without lastModified instead of letting it win every merge', () {
      final document = {..._pulled(data.bikes['b1']!)}..remove('lastModified');

      expect(SyncCodec.decode(SyncCollection.bikes, document), isNull);
    });

    test('skips a document from a newer model version', () {
      final document = {..._pulled(data.bikes['b1']!), 'version': 999};

      expect(SyncCodec.decode(SyncCollection.bikes, document), isNull);
    });

    test('skips a malformed document', () {
      expect(SyncCodec.decode(SyncCollection.components, {'lastModified': '2026-01-01T00:00:00Z'}), isNull);
    });
  });

  group('SyncCodec adjustment types', () {
    test('types setup values with the adjustments of the pulled components', () {
      final back = SyncCodec.decode(SyncCollection.setups, _pulled(data.setups['s1']!), adjustmentTypes: adjustmentTypes);

      final setup = back! as Setup;
      expect(setup.bikeAdjustmentValues['num'], const NumericalValue(85.5));
      expect(setup.bikeAdjustmentValues['cat'], CategoricalValue(const ['Open', 'Firm']));
    });

    test('keeps the values of unknown adjustments, so a setup can be pulled before its component', () {
      final original = data.setups['s1']!;

      final setup = SyncCodec.decode(SyncCollection.setups, _pulled(original))! as Setup;

      expect(setup.bikeAdjustmentValues.values, everyElement(isA<UnresolvedValue>()));
      expect(SyncCodec.encode(setup)['bikeAdjustmentValues'], SyncCodec.encode(original)['bikeAdjustmentValues']);
      expect(Setup.resolveAdjustmentValues(setup.bikeAdjustmentValues, adjustmentTypes), original.bikeAdjustmentValues);
    });
  });
}
