import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_athlete.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mappers Test', () {
    test('Bike Mapping', () {
      final bike = Bike(
        id: 'bike1',
        name: 'Road Bike',
        person: 'person1',
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );

      // Model -> Companion
      final companion = bike.toCompanion();
      expect(companion.id.value, 'bike1');
      expect(companion.name.value, 'Road Bike');
      expect(companion.person.value, 'person1');
      expect(companion.isDeleted.value, false);

      // DB Row -> Model
      final data = BikeDb(
        id: 'bike1',
        name: 'Road Bike',
        person: 'person1',
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );
      final model = data.toModel();
      expect(model.id, 'bike1');
      expect(model.name, 'Road Bike');
      expect(model.person, 'person1');
      expect(model.isDeleted, false);
    });

    test('Person Mapping', () {
      final person = Person(
        id: 'person1',
        name: 'Jonas',
        adjustments: [
          NumericalAdjustment(id: 'adj1', name: 'Weight', notes: '', unit: 'kg', category: AdjustmentCategory.body),
        ],
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );

      // Model -> Companion
      final companion = person.toCompanion();
      expect(companion.id.value, 'person1');
      expect(companion.name.value, 'Jonas');

      // DB Row -> Model
      final data = PersonDb(
        id: 'person1',
        name: 'Jonas',
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );
      final model = data.toModel(adjustments: [
        NumericalAdjustment(id: 'adj1', name: 'Weight', notes: '', unit: 'kg', category: AdjustmentCategory.body),
      ]);
      expect(model.id, 'person1');
      expect(model.name, 'Jonas');
      expect(model.adjustments.first.name, 'Weight');
    });

    test('Component Mapping', () {
      final component = Component(
        id: 'comp1',
        name: 'Fork',
        componentType: ComponentType.fork,
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        adjustments: [
          StepAdjustment(id: 'adj2', name: 'Rebound', notes: '', unit: 'clicks', category: AdjustmentCategory.component, min: 0, max: 20, step: 1, visualization: StepAdjustmentVisualization.slider),
        ],
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );

      // Model -> Companion
      final companion = component.toCompanion();
      expect(companion.id.value, 'comp1');
      expect(companion.name.value, 'Fork');
      expect(companion.componentType.value, ComponentType.fork);

      // DB Row -> Model
      final data = ComponentDb(
        id: 'comp1',
        name: 'Fork',
        componentType: ComponentType.fork,
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );
      final model = data.toModel(
        adjustments: [
          StepAdjustment(id: 'adj2', name: 'Rebound', notes: '', unit: 'clicks', category: AdjustmentCategory.component, min: 0, max: 20, step: 1, visualization: StepAdjustmentVisualization.slider),
        ],
        installations: [Installation.sinceBeginning(parent: 'bike1')],
      );
      expect(model.id, 'comp1');
      expect(model.componentType, ComponentType.fork);
      expect(model.installations.first.parent, 'bike1');
    });

    test('Setup Mapping', () {
      final setup = Setup(
        id: 'setup1',
        name: 'Race Setup',
        datetime: DateTime(2023, 1, 1).toUtc(),
        datetimeLocal: DateTime(2023, 1, 1),
        tags: {'race'},
        bike: 'bike1',
        person: 'person1',
        isCurrent: true,
        bikeAdjustmentValues: {'adj1': 10},
        personAdjustmentValues: {'adj2': 5},
        ratingAdjustmentValues: {'adj3': 3},
      );

      // Model -> Companion
      final companion = setup.toCompanion();
      expect(companion.id.value, 'setup1');
      expect(companion.name.value, 'Race Setup');
      expect(companion.tags.value, {'race'});
      expect(companion.bikeId.value, 'bike1');

      // DB Row -> Model
      final data = SetupDb(
        id: 'setup1',
        name: 'Race Setup',
        datetime: DateTime(2023, 1, 1).toUtc(),
        datetimeLocal: DateTime(2023, 1, 1),
        tags: {'race'},
        bikeId: 'bike1',
        personId: 'person1',
        isDeleted: false,
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );
      
      final model = data.toModel(isCurrent: true);

      expect(model.id, 'setup1');
      expect(model.isCurrent, true);
      expect(model.tags, contains('race'));
      expect(model.bike, 'bike1');
    });

    group('Detailed Adjustment Mapping', () {
      test('Adjustment Table -> Model', () {
        final data = AdjustmentDb(
          id: 'adj1',
          name: 'Pressure',
          category: AdjustmentCategory.component,
          type: AdjustmentType.numerical,
          unit: 'psi',
          orderIndex: 0,
          jsonPayload: '{"version":1,"type":"numerical","min":0.0,"max":300.0}',
        );
        
        final model = data.toModel();
        expect(model, isA<NumericalAdjustment>());
        expect(model.name, 'Pressure');
        expect(model.unit, 'psi');
        expect((model as NumericalAdjustment).min, 0.0);
      });
    });

    test('StravaAthlete Mapping', () {
      final athlete = StravaAthlete(
        id: 123,
        firstname: 'Jonas',
        lastname: 'Keller',
        profile: 'https://example.com/profile.jpg',
        gears: {'gear1', 'gear2'},
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );

      // Model -> Companion
      final companion = athlete.toCompanion();
      expect(companion.id.value, 123);
      expect(companion.firstname.value, 'Jonas');
      expect(companion.gears.value, {'gear1', 'gear2'});

      // DB Row -> Model
      final data = StravaAthleteDb(
        id: 123,
        firstname: 'Jonas',
        lastname: 'Keller',
        profile: 'https://example.com/profile.jpg',
        gears: {'gear1', 'gear2'},
        lastModified: DateTime(2023, 1, 1).toUtc(),
      );
      final model = data.toModel();
      expect(model.id, 123);
      expect(model.firstname, 'Jonas');
      expect(model.gears, {'gear1', 'gear2'});
    });
  });
}
