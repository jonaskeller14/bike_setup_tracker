import 'package:bike_setup_tracker/models/rating/rating.dart';
import 'package:bike_setup_tracker/models/rating/rating_association.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RatingAssociation', () {
    test('fromJson() / toJson() round-trips every variant', () {
      const associations = <RatingAssociation>[
        GlobalRatingAssociation(),
        BikeRatingAssociation('b1'),
        PersonRatingAssociation('p1'),
        ComponentRatingAssociation('c1'),
        ComponentTypeRatingAssociation('ComponentType.fork'),
      ];
      for (final association in associations) {
        expect(RatingAssociation.fromJson(association.toJson()), association);
      }
    });

    test('fromFilter() falls back to global without a filter id', () {
      expect(RatingAssociation.fromFilter(FilterType.bike, null), const GlobalRatingAssociation());
      expect(RatingAssociation.fromFilter(FilterType.bike, 'b1'), const BikeRatingAssociation('b1'));
    });

    test('fromLegacyJson() reads the flat filter fields', () {
      expect(
        RatingAssociation.fromLegacyJson({'filter': 'p1', 'filterType': 'FilterType.person'}),
        const PersonRatingAssociation('p1'),
      );
      expect(RatingAssociation.fromLegacyJson({}), const GlobalRatingAssociation());
    });

    test('fromJson() throws for an unknown type', () {
      expect(() => RatingAssociation.fromJson({'type': 'setup', 'filter': 's1'}), throwsArgumentError);
    });
  });

  group('Rating association', () {
    final jsonVersion3 = {
      'version': 3,
      'id': 'rating1',
      'isDeleted': false,
      'lastModified': '2026-01-01T00:00:00Z',
      'name': 'Suspension feel',
      'filter': 'c1',
      'filterType': 'FilterType.component',
      'metrics': <dynamic>[],
    };

    test('Version 3: flat filter migrates to an association', () {
      final rating = Rating.fromJson(json: jsonVersion3);
      expect(rating.association, const ComponentRatingAssociation('c1'));
    });

    test('Version 4: fromJson() / toJson()', () {
      final ratingA = Rating.fromJson(json: jsonVersion3);
      final json = ratingA.toJson();
      expect(json['version'], 4);
      expect(json.containsKey('filterType'), false);
      final ratingB = Rating.fromJson(json: json);
      expect(ratingA == ratingB, true);
    });
  });
}
