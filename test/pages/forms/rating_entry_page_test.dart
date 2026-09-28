import 'dart:async';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
import 'package:bike_setup_tracker/pages/forms/rating_entry_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.showOnboarding = false;
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  testWidgets('saving keeps values of removed metrics', (tester) async {
    final bike = Bike(name: 'Test Bike', person: null);
    await tester.runAsync(() => appRepository.addBikes([bike]));
    await _waitForRepositoryUpdate(tester, appRepository);

    final ratingEntry = RatingEntry(
      bike: bike.id,
      setupId: 's1',
      dateTimeUTC: DateTime.utc(2026, 1, 1, 12),
      dateTimeLocal: DateTime(2026, 1, 1, 12),
      metricValues: {'removed-metric': const UnresolvedValue('4')},
    );
    RatingEntry? saved;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
          ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                saved = await Navigator.push<RatingEntry>(
                  context,
                  MaterialPageRoute(builder: (_) => RatingEntryPage.edit(ratingEntry: ratingEntry)),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(saved?.metricValues, {'removed-metric': const UnresolvedValue('4')});
  });
}

Future<void> _waitForRepositoryUpdate(WidgetTester tester, AppRepository repository) async {
  final completer = Completer<void>();
  void listener() {
    if (!completer.isCompleted) completer.complete();
  }

  repository.addListener(listener);
  await tester.runAsync(() async {
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // Fall through to the pump below.
    }
  });
  repository.removeListener(listener);
  await tester.pump();
}
