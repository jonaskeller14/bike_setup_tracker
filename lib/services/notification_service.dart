import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../pages/details/strava_activitiy_details_page.dart';
import '../repositories/app_repository.dart';
import 'navigation_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  late AppRepository _appRepository;
  bool _isInitialized = false;

  void init(AppRepository appRepository) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _appRepository = appRepository;

    // Handle message when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
    });

    // Handle message when app is in background and opened by tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle message when app is launched from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  void _handleMessage(RemoteMessage message) async {
    debugPrint('NotificationService: Received message data: ${message.data}');

    final data = message.data;
    final type = data['type'];
    final activityIdStr = data['activityId'] as String?;

    if (type == 'strava_sync' && activityIdStr != null) {
      final activityId = int.tryParse(activityIdStr);
      if (activityId != null) {
        await _navigateToStravaActivity(activityId);
      } else {
        debugPrint('NotificationService: Failed to parse activityId: $activityIdStr');
      }
    } else {
      debugPrint('NotificationService: Message ignored');
    }
  }

  Future<void> _navigateToStravaActivity(int activityId, {int retryCount = 0}) async {
    // Check if repository has activities. On fresh launch, it might take a moment to load from DB.
    final activity = _appRepository.stravaActivities[activityId];

    if (activity != null) {
      unawaited(
      NavigationService.navigator?.push(
        MaterialPageRoute(
          builder: (context) => StravaActivityDetailsPage(stravaActivity: activity),
          ),
        ),
      );
    } else if (retryCount < 3) {
      // Small delay and retry for "cold starts" where the app is launched from a notification
      // and the database streams haven't emitted the first set of data yet.
      debugPrint('NotificationService: Activity $activityId not in memory yet, retrying... ($retryCount)');
      await Future.delayed(const Duration(milliseconds: 800));
      return _navigateToStravaActivity(activityId, retryCount: retryCount + 1);
    } else {
      debugPrint('NotificationService: Activity $activityId not found after retries.');
    }
  }
}
