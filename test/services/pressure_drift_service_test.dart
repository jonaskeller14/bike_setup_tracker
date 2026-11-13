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
const _reference = PressureConditions(temperatureC: _referenceTemperatureC, altitudeM: _referenceAltitudeM);

/// Conditions now: colder and much higher up.
const double _currentTemperatureC = 5;
const double _currentAltitudeM = 1800;
const _current = PressureConditions(temperatureC: _currentTemperatureC, altitudeM: _currentAltitudeM);

Setup _setup({
  required String id,
  required DateTime datetime,
  required Map<String, AdjustmentValue> bikeAdjustmentValues,
  double? temperatureC = _referenceTemperatureC,
  double? altitudeM = _referenceAltitudeM,
}) {
  return Setup(
    id: id,
    datetime: datetime,
    datetimeLocal: datetime.toLocal(),
    bike: 'bike_1',
    person: null,
    tags: const {},
    bikeAdjustmentValues: bikeAdjustmentValues,
    personAdjustmentValues: const {},
    position: altitudeM == null ? null : ContextPosition(latitude: 47, longitude: 11, altitude: altitudeM),
    weather: temperatureC == null ? null : ContextWeather(currentDateTime: datetime, currentTemperature: temperatureC),
  );
}

/// The moment every check runs at, unless a test passes its own.
final DateTime _checkedAt = DateTime(2025, 4, 20).toUtc();

Component _component({
  required String name,
  required List<Adjustment> adjustments,
  ComponentType componentType = ComponentType.fork,
}) {
  return Component(
    name: name,
    componentType: componentType,
    adjustments: adjustments,
    installations: [Installation.sinceBeginning(parent: 'bike_1')],
  );
}

NumericalAdjustment _pressureAdjustment({required String id, required String name, String unit = 'psi'}) {
  return NumericalAdjustment(id: id, name: name, notes: null, unit: AdjustmentUnit.fromLegacy(unit));
}

StepAdjustment _clicksAdjustment() {
  return StepAdjustment(
    id: 'adj_clicks',
    name: 'Rebound',
    notes: null,
    unit: AdjustmentUnit.fromLegacy('clicks'),
    step: 1,
    min: 0,
    max: 20,
    visualization: StepAdjustmentVisualization.slider,
  );
}

ContextWeather _currentWeather({double? temperatureC = _currentTemperatureC}) =>
    ContextWeather(currentDateTime: DateTime(2025, 4, 20), currentTemperature: temperatureC);

ContextPosition _currentPosition({double? altitudeM = _currentAltitudeM}) =>
    ContextPosition(latitude: 47, longitude: 11, altitude: altitudeM);

PressureCheck _check({
  required List<Component> components,
  required Iterable<Setup> setups,
  ContextWeather? weather,
  ContextPosition? position,
  double significanceThreshold = PressureDriftService.defaultSignificanceThreshold,
}) {
  return PressureDriftService.check(
    components: components,
    provenance: SetupResolutionService.resolveHistoricalProvenanceAt(
      datetime: _checkedAt,
      setups: setups,
    ),
    currentWeather: weather ?? _currentWeather(),
    currentPosition: position ?? _currentPosition(),
    at: _checkedAt,
    significanceThreshold: significanceThreshold,
  );
}

List<PressureDriftEntry> _driftEntries({
  required List<Component> components,
  required Iterable<Setup> setups,
  ContextWeather? weather,
  ContextPosition? position,
}) => _check(components: components, setups: setups, weather: weather, position: position).driftEntries;

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
      final atDestination = PressureDriftService.readingAtPa(gaugePa: gaugePa, from: _reference, to: _current);
      final backHome = PressureDriftService.readingAtPa(gaugePa: atDestination, from: _current, to: _reference);
      expect(backHome, closeTo(gaugePa, 0.001));
    });

    test('a prediction splits the drift into shares that add up to it', () {
      // Intention: The card and the info sheet both show the split, from the same function.
      // Desired outcome: 80 psi reads ~77.2 psi, and the shares reconstruct the total.
      // Not desired outcome: Shares computed in a different unit than the reading.
      final prediction = PressureDriftService.predict(
        value: 80,
        unit: AdjustmentUnit.fromLegacy('psi') as KnownUnit,
        from: _reference,
        to: _current,
      );
      expect(prediction.reading, closeTo(77.22, 0.05));
      expect(prediction.altitudeShare, closeTo(2.03, 0.05));
      expect(prediction.leakShare, 0);
      expect(prediction.temperatureShare + prediction.altitudeShare, closeTo(prediction.reading - 80, 0.0001));
    });
  });

  group('PressureDriftService air loss', () {
    late NumericalAdjustment tirePressure;
    late NumericalAdjustment forkPressure;
    late Component tire;
    late Component fork;

    setUp(() {
      tirePressure = _pressureAdjustment(id: 'adj_tire_pressure', name: 'Tire Pressure');
      forkPressure = _pressureAdjustment(id: 'adj_fork_pressure', name: 'Air Pressure');
      tire = _component(name: 'Rear Tire', adjustments: [tirePressure], componentType: ComponentType.tire);
      fork = _component(name: 'Fork', adjustments: [forkPressure]);
    });

    /// The reference is passed as provenance directly, so a reference at or
    /// after the checked moment can be tested too.
    PressureDriftEntry entryAfter(
      Duration age, {
      required Component component,
      required Adjustment adjustment,
      bool sameConditions = true,
    }) {
      const value = NumericalValue(30.0);
      return PressureDriftService.check(
        components: [component],
        provenance: {
          adjustment.id: (
            value: value,
            setup: _setup(id: 's1', datetime: _checkedAt.subtract(age), bikeAdjustmentValues: {adjustment.id: value}),
          ),
        },
        currentWeather: _currentWeather(temperatureC: sameConditions ? _referenceTemperatureC : _currentTemperatureC),
        currentPosition: _currentPosition(altitudeM: sameConditions ? _referenceAltitudeM : _currentAltitudeM),
        at: _checkedAt,
      ).driftEntries.single;
    }

    test('only tyres and wheels leak at a steady rate', () {
      for (final type in [ComponentType.tire, ComponentType.wheelFront, ComponentType.wheelRear]) {
        expect(PressureDriftService.leakRatePerDay(type), PressureDriftService.tireLeakRatePerDay);
      }
      for (final type in [ComponentType.fork, ComponentType.shock, ComponentType.seatpost, ComponentType.other]) {
        expect(PressureDriftService.leakRatePerDay(type), 0);
      }
      expect(PressureDriftService.tireLeakRatePerDay, closeTo(0.00435, 0.00001));
    });

    test('a tyre loses 3 % in a week of identical weather, all of it as leak', () {
      // Intention: Verify the assumed rate end to end, with no other cause in play.
      // Desired outcome: 30 psi reads 29.1 psi after 7 days, and the leak is the whole drift.
      // Not desired outcome: A linear psi-per-day loss, or leak counted as temperature.
      final entry = entryAfter(const Duration(days: 7), component: tire, adjustment: tirePressure);

      expect(entry.elapsedDays, closeTo(7, 0.0001));
      expect(entry.relativeDelta, closeTo(-0.03, 0.00001));
      expect(entry.leakShare, closeTo(entry.delta, 0.00001));
      expect(entry.temperatureShare, closeTo(0, 0.00001));
      expect(entry.altitudeShare, closeTo(0, 0.00001));
    });

    test('a fork left for a month leaks nothing', () {
      // Intention: Healthy air springs have no steady leak, so the model assumes none.
      // Desired outcome: No leak share and no drift in identical weather.
      // Not desired outcome: The tyre rate applied to every pressure.
      final entry = entryAfter(const Duration(days: 30), component: fork, adjustment: forkPressure);

      expect(entry.elapsedDays, closeTo(30, 0.0001));
      expect(entry.leakShare, 0);
      expect(entry.delta, closeTo(0, 0.00001));
    });

    test('a tyre checked right after its reference matches the model without leakage', () {
      // Intention: A second setup on the same ride must read exactly as before Phase 3.
      final entry = entryAfter(Duration.zero, component: tire, adjustment: tirePressure, sameConditions: false);
      final withoutLeak = PressureDriftService.predict(
        value: 30,
        unit: tirePressure.unit as KnownUnit,
        from: _reference,
        to: _current,
      );

      expect(entry.elapsedDays, 0);
      expect(entry.leakShare, 0);
      expect(entry.predictedReading, closeTo(withoutLeak.reading, 0.0000001));
    });

    test('a reference dated after the checked moment leaks nothing', () {
      // Intention: Clock skew between devices, or an edited setup dated before
      // its reference, must not turn into a pressure gain.
      // Desired outcome: Elapsed time clamps to zero.
      // Not desired outcome: A negative elapsed time growing the pressure.
      final entry = entryAfter(const Duration(days: -3), component: tire, adjustment: tirePressure);

      expect(entry.elapsedDays, 0);
      expect(entry.leakShare, 0);
      expect(entry.delta, closeTo(0, 0.00001));
    });

    test('leak, temperature and altitude shares add up to the total drift', () {
      final entry = entryAfter(
        const Duration(days: 10),
        component: tire,
        adjustment: tirePressure,
        sameConditions: false,
      );

      expect(entry.leakShare, lessThan(0));
      expect(entry.temperatureShare, lessThan(0));
      expect(entry.altitudeShare, greaterThan(0));
      expect(entry.leakShare + entry.temperatureShare + entry.altitudeShare, closeTo(entry.delta, 0.0000001));
    });

    test('the default 3 % threshold is crossed after about a week', () {
      // Intention: The expected effect stated in the plan: an untouched tyre is
      // flagged after roughly a week, even when the weather hasn't changed.
      expect(entryAfter(const Duration(days: 6), component: tire, adjustment: tirePressure).isSignificant, isFalse);
      expect(entryAfter(const Duration(days: 8), component: tire, adjustment: tirePressure).isSignificant, isTrue);
    });
  });

  group('PressureConditions', () {
    test('needs both a temperature and an altitude', () {
      final weather = _currentWeather();
      final position = _currentPosition();

      expect(PressureConditions.of(weather, position), _current);
      expect(PressureConditions.of(null, position), isNull);
      expect(PressureConditions.of(weather, null), isNull);
      expect(PressureConditions.of(_currentWeather(temperatureC: null), position), isNull);
      expect(PressureConditions.of(weather, _currentPosition(altitudeM: null)), isNull);
    });

    test('a temperature at or below absolute zero is bad data', () {
      final position = _currentPosition();
      expect(PressureConditions.of(_currentWeather(temperatureC: -273.15), position), isNull);
      expect(PressureConditions.of(_currentWeather(temperatureC: -300), position), isNull);
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
      final entries = _driftEntries(
        components: [fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {forkPressure.id: const NumericalValue(80.0)},
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
      expect(entry.referenceConditions, _reference);
      expect(entry.currentConditions, _current);
    });

    test('the significance threshold is configurable', () {
      // Intention: Riders pick their own threshold in the feature settings.
      // Desired outcome: The same ~3.5 % drift is flagged at 3 % but not at 5 %.
      // Not desired outcome: The default threshold applied regardless of the setting.
      final setups = [
        _setup(
          id: 's1',
          datetime: referenceDateTime,
          bikeAdjustmentValues: {forkPressure.id: const NumericalValue(80.0)},
        ),
      ];
      PressureDriftEntry entryAt(double threshold) =>
          _check(components: [fork], setups: setups, significanceThreshold: threshold).driftEntries.single;

      expect(entryAt(0.03).isSignificant, isTrue);
      expect(entryAt(0.05).isSignificant, isFalse);
    });

    test('the two causes are reported separately and add up to the total', () {
      // Intention: The split is the point of the card — cold and altitude pull in
      // opposite directions, so a big temperature swing can still be harmless.
      // Desired outcome: Temperature loses ~4.8 psi, altitude gains ~2.0 psi.
      // Not desired outcome: Shares that don't reconstruct the total drift.
      final entry = _driftEntries(
        components: [fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {forkPressure.id: const NumericalValue(80.0)},
          ),
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

      final entry = _driftEntries(
        components: [wheel],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {tirePressure.id: const NumericalValue(25.0)},
          ),
        ],
      ).single;

      expect(entry.predictedReading, closeTo(25.04, 0.05));
      expect(entry.isSignificant, isFalse);
    });

    test('unchanged conditions produce no drift', () {
      // Intention: The common case of logging a second setup on the same ride.
      // Desired outcome: The pump reads exactly what it read before.
      // Not desired outcome: Rounding noise presented as a drift.
      final entry = _driftEntries(
        components: [fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {forkPressure.id: const NumericalValue(80.0)},
          ),
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

      final entry = _driftEntries(
        components: [barFork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {barPressure.id: const NumericalValue(5.5158)},
          ),
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
      final clicks = _clicksAdjustment();
      final travel = NumericalAdjustment(
        id: 'adj_travel',
        name: 'Travel',
        notes: null,
        unit: AdjustmentUnit.fromLegacy('mm'),
      );
      final sag = SagAdjustment(id: 'adj_sag', name: 'Sag', notes: null);
      final component = _component(name: 'Fork', adjustments: [clicks, travel, sag]);

      final check = _check(
        components: [component],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {
              clicks.id: const StepValue(5),
              travel.id: const NumericalValue(160.0),
              sag.id: const NumericalValue(20.0),
            },
          ),
        ],
      );

      expect(check.entries, isEmpty);
    });

    test('an adjustment that was never recorded has nothing to compare against', () {
      // Intention: A pressure added to a component but not yet logged.
      // Desired outcome: Skipped silently.
      // Not desired outcome: An entry built on a missing reference value.
      final check = _check(
        components: [fork],
        setups: [_setup(id: 's1', datetime: referenceDateTime, bikeAdjustmentValues: {})],
      );

      expect(check.entries, isEmpty);
    });

    test('a zero or negative recorded pressure is skipped', () {
      // Intention: An empty chamber has no meaningful relative drift, and its
      // relative delta would divide by zero.
      // Desired outcome: No entry.
      // Not desired outcome: An infinite or NaN percentage on screen.
      for (final value in [0.0, -5.0]) {
        final check = _check(
          components: [fork],
          setups: [
            _setup(
              id: 's1',
              datetime: referenceDateTime,
              bikeAdjustmentValues: {forkPressure.id: NumericalValue(value)},
            ),
          ],
        );
        expect(check.entries, isEmpty);
      }
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

    List<PressureDriftEntry> driftWith({
      double? referenceTemperatureC = _referenceTemperatureC,
      double? referenceAltitudeM = _referenceAltitudeM,
      ContextWeather? weather,
      ContextPosition? position,
    }) {
      return _driftEntries(
        components: [fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {forkPressure.id: const NumericalValue(80.0)},
            temperatureC: referenceTemperatureC,
            altitudeM: referenceAltitudeM,
          ),
        ],
        weather: weather,
        position: position,
      );
    }

    test('no drift is reported when a temperature or altitude is missing', () {
      // Intention: Both conditions are needed on both sides. Substituting a
      // standard value (sea level, say) would turn missing data into a
      // confidently wrong recommendation.
      // Desired outcome: No drift entry whenever any of the four inputs is absent.
      // Not desired outcome: A partial estimate presented like a full one.
      expect(driftWith(referenceTemperatureC: null), isEmpty);
      expect(driftWith(referenceAltitudeM: null), isEmpty);
      expect(driftWith(weather: _currentWeather(temperatureC: null)), isEmpty);
      expect(driftWith(position: _currentPosition(altitudeM: null)), isEmpty);
      expect(
        PressureDriftService.check(
          components: [fork],
          provenance: const {},
          currentWeather: null,
          currentPosition: null,
          at: _checkedAt,
        ).entries,
        isEmpty,
      );
      // Sanity check that the fixture itself does produce an entry.
      expect(driftWith(), hasLength(1));
    });
  });

  group('PressureDriftService gap', () {
    late NumericalAdjustment forkPressure;
    late Component fork;
    late DateTime referenceDateTime;

    setUp(() {
      forkPressure = _pressureAdjustment(id: 'adj_fork_pressure', name: 'Air Pressure');
      fork = _component(name: 'Fork', adjustments: [forkPressure]);
      referenceDateTime = DateTime(2025, 4, 2).toUtc();
    });

    PressureDriftGap? gapWith({
      AdjustmentValue? recorded = const NumericalValue(80.0),
      double? referenceTemperatureC = _referenceTemperatureC,
      double? referenceAltitudeM = _referenceAltitudeM,
      ContextWeather? weather,
      ContextPosition? position,
    }) {
      return _check(
        components: [fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {forkPressure.id: ?recorded},
            temperatureC: referenceTemperatureC,
            altitudeM: referenceAltitudeM,
          ),
        ],
        weather: weather,
        position: position,
      ).gap;
    }

    test('there is no gap while a drift can be computed', () {
      expect(gapWith(), isNull);
    });

    test('a pressure never recorded, or recorded empty, has nothing to compare', () {
      expect(gapWith(recorded: null), PressureDriftGap.noRecordedPressure);
      expect(gapWith(recorded: const NumericalValue(0.0)), PressureDriftGap.noRecordedPressure);
    });

    test('a pressure recorded without conditions cannot be compared', () {
      expect(gapWith(referenceTemperatureC: null), PressureDriftGap.noRecordedConditions);
      expect(gapWith(referenceAltitudeM: null), PressureDriftGap.noRecordedConditions);
    });

    test('missing current conditions come last, since the rider can still add them', () {
      // Intention: The page shows a loading state for this gap while fetching,
      // so it must not hide a gap that no fetch can close.
      expect(gapWith(weather: _currentWeather(temperatureC: null)), PressureDriftGap.noCurrentConditions);
      expect(gapWith(position: _currentPosition(altitudeM: null)), PressureDriftGap.noCurrentConditions);
      expect(
        gapWith(recorded: null, weather: _currentWeather(temperatureC: null)),
        PressureDriftGap.noRecordedPressure,
      );
      expect(
        gapWith(referenceTemperatureC: null, weather: _currentWeather(temperatureC: null)),
        PressureDriftGap.noRecordedConditions,
      );
    });

    test('a bike needs a pressure adjustment for the check', () {
      expect(PressureDriftService.hasPressureAdjustment([fork]), isTrue);
      final shock = _component(
        name: 'Shock',
        adjustments: [
          NumericalAdjustment(id: 'adj_travel', name: 'Travel', notes: null, unit: AdjustmentUnit.fromLegacy('mm')),
        ],
      );
      expect(PressureDriftService.hasPressureAdjustment([shock]), isFalse);
    });
  });

  group('PressureDriftService pressures without reference conditions', () {
    late NumericalAdjustment forkPressure;
    late NumericalAdjustment shockPressure;
    late Component fork;
    late Component shock;
    late DateTime referenceDateTime;

    setUp(() {
      forkPressure = _pressureAdjustment(id: 'adj_fork_pressure', name: 'Air Pressure');
      shockPressure = _pressureAdjustment(id: 'adj_shock_pressure', name: 'Shock Pressure');
      fork = _component(name: 'Fork', adjustments: [forkPressure]);
      shock = _component(name: 'Shock', adjustments: [shockPressure]);
      referenceDateTime = DateTime(2025, 4, 2).toUtc();
    });

    test('pressures split between drift entries and reference gaps, in component order', () {
      // Intention: The card lists both kinds of rows, so every recorded pressure
      // must land in exactly one of them.
      // Desired outcome: The fork (reference with conditions) is a drift entry,
      // the shock (reference without temperature) a reference gap.
      // Not desired outcome: A pressure listed twice, or dropped.
      final check = _check(
        components: [shock, fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {forkPressure.id: const NumericalValue(80.0)},
          ),
          _setup(
            id: 's2',
            datetime: referenceDateTime.add(const Duration(days: 1)),
            bikeAdjustmentValues: {
              forkPressure.id: const NumericalValue(80.0),
              shockPressure.id: const NumericalValue(200.0),
            },
            temperatureC: null,
          ),
        ],
      );

      expect(check.entries.map((entry) => entry.adjustmentId), [shockPressure.id, forkPressure.id]);
      expect(check.driftEntries.single.referenceSetup.id, 's1');
      final gap = check.referenceGapEntries.single;
      expect(gap.adjustmentId, shockPressure.id);
      expect(gap.adjustmentName, 'Shock Pressure');
      expect(gap.componentName, 'Shock');
      expect(gap.unit.label, 'psi');
      expect(gap.referenceSetup.id, 's2');
      expect(gap.referenceValue, 200.0);
      expect(check.gap, isNull);
    });

    test('a reference missing either temperature or altitude is a gap', () {
      final check = _check(
        components: [fork, shock],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {shockPressure.id: const NumericalValue(200.0)},
            altitudeM: null,
          ),
          _setup(
            id: 's2',
            datetime: referenceDateTime.add(const Duration(days: 1)),
            bikeAdjustmentValues: {forkPressure.id: const NumericalValue(80.0)},
            temperatureC: null,
          ),
        ],
      );

      expect(check.referenceGapEntries.map((entry) => entry.adjustmentId), [forkPressure.id, shockPressure.id]);
      expect(check.driftEntries, isEmpty);
      expect(check.gap, PressureDriftGap.noRecordedConditions);
      expect(check.currentConditions, _current);
    });

    test('nothing is listed while the current conditions are missing', () {
      // Intention: A mark made without today's conditions could not start a
      // usable reference, so there is nothing to offer.
      final setups = [
        _setup(
          id: 's1',
          datetime: referenceDateTime,
          bikeAdjustmentValues: {forkPressure.id: const NumericalValue(80.0)},
          temperatureC: null,
        ),
      ];

      expect(_check(components: [fork], setups: setups).referenceGapEntries, hasLength(1));
      for (final check in [
        _check(components: [fork], setups: setups, weather: _currentWeather(temperatureC: null)),
        _check(components: [fork], setups: setups, position: _currentPosition(altitudeM: null)),
      ]) {
        expect(check.entries, isEmpty);
        expect(check.currentConditions, isNull);
      }
    });

    test('zero, negative and non-numerical values are skipped', () {
      final clicks = _clicksAdjustment();
      final component = _component(name: 'Fork', adjustments: [forkPressure, shockPressure, clicks]);

      final check = _check(
        components: [component],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {
              forkPressure.id: const NumericalValue(0.0),
              shockPressure.id: const NumericalValue(-5.0),
              clicks.id: const StepValue(5),
            },
            temperatureC: null,
            altitudeM: null,
          ),
        ],
      );

      expect(check.entries, isEmpty);
      expect(check.gap, PressureDriftGap.noRecordedPressure);
    });

    test('only pressures of the given components are listed', () {
      // Intention: The caller already filters out hidden component types, so a
      // component it leaves out must not appear.
      final check = _check(
        components: [fork],
        setups: [
          _setup(
            id: 's1',
            datetime: referenceDateTime,
            bikeAdjustmentValues: {
              forkPressure.id: const NumericalValue(80.0),
              shockPressure.id: const NumericalValue(200.0),
            },
            temperatureC: null,
          ),
        ],
      );

      expect(check.entries.map((entry) => entry.adjustmentId), [forkPressure.id]);
    });
  });
}
