import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  StravaServiceStatus get status => _status;
  String get errorMessage => _errorMessage;
  String? _userId;
  String? get userId => _userId;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitiesSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _athleteSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _gearSubscription;
  bool _isDisposed = false;
  
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
    _gearSubscription?.cancel();
    _activitiesSubscription = null;
    _userDocSubscription = null;
    _athleteSubscription = null;
    _gearSubscription = null;
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> update({required AppRepository appRepository}) async {
    _appRepository = appRepository;

    if (_isInitialized || _isDisconnecting) return;
    _isInitialized = true;

    try {
      await _loadUserId();
      _listenToUserDocument();
      _registerFcmToken();
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

      final bool wasConnected = _isConnected;
      _isConnected = data['strava_connected'] ?? false;

      // Update Sync Status
      final String remoteStatus = data['strava_sync_status'] ?? 'idle';
      final String remoteError = data['strava_sync_error'] ?? '';

      if (remoteStatus == 'syncing') {
        _status = StravaServiceStatus.syncing;
        _errorMessage = ''; 
      } else if (remoteStatus == 'error') {
        _status = StravaServiceStatus.idle;
        _errorMessage = remoteError.isNotEmpty ? remoteError : 'Sync failed';
      } else {
        _status = StravaServiceStatus.idle;
      }
      
      _lastRecentSync = _parseDateTime(data['strava_sync_last_recent']);
      _lastFullSync = _parseDateTime(data['strava_sync_last_full']);
      _syncDay = data['sync_day'] as int?;

      notifyListeners();

      // Reactive Lifecycle: Start/Stop data listeners based on connection state
      if (_isConnected && (_activitiesSubscription == null)) {
        unawaited(_startDataListeners());
      } else if (!_isConnected && wasConnected) {
        unawaited(_stopDataListeners());
      }
    }, onError: (e) => _handleError("UserDoc", e, userMessage: "Connection verify failed"));
  }

  Future<void> _startDataListeners() async {
    _listenToActivities();
    _listenToAthlete();
    _listenToGear();
  }

  Future<void> _stopDataListeners() async {
    _activitiesSubscription?.cancel();
    _athleteSubscription?.cancel();
    _gearSubscription?.cancel();
    _activitiesSubscription = null;
    _athleteSubscription = null;
    _gearSubscription = null;
  }

  void _listenToActivities() {
    if (_userId == null) return;

    unawaited(_activitiesSubscription?.cancel());
    _activitiesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('activity_batches')
        .snapshots()
        .listen((snapshot) {
      if (!_isConnected) return;

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

        // For added or modified batches: process tombstones and valid activities
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

  Future<void> _listenToAthlete() async {
    if (_userId == null) return;

    await _athleteSubscription?.cancel();
    _athleteSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('athletes')
        .doc('athlete')
        .snapshots()
        .listen((snapshot) async {
      if (!_isConnected) return;
      if (snapshot.exists && snapshot.data() != null) {
        final athlete = StravaAthlete.fromFirestore(snapshot.data()!);
        await _appRepository.setStravaAthletes([athlete]);
      } else {
        _appRepository.setStravaAthletes([]);
      }
    }, onError: (e) => _handleError("AthleteSync", e));
  }

  Future<void> _listenToGear() async {
    if (_userId == null) return;

    await _gearSubscription?.cancel();
    _gearSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('gears')
        .snapshots()
        .listen((snapshot) async {
      if (!_isConnected) return;
      final gears = snapshot.docs.map((doc) => StravaGear.fromFirestore(doc.data())).toList();
      await _appRepository.setStravaGears(gears);
    }, onError: (e) => _handleError("GearSync", e));
  }

  Future<void> _registerFcmToken() async {
    if (_userId == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        if (token != null) {
          final Map<String, dynamic> data = {'fcm_token': token};
          
          // TTL: Cleanup anonymous users who never link Strava.
          // If not connected, set expiration to 1 year (365 days) from now.
          if (!_isConnected) {
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
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    _userId = userCredential.user?.uid;
    notifyListeners();
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

  /// Manual sync can be triggered if it's been more than 7 days
  /// since the last manual sync, or if it has never been synced.
  bool get canSyncRecent {
    if (!_isConnected) return false;
    if (_status == StravaServiceStatus.syncing) return false;
    if (_lastRecentSync == null) return true;
    final difference = DateTime.now().difference(_lastRecentSync!);
    return difference.inDays >= 7;
  }

  /// Returns the date when the next manual sync becomes available.
  /// Returns null if manual sync is already available.
  DateTime? get manualSyncAvailableAt {
    if (canSyncRecent || _lastRecentSync == null) return null;
    return _lastRecentSync!.add(const Duration(days: 7));
  }

  static void openActivityOnStrava(int activityId) async {
    final url = Uri.parse("https://www.strava.com/activities/$activityId");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Checks if there are open spots for the Strava integration.
  Future<bool> checkAvailability() async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      final result = await functions.httpsCallable('checkStravaAvailability').call();
      
      final data = result.data as Map<String, dynamic>;
      return data['available'] == true;
    } catch (e) {
      _handleError("checkAvailability", e);
      // Fail safe: If the check fails (e.g. no internet), we probably want to return false 
      // or true depending on preference. Usually better to return false so they don't buy and fail later.
      return false;
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
    if (_userId == null) return;
    _isDisconnecting = true;
    status = StravaServiceStatus.syncing;
    errorMessage = "Disconnecting...";
    
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      await functions.httpsCallable('deauthorizeUser').call();
      _stopListening();
      await _appRepository.clearStravaData();

      _isConnected = false;
      errorMessage = "";
      status = StravaServiceStatus.idle;
      _isInitialized = false; 
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
