import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'error_reporter.dart';

/// Whether this build has to stop at the update gate. A minimum of 0 or less
/// means none is set; web and desktop have no store to update from.
bool isAppBlocked({
  required int build,
  required int minSupportedBuild,
  required bool supportedPlatform,
  bool simulateOutdatedBuild = false,
}) {
  if (!supportedPlatform) return false;
  if (simulateOutdatedBuild) return true;
  return minSupportedBuild > 0 && build < minSupportedBuild;
}

abstract interface class RemoteConfigSource {
  /// Applies [defaults] and the fetch settings, then loads the last activated
  /// values from the device. Never fetches.
  Future<void> initialize({
    required Map<String, int> defaults,
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  });

  int getInt(String key);

  /// Fetches the latest values, which the next [initialize] (cold start) reads.
  Future<void> fetchAndActivate();
}

class FirebaseRemoteConfigSource implements RemoteConfigSource {
  FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;

  @override
  Future<void> initialize({
    required Map<String, int> defaults,
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) async {
    await _remoteConfig.setDefaults(defaults);
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(fetchTimeout: fetchTimeout, minimumFetchInterval: minimumFetchInterval),
    );
    await _remoteConfig.ensureInitialized();
  }

  @override
  int getInt(String key) => _remoteConfig.getInt(key);

  @override
  Future<void> fetchAndActivate() => _remoteConfig.fetchAndActivate();
}

/// The remote `min_supported_build`. Startup reads only the value activated by
/// an earlier fetch, so a raised minimum applies from the next cold start on.
class AppVersionConfig {
  static const minSupportedBuildKey = 'min_supported_build';

  final RemoteConfigSource _source;
  final bool supportedPlatform;
  final Duration _initializeTimeout;
  Future<void>? _initialized;

  AppVersionConfig({
    RemoteConfigSource? source,
    bool? supportedPlatform,
    this._initializeTimeout = const Duration(seconds: 2),
  }) : _source = source ?? FirebaseRemoteConfigSource(),
       supportedPlatform =
           supportedPlatform ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS));

  /// 0, which never gates, on web and desktop, before the first fetch and on
  /// any error or timeout.
  Future<int> loadMinSupportedBuild() async {
    if (!supportedPlatform) return 0;
    try {
      await _initialize().timeout(_initializeTimeout);
      return _source.getInt(minSupportedBuildKey);
    } catch (e) {
      logBreadcrumb('Remote Config unavailable at startup: $e');
      return 0;
    }
  }

  void refreshInBackground() {
    if (!supportedPlatform) return;
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      await _initialize();
      await _source.fetchAndActivate();
    } catch (e) {
      logBreadcrumb('Remote Config fetch failed: $e');
    }
  }

  // Shared, so a refresh after a startup timeout waits for the same call.
  Future<void> _initialize() => _initialized ??= _source.initialize(
    defaults: const {minSupportedBuildKey: 0},
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
  );
}
