import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/pressure_drift_service.dart';
import 'package:bike_setup_tracker/services/setup_resolution_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Conditions the pressures were set in: a mild spring day at low elevation.
const double _referenceTemperatureC = 20;
const double _referenceAltitudeM = 500;

/// Conditions now: colder and much higher up.
const double _currentTemperatureC = 5;
const double _currentAltitudeM = 1800;

Setup _setup({
  required String id,
  required DateTime datetime,
  required Map<String, dynamic> bikeAdjustmentValues,
  double? temperatureC = _referenceTemperatureC,
  double? altitudeM = _referenceAltitudeM,
}) {
  return Setup(
    id: id,
    datetime: datetime,
    datetimeLocal: datetime.toLocal(),
    bike: 'bike_1',
    person: null,
    tags: {},
    bikeAdjustmentValues: bikeAdjustmentValues,
    personAdjustmentValues: {},
    position: altitudeM == null ? null : ContextPosition(latitude: 47, longitude: 11, altitude: altitudeM),
    weather: temperatureC == null
        ? null
        : ContextWeather(currentDateTime: datetime, currentTemperature: temperatureC),
  );
}

Component _component({required String name, required List<Adjustment> adjustments}) {
  return Component(
    name: name,
    componentType: ComponentType.fork,
    adjustments: adjustments,
    installations: [Installation.sinceBeginning(parent: 'bike_1')],
  );
}

NumericalAdjustment _pressureAdjustment({required String id, required String name, String unit = 'psi'}) {
  return NumericalAdjustment(
    id: id,
    name: name,
    notes: null,
    unit: AdjustmentUnit.fromLegacy(unit),
  );
}

ContextWeather _currentWeather({double? temperatureC = _currentTemperatureC}) =>
    ContextWeather(currentDateTime: DateTime(2025, 4, 20), currentTemperature: temperatureC);

ContextPosition _currentPosition({double? altitudeM = _currentAltitudeM}) =>
    ContextPosition(latitude: 47, longitude: 11, altitude: altitudeM);

List<PressureDriftEntry> _compute({
  required List<Component> components,
  required Iterable<Setup> setups,
  ContextWeather? weather,
  ContextPosition? position,
}) {
  return PressureDriftService.compute(
    components: components,
    provenance: SetupResolutionService.resolveHistoricalProvenanceAt(
      datetime: DateTime(2025, 4, 20).toUtc(),
      setups: setups,
    ),
    currentWeather: weather ?? _currentWeather(),
    currentPosition: position ?? _currentPosition(),
  );
}

void main() {
  group('PressureDriftService atmosphere model', () {
    test('atmospheric pressure follows the ISA barometric formula', () {
      // Intention: Verify the ambient pressure the whole calculation rests on.
      // Desired outcome: Sea level is 1013.25 hPa and known elevations match ISA tables.
      // Not desired outcome: A linear approximation, or an altitude sign error.
      expect(PressureDriftService.atmosphericPressurePa(0), closeTo(101325, 1));
      expect(PressureDriftService.atmosphericPressurePa(500), closeTo(95461, 50));
      expect(PressureDriftService.atmosphericPressurePa(1800), closeTo(81491, 50));
      expect(PressureDriftService.atmosphericPressurePa(2500), closeTo(74692, 50));
    });

    test('absurd altitudes are clamped instead of producing NaN', () {
      // Intention: A broken GPS altitude must not poison the calculation.
      // Desired outcome: Finite pressures outside the troposphere.
      // Not desired outcome: NaN from a negative base raised to a fractional power.
      expect(PressureDriftService.atmosphericPressurePa(-100000).isFinite, isTrue);
      expect(PressureDriftService.atmosphericPressurePa(100000).isFinite, isTrue);
    });

    test('a reading converted to other conditions and back is unchanged', () {
      // Intention: The model must be reversible, since the same solver will later
      // be used to pre-compensate a pressure for conditions ahead.
      // Desired outcome: Round-tripping returns the original gauge pressure.
      // Not desired outcome: Drift accumulating through the temperature ratio.
      const gaugePa = 551581.0; // 80 psi
      final atDestination = PressureDriftService.readingAtPa(
        gaugePa: gaugePa,
        fromTemperatureC: _referenceTemperatureC,
        fromAltitudeM: _referenceAltitudeM,
        toTemperatureC: _currentTemperatureC,
        toAltitudeM: _currentAltitudeM,
      );
      final backHome = PressureDriftService.readingAtPa(
        gaugePa: atDestination,
        fromTemperatureC: _currentTemperatureC,
        fromAltitudeM: _currentAltitudeM,
        toTemperatureC: _referenceTemperatureC,
        toAltitudeM: _referenceAltitudeM,
      );
      expect(backHome, closeTo(gaugePa, 0.001));
    });
  });

  group('PressureDriftService drift entries', () {
    late NumericalAdjustment forkPressure;
    late Component fork;
    late DateTime referenceDateTime;

    setUp(() {
      forkPressure = _pressureAdjustment(id: 'adj_fork_pressure', name: 'Air Pressure');
      fork = _component(name: 'Fork', adjustments: [forkPressure]);
      referenceDateTime = DateTime(2025, 4, 2).toUtc();
    });

    test('a colder, higher day lowers what the pump reads', () {
      // Intention: Verify the headline number against a hand-calculated case
      // (80 psi set at 20 °C / 500 m, checked at 5 °C / 1800 m).
      // Desired outcome: ~77.2 psi, i.e. the fork has gone soft by ~2.8 psi.
      // Not desired outcome: A rise (altitude applied with the wrong sign) or a
      // temperature ratio taken in Celsius.
      final entries = _compute(
        components: [fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {forkPressure.id: 80.0},
          ),
        ],
      );

      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.predictedReading, closeTo(77.22, 0.05));
      expect(entry.delta, closeTo(-2.78, 0.05));
      expect(entry.relativeDelta, closeTo(-0.0347, 0.001));
      expect(entry.isSignificant, isTrue);
      expect(entry.referenceSetup.id, 's1');
      expect(entry.componentName, 'Fork');
      expect(entry.adjustmentName, 'Air Pressure');
    });

    test('the two causes are reported separately and add up to the total', () {
      // Intention: The split is the point of the card — cold and altitude pull in
      // opposite directions, so a big temperature swing can still be harmless.
      // Desired outcome: Temperature loses ~4.8 psi, altitude gains ~2.0 psi.
      // Not desired outcome: Shares that don't reconstruct the total drift.
      final entry = _compute(
        components: [fork],
        setups: [
          _setup(id: 's1', datetime: referenceDateTime, bikeAdjustmentValues: {forkPressure.id: 80.0}),
        ],
      ).single;

      expect(entry.temperatureShare, closeTo(-4.80, 0.05));
      expect(entry.altitudeShare, closeTo(2.03, 0.05));
      expect(entry.temperatureShare + entry.altitudeShare, closeTo(entry.delta, 0.0001));
      expect(entry.temperatureDeltaC, -15);
      expect(entry.altitudeDeltaM, 1300);
    });

    test('a low tire pressure stays below the significance threshold', () {
      // Intention: The same conditions barely move a tire, because its absolute
      // pressure is low enough for the altitude gain to offset the cooling.
      // Desired outcome: A tiny drift that is not worth unpacking the pump for.
      // Not desired outcome: Flagging every pressure whenever the weather moves.
      final tirePressure = _pressureAdjustment(id: 'adj_tire_pressure', name: 'Tire Pressure');
      final wheel = _component(name: 'Front Wheel', adjustments: [tirePressure]);

      final entry = _compute(
        components: [wheel],
        setups: [
          _setup(id: 's1', datetime: referenceDateTime, bikeAdjustmentValues: {tirePressure.id: 25.0}),
        ],
      ).single;

      expect(entry.predictedReading, closeTo(25.04, 0.05));
      expect(entry.isSignificant, isFalse);
    });

    test('unchanged conditions produce no drift', () {
      // Intention: The common case of logging a second setup on the same ride.
      // Desired outcome: The pump reads exactly what it read before.
      // Not desired outcome: Rounding noise presented as a drift.
      final entry = _compute(
        components: [fork],
        setups: [
          _setup(id: 's1', datetime: referenceDateTime, bikeAdjustmentValues: {forkPressure.id: 80.0}),
        ],
        weather: _currentWeather(temperatureC: _referenceTemperatureC),
        position: _currentPosition(altitudeM: _referenceAltitudeM),
      ).single;

      expect(entry.delta, closeTo(0, 0.0001));
      expect(entry.isSignificant, isFalse);
    });

    test('the same case in bar drifts by the same fraction', () {
      // Intention: Results must not depend on the unit the adjustment stores.
      // Desired outcome: 5.52 bar behaves exactly like 80 psi.
      // Not desired outcome: A conversion applied to the gauge value but not to
      // the ambient pressure.
      final barPressure = _pressureAdjustment(id: 'adj_bar', name: 'Air Pressure', unit: 'bar');
      final barFork = _component(name: 'Fork', adjustments: [barPressure]);

      final entry = _compute(
        components: [barFork],
        setups: [
          _setup(id: 's1', datetime: referenceDateTime, bikeAdjustmentValues: {barPressure.id: 5.5158}),
        ],
      ).single;

      expect(entry.unit.label, 'bar');
      expect(entry.predictedReading, closeTo(5.324, 0.005));
      expect(entry.relativeDelta, closeTo(-0.0347, 0.001));
    });

    test('non-pressure adjustments are ignored', () {
      // Intention: Only pump-read values may appear; clicks, sag and travel must not.
      // Desired outcome: No entries at all for those adjustment types.
      // Not desired outcome: A "drift" reported for a rebound click count.
      final clicks = StepAdjustment(
        id: 'adj_clicks',
        name: 'Rebound',
        notes: null,
        unit: AdjustmentUnit.fromLegacy('clicks'),
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.slider,
      );
      final travel = NumericalAdjustment(
        id: 'adj_travel',
        name: 'Travel',
        notes: null,
        unit: AdjustmentUnit.fromLegacy('mm'),
      );
      final sag = SagAdjustment(id: 'adj_sag', name: 'Sag', notes: null);
      final component = _component(name: 'Fork', adjustments: [clicks, travel, sag]);

      final entries = _compute(
        components: [component],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {clicks.id: 5, travel.id: 160.0, sag.id: 20.0},
          ),
        ],
      );

      expect(entries, isEmpty);
    });

    test('an adjustment that was never recorded has nothing to compare against', () {
      // Intention: A pressure added to a component but not yet logged.
      // Desired outcome: Skipped silently.
      // Not desired outcome: An entry built on a missing reference value.
      final entries = _compute(
        components: [fork],
        setups: [_setup(id: 's1', datetime: referenceDateTime, bikeAdjustmentValues: {})],
      );

      expect(entries, isEmpty);
    });

    test('a zero or negative recorded pressure is skipped', () {
      // Intention: An empty chamber has no meaningful relative drift, and its
      // relative delta would divide by zero.
      // Desired outcome: No entry.
      // Not desired outcome: An infinite or NaN percentage on screen.
      final entries = _compute(
        components: [fork],
        setups: [
          _setup(id: 's1', datetime: referenceDateTime, bikeAdjustmentValues: {forkPressure.id: 0.0}),
        ],
      );

      expect(entries, isEmpty);
    });
  });

  group('PressureDriftService missing conditions', () {
    late NumericalAdjustment forkPressure;
    late Component fork;
    late DateTime referenceDateTime;

    setUp(() {
      forkPressure = _pressureAdjustment(id: 'adj_fork_pressure', name: 'Air Pressure');
      fork = _component(name: 'Fork', adjustments: [forkPressure]);
      referenceDateTime = DateTime(2025, 4, 2).toUtc();
    });

    List<PressureDriftEntry> computeWith({
      double? referenceTemperatureC = _referenceTemperatureC,
      double? referenceAltitudeM = _referenceAltitudeM,
      ContextWeather? weather,
      ContextPosition? position,
    }) {
      return _compute(
        components: [fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {forkPressure.id: 80.0},
            temperatureC: referenceTemperatureC,
            altitudeM: referenceAltitudeM,
          ),
        ],
        weather: weather,
        position: position,
      );
    }

    test('nothing is reported when a temperature or altitude is missing', () {
      // Intention: Both conditions are needed on both sides. Substituting a
      // standard value (sea level, say) would turn missing data into a
      // confidently wrong recommendation.
      // Desired outcome: No entry whenever any of the four inputs is absent.
      // Not desired outcome: A partial estimate presented like a full one.
      expect(computeWith(referenceTemperatureC: null), isEmpty);
      expect(computeWith(referenceAltitudeM: null), isEmpty);
      expect(computeWith(weather: _currentWeather(temperatureC: null)), isEmpty);
      expect(computeWith(position: _currentPosition(altitudeM: null)), isEmpty);
      expect(
        PressureDriftService.compute(
          components: [fork],
          provenance: const {},
          currentWeather: null,
          currentPosition: null,
        ),
        isEmpty,
      );
      // Sanity check that the fixture itself does produce an entry.
      expect(computeWith(), hasLength(1));
    });
  });
}
