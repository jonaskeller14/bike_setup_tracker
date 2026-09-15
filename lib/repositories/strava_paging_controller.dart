import 'dart:async';

import 'package:drift/drift.dart' as drift;

import '../database/app_database.dart';
import '../database/mappers.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_scope.dart';

/// Owns the paged, gear-filtered window of Strava activities.
///
/// Strava is paginated per active scope (see [StravaDao.getActivitiesPaginated]),
/// so the loaded window *is* the filtered set. The owning repository supplies the
/// current scope via [scope] and is told about changes through [onLoadingChanged]
/// (spinner only) and [onWindowChanged] (window contents).
class StravaPagingController {
  final AppDatabase database;

  /// Reads the caller's current bike selection. Called on every load rather
  /// than cached, so a selection change is always picked up.
  final StravaScope Function() scope;

  /// Fired for in-flight state (the loading spinner) with no window change.
  final void Function() onLoadingChanged;

  /// Fired once the loaded window itself changed.
  final void Function() onWindowChanged;

  StravaPagingController({
    required this.database,
    required this.scope,
    required this.onLoadingChanged,
    required this.onWindowChanged,
  }) {
    // Seed the baseline so the first (no-bike) stream emissions don't spuriously
    // re-trigger an initial load before/alongside the repository's initialize().
    _lastSignature = _currentSignature();
  }

  Map<int, StravaActivity> _activities = {};
  int _offset = 0;
  int _limit = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _sortAscending = false;
  bool _isDisposed = false;

  /// Identifies the scope the current loaded window was paged for. When this
  /// changes we re-page from the top so the bike's activities never get dropped
  /// behind a global pagination boundary.
  String? _lastSignature;

  Map<int, StravaActivity> get activities => _activities;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get sortAscending => _sortAscending;

  void dispose() => _isDisposed = true;

  set limit(int newLimit) => _limit = newLimit; // Debug helper

  String _currentSignature() => '${_sortAscending ? 'asc' : 'desc'}|${scope().signature}';

  drift.OrderingMode get _mode => _sortAscending ? drift.OrderingMode.asc : drift.OrderingMode.desc;

  Future<List<StravaActivity>> _page({required int limit, required int offset}) async {
    final list = await database.stravaDao.getActivitiesPaginated(
      limit: limit,
      offset: offset,
      mode: _mode,
      scope: scope(),
    );
    return list.map((a) => a.toModel()).toList();
  }

  void reloadIfScopeChanged() {
    if (_currentSignature() == _lastSignature) return;
    unawaited(initialLoad());
  }

  Future<void> initialLoad() async {
    final sig = _currentSignature();
    _lastSignature = sig;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = true;
    onLoadingChanged();

    final list = await _page(limit: _limit, offset: 0);
    if (_isDisposed) return;
    // A newer filter took over while we were querying; drop these stale results.
    if (sig != _lastSignature) return;
    _activities = {for (var a in list) a.id: a};
    _offset = list.length;
    if (list.length < _limit) _hasMore = false;
    _isLoadingMore = false;
    onWindowChanged();
  }

  /// Re-derives the in-memory window from the database (the single source of
  /// truth) after an out-of-band write such as a webhook sync, without
  /// collapsing the user's scroll position. Unlike [initialLoad] this re-pages
  /// the whole currently-loaded window (page 1 .. current offset), so activities
  /// the user already scrolled in are kept and any new/changed/deleted rows are
  /// reflected. It runs silently (no loading spinner).
  Future<void> reloadWindow() async {
    final sig = _currentSignature();
    _lastSignature = sig;
    // Reload at least the first page; if the user paged further, reload the
    // whole loaded window so scrolled-in activities aren't dropped.
    final reloadLimit = _offset > _limit ? _offset : _limit;

    final list = await _page(limit: reloadLimit, offset: 0);
    if (_isDisposed) return;
    // A newer filter took over while we were querying; drop these stale results.
    if (sig != _lastSignature) return;
    _activities = {for (var a in list) a.id: a};
    _offset = list.length;
    // Only ever narrows: a short page means the window shrank (deletions);
    // a full page leaves [_hasMore] as-is so paging keeps working.
    if (list.length < reloadLimit) _hasMore = false;
    onWindowChanged();
  }

  Future<void> setSortOrder(bool ascending) async {
    if (_sortAscending == ascending) return;
    _sortAscending = ascending;
    // initialLoad resets the offset and re-pages for the new ordering.
    await initialLoad();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    onLoadingChanged();

    final sig = _lastSignature;
    final list = await _page(limit: _limit, offset: _offset);
    if (_isDisposed) return;
    // The filter changed mid-load; these belong to a stale window.
    if (sig != _lastSignature) return;
    _activities.addAll({for (var a in list) a.id: a});
    _offset += list.length;
    if (list.length < _limit) _hasMore = false;
    _isLoadingMore = false;
    onWindowChanged();
  }

  /// Drops the loaded window after the underlying tables were wiped.
  void clear() {
    _activities = {};
    _offset = 0;
    _hasMore = true;
  }

  Stream<List<StravaActivity>> get activitiesWithPosition =>
      database.stravaDao.watchActivitiesWithPosition().map((list) => list.map((a) => a.toModel()).toList());

  Future<List<StravaActivity>> get latest async {
    final list = await database.stravaDao.getActivitiesPaginated(limit: 3, offset: 0, mode: drift.OrderingMode.desc);
    return list.map((a) => a.toModel()).toList();
  }

  Future<List<StravaActivity>> filteredActivitiesWithPosition() async {
    final list = await activitiesWithPosition.first;
    return list.where(scope().matches).toList();
  }

  Future<List<StravaActivity>> search(String query) async {
    final results = await database.stravaDao.searchActivitiesByName(query);
    return results.map((a) => a.toModel()).where(scope().matches).toList();
  }

  Future<StravaActivity?> getActivity(int id) async {
    final loaded = _activities[id];
    if (loaded != null) return loaded;
    final dbActivity = await database.stravaDao.getActivityById(id);
    return dbActivity?.toModel();
  }
}
