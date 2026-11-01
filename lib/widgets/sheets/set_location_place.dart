import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/context/context_place.dart';
import '../../models/context/context_position.dart';
import '../../services/address_service.dart';
import '../../services/elevation_service.dart';
import '../../services/location_service.dart';
import '../../theme.dart';
import '../../utils/localized_number.dart';
import '../../utils/number_input_formatters.dart';
import '../dialogs/discard_changes.dart';
import 'sheet_header.dart';

class LocationAndPlace {
  final ContextPosition? location;
  final geo.Placemark? place;
  const LocationAndPlace({required this.location, required this.place});
}

Future<LocationAndPlace?> showSetLocationPlaceSheet({
  required BuildContext context,
  required LocationService locationService,
  required ContextPosition? currentLocation,
  required AddressService addressService,
  required geo.Placemark? currentPlace,
}) async {
  return showModalBottomSheet(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return SetLocationPlaceSheetContent(
        locationService: locationService,
        currentLocation: currentLocation,
        addressService: addressService,
        currentPlace: currentPlace,
      );
    },
  );
}

class SetLocationPlaceSheetContent extends StatefulWidget {
  final LocationService locationService;
  final ElevationService? elevationService;
  final ContextPosition? currentLocation;
  final AddressService addressService;
  final geo.Placemark? currentPlace;

  const SetLocationPlaceSheetContent({
    super.key,
    required this.locationService,
    this.elevationService,
    required this.currentLocation,
    required this.addressService,
    required this.currentPlace,
  });

  @override
  State<SetLocationPlaceSheetContent> createState() => _SetLocationPlaceSheetContentState();
}

class _SetLocationPlaceSheetContentState extends State<SetLocationPlaceSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _altitudeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();
  String? _addressTextFieldErrorText;
  String? _settingsErrorMessage;

  late final ElevationService _elevationService;

  ContextPosition? _currentLocation;
  geo.Placemark? _currentPlace;

  @override
  void initState() {
    super.initState();

    _elevationService = widget.elevationService ?? ElevationService();
    _currentLocation = widget.currentLocation;
    _currentPlace = widget.currentPlace;
    _setFieldsFromLocationPlace();

    _addressFocusNode.addListener(() {
      if (_addressFocusNode.hasFocus) {
        _addressController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _addressController.text.length,
        );
      }
    });
  }

  void _setFieldsFromLocationPlace() {
    final appSettings = context.read<AppSettings>();

    _latitudeController.text = formatEditableDouble(_currentLocation?.latitude, locale: context.untrackedLocaleName);
    _longitudeController.text = formatEditableDouble(_currentLocation?.longitude, locale: context.untrackedLocaleName);
    _altitudeController.text = formatEditableDouble(
      ContextPosition.convertAltitudeFromMeters(_currentLocation?.altitude, appSettings.altitudeUnit),
      locale: context.untrackedLocaleName,
    );

    _addressController.text = _formatAddress(_currentPlace);
  }

  String _formatAddress(geo.Placemark? place) {
    if (place == null) return "";

    final street = place.thoroughfare?.isNotEmpty == true
        ? "${place.thoroughfare} ${place.subThoroughfare ?? ""}".trim()
        : place.name;
    final city = place.locality ?? place.subLocality ?? "";
    final region = "${place.administrativeArea ?? ""} ${place.postalCode ?? ""}".trim();

    return [street, city, region, place.country].where((s) => s != null && s.isNotEmpty).join(", ");
  }

  Future<void> _updateLocationPlace() async {
    unawaited(HapticFeedback.selectionClick());
    // LOCATION: Lat/Lon/Altitiude
    setState(() {
      _addressTextFieldErrorText = null;
    });
    final fetchedLocation = await widget.locationService.fetchLocation();
    if (!mounted) return;
    if (fetchedLocation == null) return;
    final newLocation = await _elevationService.addMissingElevation(fetchedLocation);
    if (!mounted) return;
    setState(() {
      _currentLocation = newLocation;
      _setFieldsFromLocationPlace();
    });

    // 2: ADDRESS
    await _updatePlace();
  }

  Future<void> _updatePlace() async {
    if (_currentLocation?.latitude == null || _currentLocation?.longitude == null) {
      setState(() {
        _addressTextFieldErrorText = context.l10n.locationNoCoordinatesForAddress;
      });
      return;
    }

    final newAddress = await widget.addressService.fetchAddress(
      lat: _currentLocation!.latitude!,
      lon: _currentLocation!.longitude!,
    );
    if (!mounted) return;
    setState(() {
      _currentPlace = newAddress;
      _setFieldsFromLocationPlace();
      _addressTextFieldErrorText = newAddress == null ? context.l10n.locationNoAddressFound : null;
    });
  }

  Future<void> _searchAddress() async {
    // 1. LOCATION Lat/Lon
    final newLocation = await widget.locationService.locationFromAddress(_addressController.text.trim());
    if (!mounted) return;
    if (newLocation == null) {
      setState(() {
        _addressTextFieldErrorText = context.l10n.locationNotFound;
      });
      return;
    }
    setState(() {
      _currentLocation = newLocation;
      _addressTextFieldErrorText = null;
      _setFieldsFromLocationPlace();
    });

    if (_currentLocation?.latitude == null || _currentLocation?.longitude == null) return;

    // 2: LOCATION Altitude
    final locationWithElevation = await _elevationService.addMissingElevation(_currentLocation!);
    if (!mounted) return;
    setState(() {
      _currentLocation = locationWithElevation;
      _setFieldsFromLocationPlace();
    });

    // 3: ADDRESS
    await _updatePlace();
  }

  Future<void> _openLocationSettings() async {
    unawaited(HapticFeedback.selectionClick());
    final opened = await widget.locationService.openLocationSettings();
    if (!mounted) return;
    setState(() {
      _settingsErrorMessage = opened ? null : context.l10n.locationSettingsOpenFailed;
    });
  }

  Future<void> _openAppSettings() async {
    unawaited(HapticFeedback.selectionClick());
    final opened = await widget.locationService.openAppSettings();
    if (!mounted) return;
    setState(() {
      _settingsErrorMessage = opened ? null : context.l10n.locationAppSettingsOpenFailed;
    });
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(LocationAndPlace(location: _currentLocation, place: _currentPlace));
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    final hasChanges =
        !ContextPlace.equal(widget.currentPlace, _currentPlace) ||
        !ContextPosition.equal(widget.currentLocation, _currentLocation);
    if (!hasChanges) {
      Navigator.of(context).pop(null);
      return;
    }

    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    return ListenableBuilder(
      listenable: Listenable.merge([widget.locationService, widget.addressService, _elevationService]),
      builder: (context, child) {
        final enableFields =
            widget.locationService.status != LocationStatus.searching &&
            widget.addressService.status != AddressStatus.searching;
        final enableUpdate =
            widget.locationService.status != LocationStatus.searching &&
            widget.addressService.status != AddressStatus.searching;
        final enableUpdatePlace =
            enableUpdate && _currentLocation?.latitude != null && _currentLocation?.longitude != null;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: _handlePopInvoked,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SheetHeader(title: context.l10n.locationSheetTitle),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.locationService.status == LocationStatus.noService)
                              ListTile(
                                key: const Key('location-service-disabled'),
                                leading: Icon(Icons.location_disabled, color: Theme.of(context).colorScheme.error),
                                title: Text(context.l10n.locationServicesDisabled),
                                subtitle: Text(context.l10n.locationServicesDisabledHint),
                                trailing: TextButton(
                                  onPressed: _openLocationSettings,
                                  child: Text(context.l10n.locationOpenSettings),
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (widget.locationService.status == LocationStatus.noPermission)
                              ListTile(
                                leading: Icon(Icons.location_disabled, color: Theme.of(context).colorScheme.error),
                                title: Text(context.l10n.locationPermissionDenied),
                                subtitle: Text(context.l10n.locationPermissionDeniedHint),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (widget.locationService.status == LocationStatus.permissionDeniedForever)
                              ListTile(
                                key: const Key('location-permission-permanently-denied'),
                                leading: Icon(Icons.location_disabled, color: Theme.of(context).colorScheme.error),
                                title: Text(context.l10n.locationPermissionForever),
                                subtitle: Text(context.l10n.locationPermissionForeverHint),
                                trailing: TextButton(
                                  onPressed: _openAppSettings,
                                  child: Text(context.l10n.locationOpenSettings),
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (widget.locationService.status == LocationStatus.timeout)
                              ListTile(
                                leading: Icon(Icons.timer_off_outlined, color: Theme.of(context).colorScheme.error),
                                title: Text(context.l10n.locationTimeout),
                                subtitle: Text(context.l10n.locationTimeoutHint),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (widget.locationService.status == LocationStatus.error)
                              ListTile(
                                leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                title: Text(context.l10n.locationUndetermined),
                                subtitle: Text(context.l10n.locationUndeterminedHint),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (_elevationService.status == ElevationStatus.error)
                              ListTile(
                                leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                title: SelectableText(context.l10n.locationElevationFailed),
                                subtitle: SelectableText(context.l10n.locationElevationFailedHint),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (widget.addressService.status == AddressStatus.error)
                              ListTile(
                                leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                                title: SelectableText(context.l10n.locationAddressFailed),
                                subtitle: SelectableText(context.l10n.locationAddressFailedHint),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            if (_settingsErrorMessage != null)
                              ListTile(
                                key: const Key('settings-open-error'),
                                leading: Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                title: Text(_settingsErrorMessage!),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),

                            const SizedBox(height: 16),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              inputFormatters: const [SignedDecimalInputFormatter()],
                              controller: _latitudeController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.locationLatitude,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: context.l10n.locationLatitude,
                                suffixText: "°",
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: _currentLocation?.latitude != widget.currentLocation?.latitude,
                                icon: const Icon(Icons.my_location),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = parseLocalizedDouble(value);
                                if (parsedValue == null) return context.l10n.setNumberInvalid;
                                if (parsedValue.abs() > 90) return context.l10n.locationLatitudeRange;
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentLocation = (_currentLocation ?? const ContextPosition()).copyWith(
                                    latitude: parseLocalizedDouble(newValue),
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              inputFormatters: const [SignedDecimalInputFormatter()],
                              controller: _longitudeController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.locationLongitude,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: context.l10n.locationLongitude,
                                suffixText: "°",
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: _currentLocation?.longitude != widget.currentLocation?.longitude,
                                icon: const Icon(Icons.my_location, color: Colors.transparent), // Placeholder
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = parseLocalizedDouble(value);
                                if (parsedValue == null) return context.l10n.setNumberInvalid;
                                if (parsedValue.abs() > 180) return context.l10n.locationLongitudeRange;
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentLocation = (_currentLocation ?? const ContextPosition()).copyWith(
                                    longitude: parseLocalizedDouble(newValue),
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              enabled: enableFields,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              inputFormatters: const [SignedDecimalInputFormatter()],
                              controller: _altitudeController,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: context.l10n.locationAltitudeLabel(appSettings.altitudeUnit),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                hintText: context.l10n.locationAltitudeHint,
                                suffixText: appSettings.altitudeUnit,
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: _currentLocation?.altitude != widget.currentLocation?.altitude,
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return null;
                                final parsedValue = parseLocalizedDouble(value);
                                if (parsedValue == null) return context.l10n.setNumberInvalid;
                                return null;
                              },
                              onChanged: (String newValue) {
                                setState(() {
                                  _currentLocation = (_currentLocation ?? const ContextPosition()).copyWith(
                                    altitude: ContextPosition.convertAltitudeToMeters(
                                      parseLocalizedDouble(newValue),
                                      appSettings.altitudeUnit,
                                    ),
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: enableUpdatePlace ? _updatePlace : null,
                                icon: widget.addressService.status == AddressStatus.searching
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : null,
                                label: Text(context.l10n.locationUpdateAddress),
                              ),
                            ),
                            TextFormField(
                              enabled: enableFields,
                              textInputAction: TextInputAction.search,
                              controller: _addressController,
                              focusNode: _addressFocusNode,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              maxLines: null,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                isDense: true,
                                labelText: context.l10n.locationAddressSearchLabel,
                                hintText: context.l10n.locationAddressHint,
                                contentPadding: const EdgeInsets.all(8),
                                errorText: _addressTextFieldErrorText,
                                icon: const Icon(Icons.location_city),
                                suffixIcon: IconButton(
                                  onPressed: enableFields ? _searchAddress : null,
                                  icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                                ),
                                fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
                                filled: !ContextPlace.equal(widget.currentPlace, _currentPlace),
                              ),
                              validator: null,
                              onFieldSubmitted: enableFields ? (_) => _searchAddress() : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        spacing: 8,
                        children: [
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: OutlinedButton.icon(
                              onPressed: enableUpdate ? _updateLocationPlace : null,
                              icon:
                                  widget.locationService.status == LocationStatus.searching ||
                                      widget.addressService.status == AddressStatus.searching
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location),
                              label: Text(context.l10n.locationFindByGps),
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: FilledButton(
                              onPressed:
                                  ContextPlace.equal(widget.currentPlace, _currentPlace) &&
                                      ContextPosition.equal(widget.currentLocation, _currentLocation)
                                  ? null
                                  : _save,
                              child: Text(context.l10n.save),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
