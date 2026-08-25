import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_hint.dart';
import '../models/app_settings.dart';
import '../repositories/app_repository.dart';

class AppHintService extends ChangeNotifier {
  static const _preferencePrefix = 'app_hint.';

  AppRepository _appRepository;
  AppSettings _appSettings;
  final Map<AppHint, AppHintStatus> _statuses = {};
  final Map<AppHintPlacement, AppHint?> _activeHints = {};
  bool _hintHandledThisSession = false;

  factory AppHintService({
    required AppRepository appRepository,
    required AppSettings appSettings,
  }) => AppHintService._(appRepository, appSettings);

  AppHintService._(this._appRepository, this._appSettings);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    for (final hint in AppHint.values) {
      final storedValue = preferences.getString(_keyFor(hint));
      final status = AppHintStatus.values.firstWhere(
        (status) => status.name == storedValue,
        orElse: () => AppHintStatus.unseen,
      );
      if (status != AppHintStatus.unseen) _statuses[hint] = status;
    }
  }

  AppHintStatus statusOf(AppHint hint) => _statuses[hint] ?? AppHintStatus.unseen;

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
      AppHintPlacement.garageHeader => _garageGesturesHint(),
      AppHintPlacement.setupHeader || AppHintPlacement.stravaDashboard => null,
    };
  }

  Future<void> dismiss(AppHint hint) => _setStatus(hint, AppHintStatus.dismissed);
  Future<void> complete(AppHint hint) => _setStatus(hint, AppHintStatus.completed);

  Future<void> resetAll() async {
    final changed = _statuses.isNotEmpty || _hintHandledThisSession;
    if (!changed) return;

    _statuses.clear();
    _hintHandledThisSession = false;
    await _removePersistedStatuses();
    _cacheActiveHints();
    notifyListeners();
  }

  AppHint? _garageGesturesHint() {
    final eligible =
        _appRepository.bikes.length >= 2 &&
        _appRepository.components.isNotEmpty &&
        statusOf(AppHint.garageGesturesV1) == AppHintStatus.unseen;
    return eligible ? AppHint.garageGesturesV1 : null;
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

  Future<void> _removePersistedStatuses() async {
    final preferences = await SharedPreferences.getInstance();
    for (final hint in AppHint.values) {
      await preferences.remove(_keyFor(hint));
    }
  }
}
