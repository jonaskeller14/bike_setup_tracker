import 'dart:async';

import 'package:bike_setup_tracker/services/app_version_config.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemoteConfigSource implements RemoteConfigSource {
  Map<String, int> values = {};
  Future<void> Function() onInitialize = () async {};
  Future<void> Function() onFetch = () async {};
  int initializeCalls = 0;
  int fetchCalls = 0;
  Map<String, int>? defaults;
  Duration? minimumFetchInterval;

  @override
  Future<void> initialize({
    required Map<String, int> defaults,
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) {
    initializeCalls++;
    this.defaults = defaults;
    this.minimumFetchInterval = minimumFetchInterval;
    return onInitialize();
  }

  @override
  int getInt(String key) => values[key] ?? defaults?[key] ?? 0;

  @override
  Future<void> fetchAndActivate() {
    fetchCalls++;
    return onFetch();
  }
}

void main() {
  group('isAppBlocked', () {
    bool blocked(int minimum, {bool supportedPlatform = true, bool simulate = false}) => isAppBlocked(
      build: 50,
      minSupportedBuild: minimum,
      supportedPlatform: supportedPlatform,
      simulateOutdatedBuild: simulate,
    );

    test('blocks only a build below the minimum', () {
      expect(blocked(51), isTrue);
      expect(blocked(50), isFalse);
      expect(blocked(49), isFalse);
    });

    test('a minimum of 0 or less never blocks', () {
      expect(blocked(0), isFalse);
      expect(blocked(-1), isFalse);
    });

    test('an unsupported platform never blocks', () {
      expect(blocked(51, supportedPlatform: false), isFalse);
      expect(blocked(0, supportedPlatform: false, simulate: true), isFalse);
    });

    test('a simulated outdated build blocks whatever the minimum', () {
      expect(blocked(0, simulate: true), isTrue);
      expect(blocked(49, simulate: true), isTrue);
    });
  });

  group('AppVersionConfig', () {
    late _FakeRemoteConfigSource source;

    setUp(() => source = _FakeRemoteConfigSource());

    AppVersionConfig config({bool supportedPlatform = true}) => AppVersionConfig(
      source: source,
      supportedPlatform: supportedPlatform,
      initializeTimeout: const Duration(milliseconds: 50),
    );

    test('returns the activated minimum', () async {
      source.values = {AppVersionConfig.minSupportedBuildKey: 52};

      expect(await config().loadMinSupportedBuild(), 52);
      expect(source.defaults, {AppVersionConfig.minSupportedBuildKey: 0});
      expect(source.minimumFetchInterval, Duration.zero);
    });

    test('returns the default 0 before any fetch', () async {
      expect(await config().loadMinSupportedBuild(), 0);
    });

    test('returns 0 when initializing fails', () async {
      source.values = {AppVersionConfig.minSupportedBuildKey: 52};
      source.onInitialize = () async => throw Exception('no Firebase');

      expect(await config().loadMinSupportedBuild(), 0);
    });

    test('returns 0 when initializing times out', () async {
      source.values = {AppVersionConfig.minSupportedBuildKey: 52};
      source.onInitialize = () => Completer<void>().future;

      expect(await config().loadMinSupportedBuild(), 0);
    });

    test('never touches Remote Config on an unsupported platform', () async {
      final unsupported = config(supportedPlatform: false);

      expect(await unsupported.loadMinSupportedBuild(), 0);
      unsupported.refreshInBackground();
      await pumpEventQueue();

      expect(source.initializeCalls, 0);
      expect(source.fetchCalls, 0);
    });

    test('refresh initializes once and then fetches', () async {
      final appVersionConfig = config();
      await appVersionConfig.loadMinSupportedBuild();

      appVersionConfig.refreshInBackground();
      await pumpEventQueue();

      expect(source.initializeCalls, 1);
      expect(source.fetchCalls, 1);
    });

    test('refresh swallows fetch errors', () async {
      source.onFetch = () async => throw Exception('offline');

      config().refreshInBackground();
      await pumpEventQueue();

      expect(source.fetchCalls, 1);
    });

    test('refresh swallows initialize errors and skips the fetch', () async {
      source.onInitialize = () async => throw Exception('no Firebase');

      config().refreshInBackground();
      await pumpEventQueue();

      expect(source.fetchCalls, 0);
    });
  });
}
