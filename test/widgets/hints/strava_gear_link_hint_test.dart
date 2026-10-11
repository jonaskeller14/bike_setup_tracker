import 'package:bike_setup_tracker/widgets/hints/strava_gear_link_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('delegates dismissal', (tester) async {
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StravaGearLinkHint(onDismiss: () => dismissed = true),
        ),
      ),
    );

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}
