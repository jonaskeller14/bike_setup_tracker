import 'package:bike_setup_tracker/utils/map_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showOpenMapMenu', () {
    Future<void> openMenu(WidgetTester tester, {required VoidCallback? onViewOnMap}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => MapActions.showOpenMapMenu(
                  context,
                  globalPosition: Offset.zero,
                  onViewOnMap: onViewOnMap,
                  externalTargets: const [
                    (label: 'Open A in maps app', latitude: 46.5, longitude: 9.8, displayName: 'A'),
                    (label: 'Open B in maps app', latitude: 46.6, longitude: 9.9, displayName: 'B'),
                  ],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers the in-app map and every external target', (tester) async {
      var viewedOnMap = false;
      await openMenu(tester, onViewOnMap: () => viewedOnMap = true);

      expect(find.text('Open A in maps app'), findsOneWidget);
      expect(find.text('Open B in maps app'), findsOneWidget);

      await tester.tap(find.text('View on map'));
      await tester.pumpAndSettle();

      expect(viewedOnMap, isTrue);
    });

    testWidgets('leaves out the in-app map without a callback', (tester) async {
      await openMenu(tester, onViewOnMap: null);

      expect(find.text('View on map'), findsNothing);
      expect(find.text('Open A in maps app'), findsOneWidget);
    });
  });
}
