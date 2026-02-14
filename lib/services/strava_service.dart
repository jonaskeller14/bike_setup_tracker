import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../models/app_data.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';

enum StravaServiceStatus {
  idle,
  syncing,
}

class StravaService extends ChangeNotifier {
  static const String _stravaClientId = "193047";
  static const String _redirectUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/exchangeToken";
  static const String _deauthorizeUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/deauthorizeUser";
  static const String _syncUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/syncActivities";
  static const String _syncFullHistoryUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/syncFullHistory";
  static const String _scope = "read,profile:read_all,activity:read_all";

  StravaServiceStatus _status = StravaServiceStatus.idle;
  String _errorMessage = '';
  bool _isInitialized = false;

  StravaServiceStatus get status => _status;
  String get errorMessage => _errorMessage;
  String? _userId;
  String? get userId => _userId;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  StreamSubscription? _activitiesSubscription;
  StreamSubscription? _userDocSubscription;
  StreamSubscription? _athleteSubscription;
  StreamSubscription? _gearSubscription;
  bool _isDisposed = false;
  
  AppData _appData;

  StravaService(this._appData);

  @override
  void dispose() {
    _isDisposed = true;
    _activitiesSubscription?.cancel();
    _userDocSubscription?.cancel();
    _athleteSubscription?.cancel();
    _gearSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> update({required AppData newAppData}) async {
    _appData = newAppData;

    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _loadUserId();
      _listenToUserDocument();
      _listenToActivities();
      _listenToAthlete();
      _listenToGear();
      _registerFcmToken();
    } catch (e) {
      _isInitialized = false;
      debugPrint("StravaService.update failed: $e");
    }
  }

  void _listenToUserDocument() {
    if (_userId == null) return;
    
    _userDocSubscription?.cancel();
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data == null) return;

        final bool wasConnected = _isConnected;
        _isConnected = data['strava_connected'] ?? false;

        // Sync Status tracking (Idle, Syncing, Error)
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
          // Don't clear error if it was set by a local failure (e.g. timeout) 
          // but usually the backend will reset it to idle + empty error on new attempts
        }
        
        // If status or connection changed, notify listeners
        notifyListeners();

        if (wasConnected != _isConnected) {
          debugPrint("Strava connection status changed: $_isConnected");
        }
      }
    }, onError: (e) {
      debugPrint("Error listening to user document: $e");
      errorMessage = "Could not verify connection (No internet?)";
    });
  }

  void _listenToActivities() {
    if (_userId == null) return;

    _activitiesSubscription?.cancel();
    _activitiesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('activities')
        .orderBy('synced_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      _appData.updateStravaActivities(snapshot.docs.map((doc) => StravaActivity.fromFirestore(doc.data()))); //FIXME -> how to handle delete?
    }, onError: (e) {
      debugPrint("Strava sync stream error: $e");
      errorMessage = "Background sync error (Internet issue?)";
    });
  }

  void _listenToAthlete() {
    if (_userId == null) return;

    _athleteSubscription?.cancel();
    _athleteSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('athletes')
        .doc('athlete')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final athlete = StravaAthlete.fromFireStore(snapshot.data()!);
        _appData.updateStravaAthlete(athlete);
        debugPrint("Strava athlete synced: ${athlete.firstname} ${athlete.lastname}");
      }
    }, onError: (e) {
      debugPrint("Strava athlete sync error: $e");
    });
  }

  void _listenToGear() {
    if (_userId == null) return;

    _gearSubscription?.cancel();
    _gearSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('gears')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final gear = StravaGear.fromFireStore(doc.data());
        _appData.updateStravaGear(gear);
      }
      if (snapshot.docs.isNotEmpty) {
        debugPrint("Strava gear synced: ${snapshot.docs.length} items");
      }
    }, onError: (e) {
      debugPrint("Strava gear sync error: $e");
    });
  }

  Future<void> _registerFcmToken() async {
    if (_userId == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .set({'fcm_token': token}, SetOptions(merge: true));
          debugPrint("FCM Token registered for $_userId");
        }
      }
    } catch (e) {
      debugPrint("Error registering FCM token: $e");
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('strava_user_id');
    if (_userId == null || _userId!.isEmpty) {
      _userId = const Uuid().v4();
      await prefs.setString('strava_user_id', _userId!);
    }
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

  static void openActivityOnStrava(int activityId) async {
    final url = Uri.parse("https://www.strava.com/activities/$activityId");
    await launchUrl(url, mode: LaunchMode.externalApplication);
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
        await launchUrl(
          authUrl,
          mode: LaunchMode.externalApplication, // use Strava App if existing
        );
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
    
    status = StravaServiceStatus.syncing;
    errorMessage = "Disconnecting...";
    
    try {
      // 1. Call Backend Cleanup
      final response = await http.get(Uri.parse("$_deauthorizeUri?state=$_userId"));
      if (response.statusCode != 200) {
        throw "Backend cleanup failed: ${response.body}";
      }

      // 2. Clear Local State
      _appData.clearStravaData();

      _isConnected = false;
      errorMessage = "";
      status = StravaServiceStatus.idle;
      notifyListeners();
      debugPrint("Strava disconnected and data wiped.");

    } catch (e) {
      debugPrint("Error disconnecting Strava: $e");
      errorMessage = "Disconnection failed: $e";
      status = StravaServiceStatus.idle;
    }
  }

  Future<void> triggerManualSync() async {
    if (_userId == null) return;
    
    status = StravaServiceStatus.syncing;
    errorMessage = ""; // Clear previous errors
    
    try {
      final response = await http.get(Uri.parse("$_syncUri?state=$_userId"));
      
      if (response.statusCode != 200) {
        throw "Sync failed: ${response.body}";
      }
      
      debugPrint("Manual sync successful: ${response.body}");
      status = StravaServiceStatus.idle;
      
    } catch (e) {
      debugPrint("Error manually syncing Strava: $e");
      errorMessage = "Sync failed: $e";
      status = StravaServiceStatus.idle;
    }
  }

  Future<void> triggerFullHistorySync() async {
    if (_userId == null) return;
    
    status = StravaServiceStatus.syncing;
    errorMessage = ""; // Clear previous errors
    
    try {
      final response = await http.get(Uri.parse("$_syncFullHistoryUri?state=$_userId"));
      
      if (response.statusCode != 200) {
        throw "Full history sync triggered fail: ${response.body}";
      }
      
      debugPrint("Full history sync triggered successfully: ${response.body}");
      status = StravaServiceStatus.idle;
      
    } catch (e) {
      debugPrint("Error triggering full history sync: $e");
      errorMessage = "Full history sync fail: $e";
      status = StravaServiceStatus.idle;
    }
  }
}
