class RegionalDefaults {
  final String temperatureUnit;
  final String windSpeedUnit;
  final String altitudeUnit;
  final String precipitationUnit;
  final String distanceUnit;
  final String timeFormat;

  const RegionalDefaults({
    required this.temperatureUnit,
    required this.windSpeedUnit,
    required this.altitudeUnit,
    required this.precipitationUnit,
    required this.distanceUnit,
    required this.timeFormat,
  });

  // What the app used before the region mattered
  static const metric = RegionalDefaults(
    temperatureUnit: '°C',
    windSpeedUnit: 'km/h',
    altitudeUnit: 'm',
    precipitationUnit: 'mm',
    distanceUnit: 'km',
    timeFormat: 'HH:mm',
  );

  Map<String, String> get settings => {
    'temperatureUnit': temperatureUnit,
    'windSpeedUnit': windSpeedUnit,
    'altitudeUnit': altitudeUnit,
    'precipitationUnit': precipitationUnit,
    'distanceUnit': distanceUnit,
    'timeFormat': timeFormat,
  };

  RegionalDefaults copyWith({String? timeFormat}) => RegionalDefaults(
    temperatureUnit: temperatureUnit,
    windSpeedUnit: windSpeedUnit,
    altitudeUnit: altitudeUnit,
    precipitationUnit: precipitationUnit,
    distanceUnit: distanceUnit,
    timeFormat: timeFormat ?? this.timeFormat,
  );
}

const _usUnits = RegionalDefaults(
  temperatureUnit: '°F',
  windSpeedUnit: 'mph',
  altitudeUnit: 'ft',
  precipitationUnit: 'in',
  distanceUnit: 'mi',
  timeFormat: 'HH:mm',
);

const _ukUnits = RegionalDefaults(
  temperatureUnit: '°C',
  windSpeedUnit: 'mph',
  altitudeUnit: 'm',
  precipitationUnit: 'mm',
  distanceUnit: 'mi',
  timeFormat: 'HH:mm',
);

/// Starting values for the device's region (the country of its locale, not the
/// app language). The clock comes from the system setting, which no table can
/// know.
RegionalDefaults regionalDefaults(String? regionCode, {bool alwaysUse24HourFormat = true}) {
  final units = switch (regionCode?.toUpperCase()) {
    'US' || 'PR' || 'GU' || 'VI' || 'AS' || 'MP' => _usUnits,
    'GB' => _ukUnits,
    _ => RegionalDefaults.metric,
  };
  return units.copyWith(timeFormat: alwaysUse24HourFormat ? 'HH:mm' : 'h:mm a');
}
