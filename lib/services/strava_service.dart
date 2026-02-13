import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../models/strava/strava_activity.dart';

enum StravaServiceStatus {
  idle,
  syncing,
}

class StravaService extends ChangeNotifier {
  static const String _stravaClientId = "193047";
  static const String _redirectUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/exchangeToken";
  static const String _deauthorizeUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/deauthorizeUser";
  static const String _syncUri = "https://europe-west3-bike-setup-tracker-strava.cloudfunctions.net/syncActivities";
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
  final List<StravaActivity> _activities = [];
  List<StravaActivity> get activities => List.unmodifiable(_activities);

  StreamSubscription? _activitiesSubscription;
  StreamSubscription? _userDocSubscription;
  bool _isDisposed = false;

  StravaService();

  @override
  void dispose() {
    _isDisposed = true;
    _activitiesSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> update() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _loadUserId();
      _listenToUserDocument();
      await _loadLocalActivities();
      _listenToActivities();
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
        final bool wasConnected = _isConnected;
        _isConnected = snapshot.data()?['strava_connected'] ?? false;
        
        // If connection status changed, notify listeners
        if (wasConnected != _isConnected) {
          debugPrint("Strava connection status changed: $_isConnected");
          notifyListeners();
        }
      }
    }, onError: (e) {
      debugPrint("Error listening to user document: $e");
      errorMessage = "Could not verify connection (No internet?)";
    });
  }

  Future<void> _loadLocalActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('strava_activities');
    if (encoded != null) {
      final List<dynamic> decoded = jsonDecode(encoded);
      _activities.clear();
      _activities.addAll(decoded.map((a) => StravaActivity.fromJson(a)));
      notifyListeners();
    }
  }

  Future<void> _saveLocalActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_activities.map((a) => a.toJson()).toList());
    await prefs.setString('strava_activities', encoded);
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
      bool changed = false;
      for (var doc in snapshot.docs) {
        final activity = StravaActivity.fromFirestore(doc.data());
        if (!_activities.any((a) => a.id == activity.id)) { //FIXME: merge logic
          _activities.insert(0, activity);
          changed = true;
          debugPrint("New Strava activity imported: ${activity.name}");
        }
      }
      if (changed) {
        _saveLocalActivities();
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint("Strava sync stream error: $e");
      errorMessage = "Background sync error (Internet issue?)";
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
      _activities.clear();
      _isConnected = false;
      
      // 3. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('strava_activities');

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
}
