import 'package:geocoding/geocoding.dart' as geo;
import '../../utils/text_search.dart';

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
      name: json['name'] as String?,
      thoroughfare: json['thoroughfare'] as String?,
      subThoroughfare: json['subThoroughfare'] as String?,
      locality: json['locality'] as String?,
      subLocality: json['subLocality'] as String?,
      administrativeArea: json['administrativeArea'] as String?,
      subAdministrativeArea: json['subAdministrativeArea'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      isoCountryCode: json['isoCountryCode'] as String?,
    );
  }

  static bool matches(geo.Placemark? place, String query) {
    if (place == null) return false;
    return searchFieldsMatch(searchableFields(place), tokenizeSearchQuery(query));
  }

  static Iterable<String?> searchableFields(geo.Placemark? place) {
    if (place == null) return const [];
    return [
      place.name,
      place.thoroughfare,
      place.subThoroughfare,
      place.locality,
      place.subLocality,
      place.administrativeArea,
      place.subAdministrativeArea,
      place.postalCode,
      place.country,
      place.isoCountryCode,
    ];
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
