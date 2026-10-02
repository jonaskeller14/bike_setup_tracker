import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/pages/forms/bike_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StravaSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => true;
}

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

  Widget createWidgetUnderTest(Widget home, {SubscriptionService? subscriptionService}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        if (subscriptionService != null)
          ChangeNotifierProvider<SubscriptionService>.value(value: subscriptionService)
        else
          ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(theme: materialAppTheme, home: home),
    );
  }

  testWidgets('BikePage/Add input validation', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(BikePage.add()));

    Finder bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, '');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsAny);

    bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, '    ');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsAny);

    bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, 'TestBike #1');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsNothing);
  });

  testWidgets('BikePage/Edit input validation', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(BikePage.edit(bike: Bike(name: "TestBike #1", person: null))));

    Finder bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, '');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsAny);

    bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, '    ');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsAny);

    bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, 'TestBike #1 new');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsNothing);
  });

  group('attachments', () {
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (call) async => Directory.systemTemp.path,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, null);
    });

    final manual = Attachment(id: 'manual', extension: '.pdf', name: 'Frame Manual.pdf');
    final invoice = Attachment(id: 'invoice', extension: '.pdf', name: 'Invoice.pdf');
    Bike bikeWithAttachments() => Bike(id: 'bike1', name: 'Test Bike', person: null, attachments: [manual, invoice]);

    Finder attachChip() => find.widgetWithIcon(ActionChip, Icons.attach_file);

    testWidgets('hides the Attach chip when attachments are disabled', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(BikePage.edit(bike: bikeWithAttachments())));
      await tester.pumpAndSettle();

      expect(attachChip(), findsNothing);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    testWidgets('shows the Attach chip next to Initial Stats and the strip below', (tester) async {
      appSettings.enableAttachments = true;
      await tester.pumpWidget(
        createWidgetUnderTest(
          BikePage.edit(bike: bikeWithAttachments()),
          subscriptionService: _StravaSubscriptionService(),
        ),
      );
      await tester.pumpAndSettle();

      final wrap = find.ancestor(of: attachChip(), matching: find.byType(Wrap));
      expect(wrap, findsOneWidget);
      expect(find.descendant(of: wrap, matching: find.widgetWithText(FilterChip, 'Initial Stats')), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsOneWidget);
      expect(find.text('Frame Manual.pdf'), findsOneWidget);
    });

    testWidgets('shows the Attach chip alone without Strava', (tester) async {
      appSettings.enableAttachments = true;
      await tester.pumpWidget(createWidgetUnderTest(BikePage.add()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Additional Fields'));
      await tester.pumpAndSettle();

      expect(find.text('Initial Stats'), findsNothing);
      expect(attachChip(), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    testWidgets('removing an attachment marks the form changed and saving returns the rest', (tester) async {
      appSettings.enableAttachments = true;
      Bike? result;
      await tester.pumpWidget(
        createWidgetUnderTest(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await Navigator.push<Bike>(context, MaterialPageRoute(builder: (_) => BikePage.edit(bike: bikeWithAttachments()))),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      Color? chipColor() => tester.widget<ActionChip>(attachChip()).backgroundColor;
      expect(chipColor(), isNull);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Frame Manual.pdf'), findsNothing);
      final changedFill = Theme.of(tester.element(attachChip())).extension<ValueHighlightColors>()!.changedFill;
      expect(chipColor(), changedFill);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(result?.id, 'bike1');
      expect(result?.attachments, [invoice]);
    });
  });
}
