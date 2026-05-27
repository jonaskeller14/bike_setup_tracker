import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_settings.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../repositories/app_repository.dart';

sealed class StravaState {
  const StravaState();
}

class StravaIdle extends StravaState {
  const StravaIdle();
}

class StravaSyncing extends StravaState {
  const StravaSyncing();
}

class StravaDisconnecting extends StravaState {
  const StravaDisconnecting();
}

class StravaFailed extends StravaState {
  final String message;
  const StravaFailed(this.message);
}

enum StravaAvailability { available, full, networkError }

class StravaService extends ChangeNotifier {
  static const String _stravaClientId = "193047";
  static const String _redirectUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/exchangeToken";
  static const String _scope = "read,profile:read_all,activity:read_all";

  StravaState _state = const StravaIdle();
  bool _isInitialized = false;

  StravaState get state => _state;
  bool get isBusy => switch (_state) {
        StravaIdle() || StravaFailed() => false,
        _ => true,
      };

  bool get isDisconnecting => _state is StravaDisconnecting;

  String? get errorMessage {
    final s = _state;
    return s is StravaFailed ? s.message : null;
  }

  void clearError() {
    if (_state is StravaFailed) _setState(const StravaIdle());
  }

  void _setState(StravaState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Cached result of [checkAvailability] — null until the first check
  /// completes. Refreshed lazily when stale. Network failures are not cached so
  /// the next sheet open re-probes immediately.
  StravaAvailability? _availability;
  DateTime? _availabilityCheckedAt;
  static const Duration _availabilityCacheTtl = kDebugMode ? Duration.zero : Duration(minutes: 5);
  static const Duration _manualSyncCooldown = kDebugMode ? Duration.zero : Duration(hours: 1);
  Future<void>? _inFlightAvailabilityCheck;

  StravaAvailability? get availability => _availability;

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
  AppSettings _appSettings;

  StravaService(this._appRepository, this._appSettings);

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
    _appSettings = appSettings;

    if (_isInitialized || isDisconnecting) return;
    _isInitialized = true;

    try {
      await _loadUserId();
      _listenToUserDocument();
      _registerFcmToken();
      await _syncSettingsToFirestore();
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

  void _handleError(String context, dynamic error, {String? userMessage}) {
    if (error is FirebaseFunctionsException) {
      debugPrint("StravaService $context: [${error.code}] ${error.message}");
    } else {
      debugPrint("StravaService $context: $error");
    }
    if (userMessage != null) _setState(StravaFailed(userMessage));
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

      // Athlete just became linked — OAuth round-trip succeeded. Clear any
      // lingering [StravaFailed] from a previous attempt so the dashboard
      // doesn't show a stale error tile. ([StravaSyncing] and
      // [StravaDisconnecting] can't co-exist with `previousAthleteId == null`.)
      if (previousAthleteId == null && _activeAthleteId != null && _state is StravaFailed) {
        _setState(const StravaIdle());
      } else {
        notifyListeners();
      }

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

        _lastRecentSync = _parseDateTime(data['strava_sync_last_recent']);
        _lastFullSync = _parseDateTime(data['strava_sync_last_full']);
        _syncDay = data['sync_day'] as int?;

        // Mirror the server-driven sync state when we're not in the middle of an auth or disconnect
        final inSyncDomain = _state is StravaIdle || _state is StravaSyncing || _state is StravaFailed;
        final String remoteStatus = data['strava_sync_status'] ?? 'idle';
        final String remoteError = data['strava_sync_error'] ?? '';

        if (inSyncDomain) {
          if (remoteStatus == 'syncing') {
            _setState(const StravaSyncing());
          } else if (remoteStatus == 'error') {
            _setState(StravaFailed(
              remoteError.isNotEmpty ? remoteError : 'Sync failed',
            ));
          } else if (_state is! StravaIdle) {
            _setState(const StravaIdle());
          } else {
            notifyListeners();
          }
        } else {
          notifyListeners();
        }
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
    }, onError: (e) => _handleError("SyncStream", e, userMessage: "Background sync error"));
  }


  static const Duration _renewalGracePeriod = Duration(hours: 4);

  /// Called whenever the user doc updates while the athlete is still linked.
  /// If the subscription has lapsed, stops data listeners and wipes local
  /// Strava data. Keeps [linked_athletes] in Firestore and Bike/Person Strava
  /// links in SQLite so reconnecting after resubscribing needs no manual setup.
  void _checkEntitlementExpiry(Map<String, dynamic> data) {
    final entitlementData =
        data['entitlement']?['strava'] as Map<String, dynamic>?;

    DateTime? expiresAt;
    bool autoRenewing = false;
    if (entitlementData != null) {
      final raw = entitlementData['expiresAt'];
      if (raw is Timestamp) expiresAt = raw.toDate();
      autoRenewing = entitlementData['autoRenewing'] as bool? ?? false;
    }

    // Mirror StravaEntitlement.isActive: grant a grace period when autoRenewing
    // so that the renewal webhook delivery window (~30 s) does not trigger a
    // premature data clear. Non-renewing subscriptions expire on the dot.
    final buffer = autoRenewing ? _renewalGracePeriod : Duration.zero;
    final isEntitled = expiresAt != null &&
        DateTime.now().isBefore(expiresAt.add(buffer));

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

  Future<void> _syncSettingsToFirestore() async {
    await setStravaNotificationsEnabled(_appSettings.enableStravaNotifications);
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
    if (isBusy) return false;
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
  /// cache. Concurrent callers share a single in-flight request. Returns
  /// [StravaAvailability.networkError] when the check itself failed so the UI
  /// can distinguish "offline" from "actually full".
  Future<StravaAvailability> checkAvailability({bool force = false}) async {
    final cachedAt = _availabilityCheckedAt;
    final cached = _availability;
    final fresh = cachedAt != null &&
        DateTime.now().difference(cachedAt) < _availabilityCacheTtl;
    if (!force && cached != null && fresh) return cached;

    final existing = _inFlightAvailabilityCheck;
    if (existing != null) {
      await existing;
      return _availability ?? StravaAvailability.networkError;
    }

    final completer = _refreshAvailability();
    _inFlightAvailabilityCheck = completer;
    try {
      await completer;
    } finally {
      _inFlightAvailabilityCheck = null;
    }
    return _availability ?? StravaAvailability.networkError;
  }

  Future<void> _refreshAvailability() async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      final result = await functions.httpsCallable('checkStravaAvailability').call();
      final data = result.data as Map<String, dynamic>;
      _availability = data['available'] == true
          ? StravaAvailability.available
          : StravaAvailability.full;
      _availabilityCheckedAt = DateTime.now();
    } on FirebaseFunctionsException catch (e) {
      _handleError("checkAvailability", e);
      // Network-class failures: don't cache so the next sheet open re-probes
      // immediately. Anything else (e.g. server bug) is treated as full to
      // prevent users from buying when something is genuinely wrong upstream.
      if (e.code == 'deadline-exceeded' ||
          e.code == 'unavailable' ||
          e.code == 'unknown') {
        _availability = StravaAvailability.networkError;
        _availabilityCheckedAt = null;
      } else {
        _availability = StravaAvailability.full;
        _availabilityCheckedAt = DateTime.now();
      }
    } catch (e) {
      _handleError("checkAvailability", e);
      _availability = StravaAvailability.networkError;
      _availabilityCheckedAt = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> launchStravaLogin() async {
    try {
      if (_userId == null) await _loadUserId();
      if (_userId == null) {
        _setState(const StravaFailed(
          "Couldn't reach our servers. Check your connection and try again.",
        ));
        return;
      }

      final Uri authUrl = Uri.parse(
        "https://www.strava.com/oauth/mobile/authorize"
        "?client_id=$_stravaClientId"
        "&redirect_uri=$_redirectUri"
        "&response_type=code"
        "&approval_prompt=auto"
        "&scope=$_scope"
        "&state=$_userId"
      );

      if (!await canLaunchUrl(authUrl)) {
        _handleError(
          "StravaAuth",
          Exception("Failed to launch authUrl: $authUrl"),
          userMessage: "Could not find a program to launch the link."
        );
        return;
      }
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      // We don't enter any "in-flight" state after handing off to the browser.
      // The Firestore listener ([_listenToUserDocument]) carries the
      // authoritative resolution; a deep-link `success=false` surfaces failure
      // via [handleStravaAuthCallback]. If the user cancels in the browser
      // they can just retap the button.
    } catch (e) {
      _setState(StravaFailed("Login failed: $e"));
    }
  }

  /// Called by the deep-link handler when the Cloud Function redirects back
  /// to the app. On success we keep the spinner running and let the Firestore
  /// listener flip [isConnected] — it carries the authoritative state. On
  /// failure we surface the error inline on the sheet.
  void handleStravaAuthCallback({required bool success, String? error}) {
    if (success) return;
    _setState(StravaFailed(
      error != null && error.isNotEmpty
          ? "Strava sign-in failed: $error"
          : "Strava sign-in failed. Please try again.",
    ));
  }

  Future<void> disconnect() async {
    final uid = _userId;
    final athleteId = _activeAthleteId;
    if (uid == null) return;
    _setState(const StravaDisconnecting());

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
      _appSettings.showStravaLinkGearHint = true;

      _setState(const StravaIdle());
    } catch (e) {
      _setState(StravaFailed("Disconnection failed: $e"));
    }
  }

  Future<void> triggerManualSync() async {
    if (_userId == null) return;
    _setState(const StravaSyncing());
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      await functions
          .httpsCallable('syncActivities',
              options: HttpsCallableOptions(timeout: const Duration(seconds: 15)))
          .call();
    } on FirebaseFunctionsException catch (e) {
      _setState(StravaFailed(
        _friendlyFunctionError(e) ?? "Sync failed: [${e.code}] ${e.message}",
      ));
    } catch (e) {
      _setState(StravaFailed("Sync failed: $e"));
    }
  }

  Future<void> triggerFullHistorySync() async {
    if (_userId == null) return;
    _setState(const StravaSyncing());
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      await functions.httpsCallable('syncFullHistory').call();
    } on FirebaseFunctionsException catch (e) {
      _setState(StravaFailed(
        _friendlyFunctionError(e) ?? "Full history sync failed: [${e.code}] ${e.message}",
      ));
    } catch (e) {
      _setState(StravaFailed("Full history sync failed: $e"));
    }
  }

  String? _friendlyFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'deadline-exceeded':
      case 'unavailable':
      // On Android, a compound App Check + network failure surfaces as 'unknown'.
      case 'unknown':
        return "No internet connection. Please check your connection and try again.";
      case 'unauthenticated':
        return "Authentication error. Please try again or reconnect to Strava.";
      case 'resource-exhausted':
        return "Too many requests. Please try again later.";
      default:
        return null;
    }
  }
}
