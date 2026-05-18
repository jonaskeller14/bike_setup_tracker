import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_settings.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../repositories/app_repository.dart';

enum StravaServiceStatus {
  idle,
  syncing,
}

class StravaService extends ChangeNotifier {
  static const String _stravaClientId = "193047";
  static const String _redirectUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/exchangeToken";
  static const String _scope = "read,profile:read_all,activity:read_all";

  StravaServiceStatus _status = StravaServiceStatus.idle;
  String _errorMessage = '';
  bool _isInitialized = false;
  bool _isDisconnecting = false;

  /// Cached result of [checkAvailability] — null until the first check
  /// completes. Refreshed lazily when stale.
  bool? _isStravaAvailable;
  DateTime? _availabilityCheckedAt;
  static const Duration _availabilityCacheTtl = Duration(minutes: 5);
  static const Duration _manualSyncCooldown = Duration(days: 1);
  Future<void>? _inFlightAvailabilityCheck;

  bool? get isStravaAvailable => _isStravaAvailable;

  StravaServiceStatus get status => _status;
  String get errorMessage => _errorMessage;
  String? _userId;
  String? get userId => _userId;

  /// Strava athlete IDs linked to this device. Populated by the OAuth
  /// exchange Cloud Function via `users/{uid}.linked_athletes`. For now we
  /// only ever look at the first entry; the array shape leaves room for a
  /// future trainer view that watches multiple athletes.
  List<String> _linkedAthletes = const [];
  List<String> get linkedAthletes => _linkedAthletes;

  /// Athlete ID currently being tracked by the data listeners — first entry
  /// of [_linkedAthletes] (or null when no Strava is linked).
  String? _activeAthleteId;
  String? get activeAthleteId => _activeAthleteId;

  bool get isConnected => _activeAthleteId != null;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitiesSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _athleteSubscription;
  bool _isDisposed = false;
  bool _wasEntitled = false;
  
  DateTime? _lastRecentSync;
  DateTime? _lastFullSync;
  int? _syncDay;
  
  AppRepository _appRepository;

  StravaService(this._appRepository);

  @override
  void dispose() async {
    _isDisposed = true;
    await _stopListening();
    super.dispose();
  }

  Future<void> _stopListening() async {
    _activitiesSubscription?.cancel();
    _userDocSubscription?.cancel();
    _athleteSubscription?.cancel();
    _activitiesSubscription = null;
    _userDocSubscription = null;
    _athleteSubscription = null;
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> update({required AppRepository appRepository, required AppSettings appSettings}) async {
    _appRepository = appRepository;

    if (_isInitialized || _isDisconnecting) return;
    _isInitialized = true;

    try {
      await _loadUserId();
      _listenToUserDocument();
      _registerFcmToken();
      await _syncSettingsToFirestore(appSettings);
      unawaited(checkAvailability());
    } catch (e) {
      _isInitialized = false;
    }
  }

  /// Helper to process sync dates from Firestore (handles both Timestamps and Strings)
  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Centralized error handling
  void _handleError(String context, dynamic error, {String? userMessage}) {
    debugPrint("StravaService $context: $error");
    if (userMessage != null) {
      errorMessage = userMessage;
    }
  }

  Future<void> _listenToUserDocument() async {
    if (_userId == null) return;

    await _userDocSubscription?.cancel();
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      final previousAthleteId = _activeAthleteId;
      final rawLinked = data['linked_athletes'];
      _linkedAthletes = rawLinked is List
          ? rawLinked.map((e) => e.toString()).toList()
          : const [];
      _activeAthleteId = _linkedAthletes.firstOrNull;

      notifyListeners();

      // Reactive lifecycle: when the active athlete changes (link, unlink, or
      // switch to a different athlete), rebind the athlete-scoped listeners.
      if (_activeAthleteId != previousAthleteId) {
        unawaited(_stopDataListeners());
        if (_activeAthleteId != null) {
          unawaited(_startDataListeners());
        } else {
          unawaited(_appRepository.clearStravaData());
        }
      } else if (_activeAthleteId != null) {
        // Athlete unchanged but doc updated — check if subscription lapsed.
        _checkEntitlementExpiry(data);
      }
    }, onError: (e) => _handleError("UserDoc", e, userMessage: "Connection verify failed"));
  }

  Future<void> _startDataListeners() async {
    _listenToAthleteDocument();
    _listenToActivities();
  }

  Future<void> _stopDataListeners() async {
    await _activitiesSubscription?.cancel();
    await _athleteSubscription?.cancel();
    _activitiesSubscription = null;
    _athleteSubscription = null;
  }

  /// Listens to the athlete root doc — combines profile fields with the
  /// shared sync state (status, last syncs, sync_day). All devices linked to
  /// the same athlete see the same sync state, which is the desired behavior.
  Future<void> _listenToAthleteDocument() async {
    final athleteId = _activeAthleteId;
    if (athleteId == null) return;

    await _athleteSubscription?.cancel();
    _athleteSubscription = FirebaseFirestore.instance
        .collection('athletes')
        .doc(athleteId)
        .snapshots()
        .listen((snapshot) async {
      if (_activeAthleteId != athleteId) return; // listener stale
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        // Profile
        final athlete = StravaAthlete.fromFirestore(data);
        await _appRepository.setStravaAthletes([athlete]);

        // Gears are embedded as an array on the athlete doc — no separate listener needed.
        final rawGears = data['gears'];
        if (rawGears is List) {
          try {
            final gears = rawGears
                .whereType<Map<String, dynamic>>()
                .map((g) => StravaGear.fromFirestore(g))
                .toList();
            unawaited(_appRepository.setStravaGears(gears));
          } catch (e) {
            _handleError("GearSync", e);
          }
        } else {
          unawaited(_appRepository.setStravaGears([]));
        }

        // Sync state (formerly on the user doc)
        final String remoteStatus = data['strava_sync_status'] ?? 'idle';
        final String remoteError = data['strava_sync_error'] ?? '';
        if (remoteStatus == 'syncing') {
          _status = StravaServiceStatus.syncing;
          _errorMessage = '';
        } else if (remoteStatus == 'error') {
          _status = StravaServiceStatus.idle;
          _errorMessage =
              remoteError.isNotEmpty ? remoteError : 'Sync failed';
        } else {
          _status = StravaServiceStatus.idle;
        }
        _lastRecentSync = _parseDateTime(data['strava_sync_last_recent']);
        _lastFullSync = _parseDateTime(data['strava_sync_last_full']);
        _syncDay = data['sync_day'] as int?;
        notifyListeners();
      } else {
        await _appRepository.setStravaAthletes([]);
      }
    }, onError: (e) => _handleError("AthleteSync", e));
  }

  void _listenToActivities() {
    final athleteId = _activeAthleteId;
    if (athleteId == null) return;

    unawaited(_activitiesSubscription?.cancel());
    _activitiesSubscription = FirebaseFirestore.instance
        .collection('athletes')
        .doc(athleteId)
        .collection('activity_batches')
        .snapshots()
        .listen((snapshot) {
      if (_activeAthleteId != athleteId) return;

      final List<StravaActivity> toUpsert = [];
      final List<int> toDelete = [];

      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null || !data.containsKey('activities')) continue;

        final Map<String, dynamic> activitiesMap = data['activities'];

        if (change.type == DocumentChangeType.removed) {
          // If a whole batch is deleted, add all its activities to the deletion list.
          for (var entry in activitiesMap.entries) {
            toDelete.add(int.parse(entry.key));
          }
          continue;
        }

        for (var entry in activitiesMap.entries) {
          final activityData = entry.value as Map<String, dynamic>;
          if (activityData['isDeleted'] == true) {
            toDelete.add(int.parse(entry.key));
          } else {
            toUpsert.add(StravaActivity.fromFirestore(activityData));
          }
        }
      }

      if (toUpsert.isNotEmpty || toDelete.isNotEmpty) {
        unawaited(_appRepository.setStravaActivities(
          toUpsert,
          toDelete: toDelete,
        ));
      }
    }, onError: (e) =>
            _handleError("SyncStream", e, userMessage: "Background sync error"));
  }


  /// Called whenever the user doc updates while the athlete is still linked.
  /// If the subscription has lapsed, stops data listeners and wipes local
  /// Strava data. Keeps [linked_athletes] in Firestore and Bike/Person Strava
  /// links in SQLite so reconnecting after resubscribing needs no manual setup.
  void _checkEntitlementExpiry(Map<String, dynamic> data) {
    final entitlementData =
        data['entitlement']?['strava'] as Map<String, dynamic>?;

    DateTime? expiresAt;
    if (entitlementData != null) {
      final raw = entitlementData['expiresAt'];
      if (raw is Timestamp) expiresAt = raw.toDate();
    }

    final isEntitled = expiresAt != null && DateTime.now().isBefore(expiresAt);

    if (_wasEntitled && !isEntitled) {
      // Only clear local data when entitlement transitions from active → inactive.
      // Treating absence of entitlement as a lapse would incorrectly wipe data on
      // fresh installs or re-auth flows before verifySubscription has written.
      debugPrint('StravaService: subscription lapsed — clearing local Strava data');
      unawaited(_stopDataListeners());
      unawaited(_appRepository.clearStravaData());
    } else if (!_wasEntitled && isEntitled) {
      // Subscription restored while athlete is still linked — restart listeners
      // so data flows again without requiring a full disconnect + re-auth.
      debugPrint('StravaService: subscription restored — restarting data listeners');
      unawaited(_startDataListeners());
    }
    _wasEntitled = isEntitled;
  }

  Future<void> _registerFcmToken() async {
    if (_userId == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final NotificationSettings settings = await messaging.requestPermission();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final String? token = await messaging.getToken();
        if (token != null) {
          final Map<String, dynamic> data = {'fcm_token': token};
          
          // TTL: cleanup anonymous user docs that never link Strava. Once a
          // user links any athlete, this device "counts" — drop the TTL so
          // the doc survives indefinitely.
          if (!isConnected) {
            data['expiresAt'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
          }

          await FirebaseFirestore.instance.collection('users').doc(_userId).set(data, SetOptions(merge: true));
        }
      }
    } catch (e) {
      _handleError("FcmToken", e);
    }
  }

  Future<void> _loadUserId() async {
    // Wait for the first auth-state event so Firebase Auth has time to
    // restore a previously-persisted anonymous user from disk. Calling
    // signInAnonymously() before that restoration completes creates a
    // second anonymous user, whose UID would mismatch the token used in
    // subsequent Firestore requests → PERMISSION_DENIED.
    User? user = await FirebaseAuth.instance.authStateChanges().first;
    user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
    _userId = user?.uid;
    notifyListeners();
  }

  Future<void> _syncSettingsToFirestore(AppSettings settings) async {
    await setStravaNotificationsEnabled(settings.enableStravaNotifications);
  }

  Future<void> setStravaNotificationsEnabled(bool enabled) async {
    if (_userId == null || _activeAthleteId == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).set({
        'enable_strava_notifications': enabled,
      }, SetOptions(merge: true));
    } catch (e) {
      _handleError("SyncSettingsUp", e);
    }
  }

  set errorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  set status(StravaServiceStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  DateTime? get lastRecentSync => _lastRecentSync;
  DateTime? get lastFullSync => _lastFullSync;
  int? get syncDay => _syncDay;

  /// Computes the next scheduled full sync date based on sync_day.
  /// Returns null if sync_day is not set or no full sync has happened yet.
  DateTime? get nextFullSync {
    if (_syncDay == null) return null;
    final now = DateTime.now();
    // Find the next occurrence of sync_day
    // sync_day: 0=Sun, 1=Mon, ..., 6=Sat (JS convention, same as DateTime.sunday=7 in Dart)
    // Dart: 1=Mon, 2=Tue, ..., 7=Sun
    final dartWeekday = _syncDay == 0 ? DateTime.sunday : _syncDay!;
    int daysUntil = dartWeekday - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return DateTime(now.year, now.month, now.day + daysUntil);
  }

  /// Manual sync can be triggered if the cooldown has elapsed
  /// since the last manual sync, or if it has never been synced.
  bool get canSyncRecent {
    if (!isConnected) return false;
    if (_status == StravaServiceStatus.syncing) return false;
    if (_lastRecentSync == null) return true;
    final difference = DateTime.now().difference(_lastRecentSync!);
    return difference >= _manualSyncCooldown;
  }

  /// Returns the date when the next manual sync becomes available.
  /// Returns null if manual sync is already available.
  DateTime? get manualSyncAvailableAt {
    if (canSyncRecent || _lastRecentSync == null) return null;
    return _lastRecentSync!.add(_manualSyncCooldown);
  }

  static void openActivityOnStrava(int activityId) async {
    final url = Uri.parse("https://www.strava.com/activities/$activityId");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Checks if there are open spots for the Strava integration. The result is
  /// cached for [_availabilityCacheTtl]; pass `force: true` to bypass the
  /// cache. Concurrent callers share a single in-flight request.
  Future<bool> checkAvailability({bool force = false}) async {
    final cachedAt = _availabilityCheckedAt;
    final cached = _isStravaAvailable;
    final fresh = cachedAt != null &&
        DateTime.now().difference(cachedAt) < _availabilityCacheTtl;
    if (!force && cached != null && fresh) return cached;

    final existing = _inFlightAvailabilityCheck;
    if (existing != null) {
      await existing;
      return _isStravaAvailable ?? false;
    }

    final completer = _refreshAvailability();
    _inFlightAvailabilityCheck = completer;
    try {
      await completer;
    } finally {
      _inFlightAvailabilityCheck = null;
    }
    return _isStravaAvailable ?? false;
  }

  Future<void> _refreshAvailability() async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      final result = await functions.httpsCallable('checkStravaAvailability').call();
      final data = result.data as Map<String, dynamic>;
      _isStravaAvailable = data['available'] == true;
    } catch (e) {
      _handleError("checkAvailability", e);
      // Fail safe: closed if the check failed (e.g. no internet) — don't let
      // users buy and then fail to connect.
      _isStravaAvailable = false;
    } finally {
      _availabilityCheckedAt = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> launchStravaLogin() async {
    try {
      if (_userId == null) await _loadUserId();
      status = StravaServiceStatus.syncing;

      final Uri authUrl = Uri.parse(
        "https://www.strava.com/oauth/mobile/authorize"
        "?client_id=$_stravaClientId"
        "&redirect_uri=$_redirectUri"
        "&response_type=code"
        "&approval_prompt=auto"
        "&scope=$_scope"
        "&state=$_userId"
      );

      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open Strava-Login';
      }

      status = StravaServiceStatus.idle;
      errorMessage = "";
    } catch (e) {
      status = StravaServiceStatus.idle;
      errorMessage = "Login failed: $e";
    }
  }

  Future<void> disconnect() async {
    final uid = _userId;
    final athleteId = _activeAthleteId;
    if (uid == null) return;
    _isDisconnecting = true;
    status = StravaServiceStatus.syncing;
    errorMessage = "Disconnecting...";

    try {
      if (athleteId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'linked_athletes': FieldValue.arrayRemove([athleteId]),
        });
      }

      await _stopDataListeners();
      await _appRepository.clearStravaData();

      errorMessage = "";
      status = StravaServiceStatus.idle;
      notifyListeners();
    } catch (e) {
      errorMessage = "Disconnection failed: $e";
      status = StravaServiceStatus.idle;
    } finally {
      _isDisconnecting = false;
    }
  }

  Future<void> triggerManualSync() async {
    if (_userId == null) return;
    status = StravaServiceStatus.syncing;
    errorMessage = "";
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      await functions.httpsCallable('syncActivities').call();
      status = StravaServiceStatus.idle;
    } catch (e) {
      errorMessage = "Sync failed: $e";
      status = StravaServiceStatus.idle;
    }
  }

  Future<void> triggerFullHistorySync() async {
    if (_userId == null) return;
    status = StravaServiceStatus.syncing;
    errorMessage = "";
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      await functions.httpsCallable('syncFullHistory').call();
      status = StravaServiceStatus.idle;
    } catch (e) {
      errorMessage = "Full history sync fail: $e";
      status = StravaServiceStatus.idle;
    }
  }
}
