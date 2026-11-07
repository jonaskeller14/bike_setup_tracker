import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/filters/layer_filter.dart';
import '../pages/calendar_page.dart';
import '../pages/details/strava_activity_details_page.dart';
import '../repositories/app_repository.dart';
import '../utils/map_actions.dart';
import '../widgets/sheets/feature_setting_sheet.dart';
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
        // The backend picks `open` together with the prompt it fits.
        switch (data['open']) {
          case 'tasks':
            await _openTasks();
          case 'calendar':
            await _openCalendar();
          case 'map':
            await _navigateToStravaActivity(activityId, onMap: true);
          default:
            await _navigateToStravaActivity(activityId);
        }
      } else {
        debugPrint('NotificationService: Failed to parse activityId: $activityIdStr');
      }
    } else {
      debugPrint('NotificationService: Message ignored');
    }
  }

  Future<void> _navigateToStravaActivity(int activityId, {bool onMap = false, int retryCount = 0}) async {
    final activity = await _appRepository.getStravaActivity(activityId);

    if (activity != null) {
      final context = NavigationService.context;
      if (onMap && context != null && context.mounted) {
        unawaited(MapActions.openActivityOnMap(context, activity));
        return;
      }
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
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return _navigateToStravaActivity(activityId, onMap: onMap, retryCount: retryCount + 1);
    } else {
      debugPrint('NotificationService: Activity $activityId not found after retries.');
    }
  }

  Future<void> _openTasks() async {
    final context = await _navigatorContext();
    if (context == null || !context.mounted) return;
    NavigationService.popToFirstUnblocked();
    final appSettings = context.read<AppSettings>();
    final l10n = context.l10n;
    final isOn = await _offerFeature(
      context,
      isOn: appSettings.enableTask,
      title: l10n.featuresTasks,
      infoText: l10n.featuresTasksInfo,
    );
    if (!isOn) return;
    appSettings.enableTask = true;
    NavigationService.tasksTabRequested.value = true;
  }

  Future<void> _openCalendar() async {
    final context = await _navigatorContext();
    if (context == null || !context.mounted) return;
    final appSettings = context.read<AppSettings>();
    final l10n = context.l10n;
    final isOn = await _offerFeature(
      context,
      isOn: appSettings.enableCalendar,
      title: l10n.featuresCalendar,
      infoText: l10n.featuresCalendarInfo,
    );
    if (!isOn || !context.mounted) return;
    appSettings.enableCalendar = true;
    // The prompt promises this ride in the calendar, so its layer must show.
    final filters = _appRepository.filters;
    filters.layers = filters.layers.copyWith(hidden: filters.layers.hidden.difference({TimelineLayer.activities}));
    unawaited(Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const CalendarPage())));
  }

  /// Tasks and the calendar start switched off, so a prompt for one first
  /// offers the same on/off sheet as the features settings.
  Future<bool> _offerFeature(
    BuildContext context, {
    required bool isOn,
    required String title,
    required String infoText,
  }) async {
    if (isOn) return true;
    return await showFeatureSettingSheet(context, title: title, value: false, infoText: infoText) ?? false;
  }

  /// On a cold start the notification can arrive before the first frame.
  Future<BuildContext?> _navigatorContext() async {
    for (var attempt = 0; attempt <= 3; attempt++) {
      final context = NavigationService.context;
      if (context != null) return context;
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    return null;
  }
}
