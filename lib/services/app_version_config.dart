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
}) {
  if (!supportedPlatform) return false;
  return minSupportedBuild > 0 && build < minSupportedBuild;
}

abstract interface class RemoteConfigSource {
  /// Loads the last activated values from the device. Never fetches.
  Future<void> loadActivated();

  /// A key that was never fetched reads as 0.
  int getInt(String key);

  /// Applies the fetch settings, then fetches the latest values, which the
  /// next [loadActivated] (cold start) reads.
  Future<void> fetchAndActivate({required Duration fetchTimeout, required Duration minimumFetchInterval});
}

class FirebaseRemoteConfigSource implements RemoteConfigSource {
  FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;

  @override
  Future<void> loadActivated() => _remoteConfig.ensureInitialized();

  @override
  int getInt(String key) => _remoteConfig.getInt(key);

  @override
  Future<void> fetchAndActivate({required Duration fetchTimeout, required Duration minimumFetchInterval}) async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(fetchTimeout: fetchTimeout, minimumFetchInterval: minimumFetchInterval),
    );
    await _remoteConfig.fetchAndActivate();
  }
}

/// The remote `min_supported_build`. Startup reads only the value activated by
/// an earlier fetch, so a raised minimum applies from the next cold start on.
class AppVersionConfig {
  static const minSupportedBuildKey = 'min_supported_build';

  final RemoteConfigSource _source;
  final bool supportedPlatform;
  final Duration _initializeTimeout;

  AppVersionConfig({
    RemoteConfigSource? source,
    bool? supportedPlatform,
    this._initializeTimeout = const Duration(seconds: 5),
  }) : _source = source ?? FirebaseRemoteConfigSource(),
       supportedPlatform =
           supportedPlatform ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS));

  /// 0, which never gates, on web and desktop, before the first fetch and on
  /// any error or timeout.
  ///
  /// Only loads the activated values: setting defaults and fetch settings
  /// first took about 1.4 s on Android. Loading alone still took about 2 s on a
  /// cold debug start on the emulator, hence the generous timeout. It runs
  /// alongside the settings and DB load, so it rarely delays startup.
  Future<int> loadMinSupportedBuild() async {
    if (!supportedPlatform) return 0;
    try {
      await _source.loadActivated().timeout(_initializeTimeout);
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
      await _source.fetchAndActivate(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      );
    } catch (e) {
      logBreadcrumb('Remote Config fetch failed: $e');
    }
  }
}
