import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../utils/setup_actions.dart';
import 'navigation_service.dart';

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
      onError: (err) {
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
      debugPrint('Ignoring duplicate deep link: $uri');
      return;
    }

    _lastHandledUri = uri;
    _lastHandledTime = DateTime.now();

    debugPrint('Received deep link: $uri');

    if (uri.scheme == 'bike-setup-tracker' && uri.host == 'add-setup') {
      _triggerAddSetup();
    } else if (uri.scheme == 'bike-setup-tracker' && uri.host == 'strava-auth') {
      if (uri.queryParameters['success'] == 'false') {
        _showStravaAuthError();
      }
    }
  }

  Future<void> _triggerAddSetup() async {
    final context = NavigationService.context;
    if (context == null) return;

    await SetupActions.addSetup(context);
  }

  void _showStravaAuthError() {
    final context = NavigationService.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Strava connection failed. Please try again.')),
    );
  }
}
