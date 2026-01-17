import 'package:flutter/material.dart';
import 'sheet.dart';

enum UpdateLocationAddressWeatherOptions {
  locationByGPS,
  addressByLocation,
  updateWeather,
}

Future<UpdateLocationAddressWeatherOptions?> showUpdateLocationAddressWeatherSheet(
  BuildContext context, {
  Map<UpdateLocationAddressWeatherOptions, bool> buttonsEnabled = const {
    UpdateLocationAddressWeatherOptions.locationByGPS: true, 
    UpdateLocationAddressWeatherOptions.addressByLocation: true, 
    UpdateLocationAddressWeatherOptions.updateWeather: true
  },
}) async {
  return showModalBottomSheet<UpdateLocationAddressWeatherOptions?>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    sheetTitle(context, 'Update?'),
                    sheetCloseButton(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("Choose the type of update you would like to perform:"),
                dense: true,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text("1. Find location via GPS"),
                subtitle: const Text("Use device GPS sensor to fetch latitude, longitude, and altitude."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.of(context).pop(UpdateLocationAddressWeatherOptions.locationByGPS),
                enabled: buttonsEnabled[UpdateLocationAddressWeatherOptions.locationByGPS]!,
              ),
              ListTile(
                leading: const Icon(Icons.location_city),
                title: const Text("2. Update Address from location"),
                subtitle: const Text("Requires lat/lon to retrieve street address."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.of(context).pop(UpdateLocationAddressWeatherOptions.addressByLocation),
                enabled: buttonsEnabled[UpdateLocationAddressWeatherOptions.addressByLocation]!,
              ),
              ListTile(
                leading: const Icon(Icons.cloudy_snowing),
                title: const Text("3. Update Weather"),
                subtitle: const Text("Requires lat/lon to retrieve weather."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.of(context).pop(UpdateLocationAddressWeatherOptions.updateWeather),
                enabled: buttonsEnabled[UpdateLocationAddressWeatherOptions.updateWeather]!,
              ),
            ],
          ),
        ),
      );
    },
  );
}
