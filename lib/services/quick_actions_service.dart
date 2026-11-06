import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

import '../l10n/l10n.dart';
import '../utils/setup_actions.dart';
import 'navigation_service.dart';

class QuickActionsService {
  static final QuickActionsService _instance = QuickActionsService._internal();
  factory QuickActionsService() => _instance;

  QuickActionsService._internal();

  final QuickActions _quickActions = const QuickActions();
  bool _isInitialized = false;
  Locale? _registeredLocale;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _quickActions.initialize((String shortcutType) {
      unawaited(_handleShortcut(shortcutType));
    });
  }

  /// Registers the shortcuts with titles in [locale]; the launcher keeps showing
  /// the registered text, so this runs again whenever the app language changes.
  Future<void> updateLocale(Locale locale) async {
    if (_registeredLocale == locale) return;
    _registeredLocale = locale;

    try {
      await _quickActions.setShortcutItems(<ShortcutItem>[
        ShortcutItem(
          type: 'add_setup',
          localizedTitle: lookupAppLocalizations(locale).quickActionAddSetup,
          icon: 'ic_add',
          // For anroid: android\app\src\main\res\raw\keep.xml
        ),
      ]);
    } catch (e) {
      debugPrint('Failed to set shortcut items: $e');
    }
  }

  Future<void> _handleShortcut(String shortcutType) async {
    debugPrint('Received quick action: $shortcutType');

    if (shortcutType == 'add_setup') {
      unawaited(_triggerAddSetup());
    }
  }

  Future<void> _triggerAddSetup() async {
    final context = NavigationService.context;
    if (context == null) {
      // If context is not ready, wait a bit and try again
      Future.delayed(const Duration(milliseconds: 500), _triggerAddSetup);
      return;
    }

    await SetupActions.addSetup(context);
  }
}
