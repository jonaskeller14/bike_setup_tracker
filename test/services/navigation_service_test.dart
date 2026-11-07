import 'dart:async';

import 'package:bike_setup_tracker/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigationService.popToFirstUnblocked', () {
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          home: const Text('home'),
        ),
      );
    }

    void push(Widget page) {
      NavigationService.navigator!.push(MaterialPageRoute<void>(builder: (_) => page));
    }

    testWidgets('pops every route above the first', (tester) async {
      await pumpApp(tester);
      push(const Text('details'));
      push(const Text('more details'));
      await tester.pumpAndSettle();

      NavigationService.popToFirstUnblocked();
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('details'), findsNothing);
      expect(find.text('more details'), findsNothing);
    });

    testWidgets('stops at a route that blocks popping and closes what is above it', (tester) async {
      await pumpApp(tester);
      push(const PopScope(canPop: false, child: Text('unsaved form')));
      await tester.pumpAndSettle();
      unawaited(
        showDialog<void>(
          context: NavigationService.context!,
          builder: (_) => const Text('dialog'),
        ),
      );
      await tester.pumpAndSettle();

      NavigationService.popToFirstUnblocked();
      await tester.pumpAndSettle();

      expect(find.text('unsaved form'), findsOneWidget);
      expect(find.text('dialog'), findsNothing);
    });
  });
}
