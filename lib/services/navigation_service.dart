import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Pops back towards the first route, but stops at a route that blocks
  /// popping, such as a form with unsaved changes: [NavigatorState.pop]
  /// ignores `PopScope.canPop`, so the changes would be lost without a prompt.
  static void popToFirstUnblocked() {
    navigator?.popUntil((route) => route.isFirst || route.popDisposition == RoutePopDisposition.doNotPop);
  }

  /// Brings the home page's Tasks tab to the front. The home page resets it,
  /// so a request made before the page exists, as on a cold start, waits.
  static final ValueNotifier<bool> tasksTabRequested = ValueNotifier<bool>(false);
}
