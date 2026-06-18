import 'package:geocoding/geocoding.dart' as geo;

class ContextPlace {
  const ContextPlace._();

  static Map<String, dynamic> toJson(geo.Placemark place) => {
    'name': place.name,
    'thoroughfare': place.thoroughfare,
    'subThoroughfare': place.subThoroughfare,
    'locality': place.locality,
    'subLocality': place.subLocality,
    'administrativeArea': place.administrativeArea,
    'subAdministrativeArea': place.subAdministrativeArea,
    'postalCode': place.postalCode,
    'country': place.country,
    'isoCountryCode': place.isoCountryCode,
  };

  static geo.Placemark fromJson(Map<String, dynamic> json) {
    return geo.Placemark(
      name: json['name'],
      thoroughfare: json['thoroughfare'],
      subThoroughfare: json['subThoroughfare'],
      locality: json['locality'],
      subLocality: json['subLocality'],
      administrativeArea: json['administrativeArea'],
      subAdministrativeArea: json['subAdministrativeArea'],
      postalCode: json['postalCode'],
      country: json['country'],
      isoCountryCode: json['isoCountryCode'],
    );
  }

  static bool equal(geo.Placemark? a, geo.Placemark? b) {
    return identical(a, b) ||
        a != null &&
        b != null &&
        a.name == b.name &&
        a.administrativeArea == b.administrativeArea &&
        a.country == b.country &&
        a.isoCountryCode == b.isoCountryCode &&
        a.locality == b.locality &&
        a.postalCode == b.postalCode &&
        a.subAdministrativeArea == b.subAdministrativeArea &&
        a.subLocality == b.subLocality &&
        a.subThoroughfare == b.subThoroughfare &&
        a.thoroughfare == b.thoroughfare;
  }
}