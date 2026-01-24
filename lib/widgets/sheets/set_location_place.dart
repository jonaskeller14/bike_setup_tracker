import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../services/address_service.dart';
import '../../services/elevation_service.dart';
import '../../services/location_service.dart';
import 'sheet.dart';

class LocationAndPlace {
  final LocationData? location;
  final geo.Placemark? place;
  const LocationAndPlace({required this.location, required this.place});
}

Future<LocationAndPlace?> showSetLocationPlaceSheet({
  required BuildContext context,
  required LocationService locationService,
  required LocationData? currentLocation,
  required AddressService addressService,
  required geo.Placemark? currentPlace,
}) async {
  return await showModalBottomSheet(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return SetLocationPlaceSheetContent(
        locationService: locationService,
        currentLocation: currentLocation,
        addressService: addressService,
        currentPlace: currentPlace,
      );
    }
  );
}

class SetLocationPlaceSheetContent extends StatefulWidget {
  final LocationService locationService;
  final LocationData? currentLocation;
  final AddressService addressService;
  final geo.Placemark? currentPlace;

  const SetLocationPlaceSheetContent({
    super.key,
    required this.locationService,
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
  String? _addressTextFieldErrorText;

  final ElevationService _elevationService = ElevationService();
  
  LocationData? _currentLocation;
  geo.Placemark? _currentPlace;

  @override
  void initState() {
    super.initState();

    _currentLocation = widget.currentLocation;
    _currentPlace = widget.currentPlace;
    _setFieldsFromLocationPlace();
  }

  void _setFieldsFromLocationPlace() {
    final appSettings = context.read<AppSettings>();

    _latitudeController.text = _currentLocation?.latitude?.toString() ?? "";
    _longitudeController.text = _currentLocation?.longitude?.toString() ?? "";
    _altitudeController.text = Setup.convertAltitudeFromMeters(_currentLocation?.altitude, appSettings.altitudeUnit)?.toString() ?? "";

    _addressController.text = _formatAddress(_currentPlace);
  }

  String _formatAddress(geo.Placemark? place) {
    if (place == null) return "";

    final street = place.thoroughfare?.isNotEmpty == true 
        ? "${place.thoroughfare} ${place.subThoroughfare ?? ""}".trim()
        : place.name;
    final city = place.locality ?? place.subLocality ?? "";
    final region = "${place.administrativeArea ?? ""} ${place.postalCode ?? ""}".trim();

    return [street, city, region, place.country]
        .where((s) => s != null && s.isNotEmpty)
        .join(", ");
  }

  void _updateLocationPlace() async {
    // LOCATION: Lat/Lon/Altitiude
    setState(() {
      _addressTextFieldErrorText = null;
    });
    final newLocation = await widget.locationService.fetchLocation();
    if (newLocation == null) return;
    setState(() {
      _currentLocation = newLocation;
      _setFieldsFromLocationPlace();
    });

    // 2: ADDRESS
    _updatePlace();
  }

  void _updatePlace() async {
    if (_currentLocation?.latitude == null || _currentLocation?.longitude == null) {
      setState(() {
        _addressTextFieldErrorText = "Could not find address without latitude and longitude";
      });
      return;
    }

    final newAddress = await widget.addressService.fetchAddress(lat: _currentLocation!.latitude!, lon: _currentLocation!.longitude!);
    setState(() {
      _currentPlace = newAddress;
      _setFieldsFromLocationPlace();
      _addressTextFieldErrorText = newAddress == null ? "No Address found" : null;
    });
  }

  void _searchAddress() async {
    // 1. LOCATION Lat/Lon
    final newLocation = await widget.locationService.locationFromAddress(_addressController.text.trim());
    if (newLocation == null) {
      setState(() {
        _addressTextFieldErrorText = "Could not find location.";
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
    final newAltitude = await _elevationService.fetchElevation(lat: _currentLocation!.latitude!, lon: _currentLocation!.longitude!);
    setState(() {
      _currentLocation = LocationService.copyWithLocationData(_currentLocation, altitude: newAltitude);
      _setFieldsFromLocationPlace();
    });

    // 3: ADDRESS
    _updatePlace();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(LocationAndPlace(
      location: _currentLocation, 
      place: _currentPlace
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    
    return ListenableBuilder(
      listenable: Listenable.merge([widget.locationService, widget.addressService, _elevationService]), 
      builder: (context, child) {
        final enableFields = widget.locationService.status != LocationStatus.searching && widget.addressService.status != AddressStatus.searching;
        final enableUpdate = widget.locationService.status != LocationStatus.searching && widget.addressService.status != AddressStatus.searching;
        final enableUpdatePlace = enableUpdate && _currentLocation?.latitude != null && _currentLocation?.longitude != null;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      sheetTitle(context, 'Location Context'),
                      sheetCloseButton(context),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.locationService.status == LocationStatus.noService)
                            ListTile(
                              leading: Icon(Icons.location_disabled, color: Theme.of(context).colorScheme.error),
                              title: const Text("Location services are disabled"),
                              subtitle: const Text("Please enable GPS in your device settings"),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          if (widget.locationService.status == LocationStatus.noPermission)
                            ListTile(
                              leading: Icon(Icons.location_disabled, color: Theme.of(context).colorScheme.error),
                              title: const Text("Location permission denied"),
                              subtitle: const Text("Grant permission in settings to use this feature"),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          if (_elevationService.status == ElevationStatus.error)
                            ListTile(
                              leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                              title: const Text("Fetching Elevation failed"),
                              subtitle: const Text("Check your internet connection"),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          if (widget.addressService.status == AddressStatus.error)
                            ListTile(
                              leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                              title: const Text("Fetching Address failed"),
                              subtitle: const Text("Check your internet connection and spelling"),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: enableFields,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
                            controller: _latitudeController,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: "Latitude",
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Latitude',
                              suffixText: "°",
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: _currentLocation?.latitude != widget.currentLocation?.latitude,
                              icon: const Icon(Icons.my_location),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final parsedValue = double.tryParse(value);
                              if (parsedValue == null) return "Please enter valid number";
                              if (parsedValue.abs() > 90) return "Latitude must be between -90..90°";
                              return null;
                            },
                            onChanged: (String newValue) {
                              setState(() {
                                _currentLocation = LocationService.copyWithLocationData(
                                  _currentLocation, 
                                  latitude: double.tryParse(newValue),
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: enableFields,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
                            controller: _longitudeController,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: "Longitude",
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Longitude',
                              suffixText: "°",
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: _currentLocation?.longitude != widget.currentLocation?.longitude,
                              icon: const Icon(Icons.my_location, color: Colors.transparent), // Placeholder
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final parsedValue = double.tryParse(value);
                              if (parsedValue == null) return "Please enter valid number";
                              if (parsedValue.abs() > 180) return "Longitude must be between -180..180°";
                              return null;
                            },
                            onChanged: (String newValue) {
                              setState(() {
                                _currentLocation = LocationService.copyWithLocationData(
                                  _currentLocation, 
                                  longitude: double.tryParse(newValue),
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            enabled: enableFields,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),],
                            controller: _altitudeController,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: "Altitude in ${appSettings.altitudeUnit}",
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Altitude',
                              suffixText: appSettings.altitudeUnit,
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: _currentLocation?.altitude != widget.currentLocation?.altitude,
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final parsedValue = double.tryParse(value);
                              if (parsedValue == null) return "Please enter valid number";
                              return null;
                            },
                            onChanged: (String newValue) {
                              setState(() {
                                _currentLocation = LocationService.copyWithLocationData(
                                  _currentLocation, 
                                  altitude: Setup.convertAltitudeToMeters(double.tryParse(newValue), appSettings.altitudeUnit),
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
                              label: const Text("Update Address from Latitude/Longitude"),
                            ),
                          ),
                          TextFormField(
                            enabled: enableFields,
                            textInputAction: TextInputAction.search,
                            controller: _addressController,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              labelText: "Enter street, city, or landmark and press Search Icon",
                              hintText: 'Address',
                              contentPadding: const EdgeInsets.all(8),
                              errorText: _addressTextFieldErrorText,
                              icon: const Icon(Icons.location_city),
                              suffixIcon: IconButton(
                                onPressed: () => _searchAddress(), 
                                icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                              ),
                              fillColor: Colors.orange.withValues(alpha: 0.08),
                              filled: !Setup.placeEqual(widget.currentPlace, _currentPlace),
                            ),
                            validator: null,
                            onFieldSubmitted: (value) {
                              () => _searchAddress();
                            },
                          ),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    spacing: 8,
                    children: [ 
                      Flexible(
                        flex: 2,
                        fit: FlexFit.tight,
                        child: OutlinedButton.icon(
                          onPressed: enableUpdate ? _updateLocationPlace : null,
                          icon: widget.locationService.status == LocationStatus.searching || widget.addressService.status == AddressStatus.searching 
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ) 
                              : const Icon(Icons.my_location),
                          label: const Text("Find Location via GPS"),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: FilledButton(
                          onPressed: _save,
                          child: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}