import 'dart:async';

import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/services/address_service.dart';
import 'package:bike_setup_tracker/services/elevation_service.dart';
import 'package:bike_setup_tracker/services/location_provider.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_location_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:provider/provider.dart';

void main() {
  late AppSettings settings;

  setUp(() => settings = AppSettings());
  tearDown(() => settings.dispose());

  Widget buildSheet({
    required LocationService service,
    ContextPosition? currentLocation,
    geo.Placemark? currentPlace,
    MediaQueryData? mediaQueryData,
  }) {
    final child = MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
      ],
      child: Scaffold(
        body: SetLocationPlaceSheetContent(
          locationService: service,
          elevationService: FakeElevationService(),
          currentLocation: currentLocation,
          addressService: FakeAddressService(),
          currentPlace: currentPlace,
        ),
      ),
    );
    return MaterialApp(
      theme: materialAppTheme,
      home: mediaQueryData == null ? child : MediaQuery(data: mediaQueryData, child: child),
    );
  }

  testWidgets('shows distinct recovery states and retains saved fields', (tester) async {
    const saved = ContextPosition(latitude: 47.3769, longitude: 8.5417, altitude: 408);
    final cases = <LocationStatus, String>{
      LocationStatus.noService: 'Location services are disabled',
      LocationStatus.noPermission: 'Location permission denied',
      LocationStatus.permissionDeniedForever: 'Location permission permanently denied',
      LocationStatus.timeout: 'Location request timed out',
      LocationStatus.error: 'Could not determine location',
    };

    for (final entry in cases.entries) {
      final service = LocationService(provider: FakeSheetLocationProvider())..setStatus(entry.key);
      await tester.pumpWidget(buildSheet(service: service, currentLocation: saved));

      expect(find.text(entry.value), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '47.3769'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '8.5417'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '408.0'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      service.dispose();
    }
  });

  testWidgets('opens location settings for disabled services', (tester) async {
    final provider = FakeSheetLocationProvider();
    final service = LocationService(provider: provider)..setStatus(LocationStatus.noService);
    await tester.pumpWidget(buildSheet(service: service));

    await tester.tap(find.widgetWithText(TextButton, 'Open settings'));
    await tester.pump();

    expect(provider.openLocationSettingsCalls, 1);
    expect(provider.openAppSettingsCalls, 0);
  });

  testWidgets('opens app settings for permanent denial', (tester) async {
    final provider = FakeSheetLocationProvider();
    final service = LocationService(provider: provider)..setStatus(LocationStatus.permissionDeniedForever);
    await tester.pumpWidget(buildSheet(service: service));

    await tester.tap(find.widgetWithText(TextButton, 'Open settings'));
    await tester.pump();

    expect(provider.openAppSettingsCalls, 1);
    expect(provider.openLocationSettingsCalls, 0);
  });

  testWidgets('shows inline feedback when location settings cannot open', (tester) async {
    final provider = FakeSheetLocationProvider()..openLocationSettingsResult = false;
    final service = LocationService(provider: provider)..setStatus(LocationStatus.noService);
    await tester.pumpWidget(buildSheet(service: service));

    await tester.tap(find.widgetWithText(TextButton, 'Open settings'));
    await tester.pump();

    expect(find.text('Could not open location settings.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('ordinary denial retries through the GPS action', (tester) async {
    final provider = FakeSheetLocationProvider()
      ..checkedPermission = LocationProviderPermission.denied
      ..requestedPermission = LocationProviderPermission.denied;
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildSheet(service: service));

    await tester.tap(find.text('Find Location via GPS'));
    await tester.pump();
    expect(service.status, LocationStatus.noPermission);
    expect(find.text('Try GPS again to request permission'), findsOneWidget);
    expect(find.text('Open settings'), findsNothing);

    provider.requestedPermission = LocationProviderPermission.whileInUse;
    await tester.tap(find.text('Find Location via GPS'));
    await tester.pumpAndSettle();

    expect(provider.getCurrentPositionCalls, 1);
    expect(find.widgetWithText(TextFormField, '47.1'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '8.2'), findsOneWidget);
  });

  testWidgets('prevents concurrent GPS requests while fields remain available afterward', (tester) async {
    final completer = Completer<ContextPosition>();
    final provider = FakeSheetLocationProvider()..pendingPosition = completer.future;
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildSheet(service: service));

    await tester.tap(find.text('Find Location via GPS'));
    await tester.pump();

    final searchingButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(searchingButton.onPressed, isNull);
    expect(provider.getCurrentPositionCalls, 1);

    completer.complete(const ContextPosition(latitude: 47.1, longitude: 8.2));
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNotNull);
    expect(tester.widget<TextFormField>(find.widgetWithText(TextFormField, '47.1')).enabled, isTrue);
  });

  testWidgets('recovery UI fits a narrow screen with large text', (tester) async {
    final provider = FakeSheetLocationProvider();
    final service = LocationService(provider: provider)..setStatus(LocationStatus.noService);
    await tester.pumpWidget(
      buildSheet(
        service: service,
        mediaQueryData: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.8),
        ),
      ),
    );

    expect(find.text('Location services are disabled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class FakeAddressService extends AddressService {
  @override
  Future<geo.Placemark?> fetchAddress({required double lat, required double lon}) async {
    setStatus(AddressStatus.success);
    return null;
  }
}

class FakeElevationService extends ElevationService {
  @override
  Future<double?> fetchElevation({required double lat, required double lon}) async {
    setStatus(ElevationStatus.success);
    return 512;
  }
}

class FakeSheetLocationProvider implements LocationProvider {
  LocationProviderPermission checkedPermission = LocationProviderPermission.whileInUse;
  LocationProviderPermission requestedPermission = LocationProviderPermission.whileInUse;
  Future<ContextPosition>? pendingPosition;
  int getCurrentPositionCalls = 0;
  int openAppSettingsCalls = 0;
  int openLocationSettingsCalls = 0;
  bool openAppSettingsResult = true;
  bool openLocationSettingsResult = true;

  @override
  Future<LocationProviderPermission> checkPermission() async => checkedPermission;

  @override
  Future<ContextPosition> getCurrentPosition() async {
    getCurrentPositionCalls++;
    return pendingPosition ?? const ContextPosition(latitude: 47.1, longitude: 8.2);
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls++;
    return openAppSettingsResult;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls++;
    return openLocationSettingsResult;
  }

  @override
  Future<LocationProviderPermission> requestPermission() async => requestedPermission;
}
