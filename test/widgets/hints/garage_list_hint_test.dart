import 'package:bike_setup_tracker/widgets/hints/garage_list_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calls its dismiss callback', (tester) async {
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GarageListHint(onDismiss: () => dismissed = true),
        ),
      ),
    );

    expect(find.text('Gestures in Garage').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Skip').hitTestable());
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}
