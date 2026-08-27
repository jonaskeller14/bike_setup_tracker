import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('error action uses the error snackbar foreground color', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.error(
        context,
        'Add a bike first',
        action: AppSnackBarAction(label: 'ADD', onPressed: () {}),
      ),
    );
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final action = snackBar.action!;
    expect(action.textColor, Theme.of(context).colorScheme.onErrorContainer);
  });
}
