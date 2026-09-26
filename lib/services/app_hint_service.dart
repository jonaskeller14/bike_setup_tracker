import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_hint.dart';
import '../models/app_settings.dart';
import '../models/component/installation.dart';
import '../repositories/app_repository.dart';
import '../utils/app_info.dart';
import '../utils/installation_timeline_validation.dart';

class AppHintService extends ChangeNotifier {
  static const _preferencePrefix = 'app_hint.';
  static const _legacyPreferencePrefix = 'app_settings.';
  static const _releaseBaselineKey = '${_preferencePrefix}releaseBaselineBuild';
  static const _replayBaselineBuild = 0;  // Baseline written by [resetAll]
  static const _legacyHints = {
    AppHint.garageGesturesV1: 'showGarageListHint',
    AppHint.gettingStartedV1: 'showGettingStartedGuideHint',
    AppHint.setupTasksV1: 'showSetupTaskHint',
    AppHint.setupCalendarV1: 'showSetupCalendarHint',
    AppHint.stravaLinkGearV1: 'showStravaLinkGearHint',
  };

  AppRepository _appRepository;
  AppSettings _appSettings;

  final Map<AppHint, int> _releaseBuilds;
  final int _currentBuild;

  final Map<AppHint, AppHintStatus> _statuses = {};
  final Map<AppHintPlacement, AppHint?> _activeHints = {};
  bool _hintHandledThisSession = false;
  int? _releaseBaselineBuild;

  factory AppHintService({
    required AppRepository appRepository,
    required AppSettings appSettings,
    Map<AppHint, int> releaseBuilds = releaseHintBuilds,
    int currentBuild = AppInfo.buildNumber,
  }) => AppHintService._(appRepository, appSettings, releaseBuilds, currentBuild);

  AppHintService._(this._appRepository, this._appSettings, this._releaseBuilds, this._currentBuild);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    await _migrateLegacyStatuses(preferences);
    for (final hint in AppHint.values) {
      final storedValue = preferences.get(_keyFor(hint));
      final status = AppHintStatus.values.firstWhere(
        (status) => storedValue is String && status.name == storedValue,
        orElse: () => AppHintStatus.unseen,
      );
      if (status != AppHintStatus.unseen) _statuses[hint] = status;
    }
    await _resolveReleaseBaseline(preferences);
  }

  AppHintStatus statusOf(AppHint hint) => _statuses[hint] ?? AppHintStatus.unseen;

  bool shouldOfferInstallationTimeline(List<Installation> installations) {
    return !_appSettings.enableInstallationTimeline &&
        !isComplexInstallationTimeline(installations) &&
        statusOf(AppHint.installationTimelineV1) == AppHintStatus.unseen;
  }

  void update({
    required AppRepository appRepository,
    required AppSettings appSettings,
  }) {
    _appRepository = appRepository;
    _appSettings = appSettings;
    if (_cacheActiveHints()) notifyListeners();
  }

  /// Returns the highest-priority eligible hint for [placement], if any.
  AppHint? activeHintFor(AppHintPlacement placement) {
    if (_hintHandledThisSession) return null;

    return switch (placement) {
      AppHintPlacement.garageHeader => _gettingStartedHint() ?? _releaseHint() ?? _garageGesturesHint(),
      AppHintPlacement.setupHeader => _gettingStartedHint() ?? _releaseHint() ?? _setupTaskHint() ?? _setupCalendarHint(),
      AppHintPlacement.setupComparison => _setupComparisonHint(),
      AppHintPlacement.stravaDashboardGear => _stravaLinkGearHint(),
    };
  }

  Future<void> dismiss(AppHint hint) => _setStatus(hint, AppHintStatus.dismissed);
  Future<void> complete(AppHint hint) => _setStatus(hint, AppHintStatus.completed);

  Future<void> resetAll() async {
    final changed = _statuses.isNotEmpty || _hintHandledThisSession || _releaseBaselineBuild != _replayBaselineBuild;
    if (!changed) return;

    _statuses.clear();
    _hintHandledThisSession = false;
    _releaseBaselineBuild = _replayBaselineBuild;
    await _removePersistedStatuses();
    await _persistReleaseBaseline(_replayBaselineBuild);
    _cacheActiveHints();
    notifyListeners();
  }

  /// The oldest "What's new" announcement the user has not handled yet.
  AppHint? _releaseHint() {
    final baseline = _releaseBaselineBuild;
    if (baseline == null) return null;

    AppHint? oldest;
    var oldestBuild = 0;
    for (final entry in _releaseBuilds.entries) {
      final eligible =
          entry.value > baseline && entry.value <= _currentBuild && statusOf(entry.key) == AppHintStatus.unseen;
      if (!eligible) continue;
      if (oldest == null || entry.value < oldestBuild) {
        oldest = entry.key;
        oldestBuild = entry.value;
      }
    }
    return oldest;
  }

  AppHint? _garageGesturesHint() {
    final eligible =
        _appRepository.bikes.length >= 2 &&
        _appRepository.components.isNotEmpty &&
        statusOf(AppHint.garageGesturesV1) == AppHintStatus.unseen;
    return eligible ? AppHint.garageGesturesV1 : null;
  }

  AppHint? _gettingStartedHint() {
    final hasCompletedSteps =
        _appRepository.bikes.isNotEmpty && _appRepository.components.isNotEmpty && _appRepository.setups.isNotEmpty;
    final eligible = !hasCompletedSteps && statusOf(AppHint.gettingStartedV1) == AppHintStatus.unseen;
    return eligible ? AppHint.gettingStartedV1 : null;
  }

  AppHint? _setupTaskHint() {
    final eligible =
        !_appSettings.enableTask &&
        _appRepository.filteredSetups.isNotEmpty &&
        statusOf(AppHint.setupTasksV1) == AppHintStatus.unseen;
    return eligible ? AppHint.setupTasksV1 : null;
  }

  AppHint? _setupCalendarHint() {
    final eligible =
        !_appSettings.enableCalendar &&
        (_appRepository.filteredSetups.length >= 2 || _appRepository.filteredStravaActivities.length > 2) &&
        statusOf(AppHint.setupCalendarV1) == AppHintStatus.unseen;
    return eligible ? AppHint.setupCalendarV1 : null;
  }

  AppHint? _setupComparisonHint() {
    final eligible = statusOf(AppHint.setupComparisonV1) == AppHintStatus.unseen;
    return eligible ? AppHint.setupComparisonV1 : null;
  }

  AppHint? _stravaLinkGearHint() {
    final hasUnlinkedGears = _appRepository.stravaGears.values.any(
      (gear) => _appRepository.bikes.values.every((bike) => bike.stravaGear != gear.id),
    );
    final eligible = hasUnlinkedGears && statusOf(AppHint.stravaLinkGearV1) == AppHintStatus.unseen;
    return eligible ? AppHint.stravaLinkGearV1 : null;
  }

  Future<void> _setStatus(AppHint hint, AppHintStatus status) async {
    final statusChanged = statusOf(hint) != status;
    final sessionChanged = !_hintHandledThisSession;
    if (!statusChanged && !sessionChanged) return;

    _statuses[hint] = status;
    _hintHandledThisSession = true;
    await _persistStatus(hint, status);
    _cacheActiveHints();
    notifyListeners();
  }

  bool _cacheActiveHints() {
    var changed = false;
    for (final placement in AppHintPlacement.values) {
      final activeHint = activeHintFor(placement);
      if (_activeHints[placement] != activeHint) {
        _activeHints[placement] = activeHint;
        changed = true;
      }
    }
    return changed;
  }

  String _keyFor(AppHint hint) => '$_preferencePrefix${hint.name}.status';

  Future<void> _persistStatus(AppHint hint, AppHintStatus status) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_keyFor(hint), status.name);
  }

  Future<void> _persistReleaseBaseline(int build) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_releaseBaselineKey, build);
  }

  Future<void> _resolveReleaseBaseline(SharedPreferences preferences) async {
    final storedBaseline = preferences.getInt(_releaseBaselineKey);
    if (storedBaseline != null) {
      _releaseBaselineBuild = storedBaseline;
      return;
    }

    _releaseBaselineBuild = _currentBuild - 1;
    await _persistReleaseBaseline(_releaseBaselineBuild!);
  }

  Future<void> _removePersistedStatuses() async {
    final preferences = await SharedPreferences.getInstance();
    for (final hint in AppHint.values) {
      await preferences.remove(_keyFor(hint));
    }
  }

  Future<void> _migrateLegacyStatuses(SharedPreferences preferences) async {
    for (final entry in _legacyHints.entries) {
      final key = _keyFor(entry.key);
      if (preferences.containsKey(key)) {
        await preferences.remove('$_legacyPreferencePrefix${entry.value}');
        continue;
      }

      final legacyValue = preferences.get('$_legacyPreferencePrefix${entry.value}');
      final status = legacyValue is bool && !legacyValue ? AppHintStatus.dismissed : AppHintStatus.unseen;
      final persisted = await preferences.setString(key, status.name);
      if (persisted) {
        await preferences.remove('$_legacyPreferencePrefix${entry.value}');
      }
    }
  }
}
