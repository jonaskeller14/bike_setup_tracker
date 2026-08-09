import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/bike_actions.dart';
import '../utils/component_actions.dart';
import '../utils/setup_actions.dart';
import '../utils/task_actions.dart';
import 'navigation_service.dart';
import 'strava_service.dart';
  
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  
  // Internal constructor for singleton and test injection
  @visibleForTesting
  DeepLinkService.test(this._appLinks);

  DeepLinkService._internal() : _appLinks = AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;
  Uri? _lastHandledUri;
  DateTime? _lastHandledTime;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object err) {
        debugPrint('DeepLinkService error: $err');
      },
    );

    // Check for initial link
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      await _handleDeepLink(uri);
    }
  }

  void dispose() async {
    await _linkSubscription?.cancel();
  }

  Future<void> _handleDeepLink(Uri uri) async {
    // Prevent duplicate handling (especially during startup when stream and initialLink might both fire)
    if (_lastHandledUri == uri && 
        _lastHandledTime != null && 
        DateTime.now().difference(_lastHandledTime!).inMilliseconds < 1000) {
      return;
    }

    _lastHandledUri = uri;
    _lastHandledTime = DateTime.now();

    if (uri.scheme != 'bike-setup-tracker') return;

    switch (uri.host) {
      case 'add-setup':
        await _triggerAddSetup();
      case 'add-bike':
        await _triggerAddBike();
      case 'add-component':
        await _triggerAddComponent();
      case 'add-task':
        await _triggerAddTaskRule();
      case 'add':
        // App Actions CREATE capability routes here: ?type={matched shortcutId}
        switch (uri.queryParameters['type']) {
          case 'setup':
            await _triggerAddSetup();
          case 'bike':
            await _triggerAddBike();
          case 'component':
            await _triggerAddComponent();
        }
      case 'strava-auth':
        _notifyStravaAuthCallback(
          success: uri.queryParameters['success'] == 'true',
          error: uri.queryParameters['error'],
        );
    }
  }

  void _notifyStravaAuthCallback({required bool success, String? error}) {
    final context = NavigationService.context;
    if (context == null) return;
    try {
      context.read<StravaService>().handleStravaAuthCallback(
            success: success,
            error: error,
          );
    } catch (_) {
      // StravaService not yet available in the tree — listener will reconcile.
    }
  }

  Future<void> _triggerAddSetup() async {
    final context = NavigationService.context;
    if (context == null) return;

    await SetupActions.addSetup(context);
  }

  Future<void> _triggerAddBike() async {
    final context = NavigationService.context;
    if (context == null) return;

    await BikeActions.addBike(context);
  }

  Future<void> _triggerAddComponent() async {
    final context = NavigationService.context;
    if (context == null) return;

    await ComponentActions.addComponent(context);
  }

  Future<void> _triggerAddTaskRule() async {
    final context = NavigationService.context;
    if (context == null) return;

    await TaskActions.addTaskRule(context);
  }
}
