import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:geocoding/geocoding.dart' as geo;

export 'package:geocoding/geocoding.dart';

class PlacemarkConverter extends TypeConverter<geo.Placemark, String> {
  const PlacemarkConverter();

  @override
  geo.Placemark fromSql(String fromDb) {
    final Map<String, dynamic> jsonMap = json.decode(fromDb) as Map<String, dynamic>;
    final int? version = jsonMap["version"] as int?;
    switch (version) {
      case null || 1:
        return geo.Placemark(
          name: jsonMap['name'] as String?,
          street: jsonMap['street'] as String?,
          isoCountryCode: jsonMap['isoCountryCode'] as String?,
          country: jsonMap['country'] as String?,
          postalCode: jsonMap['postalCode'] as String?,
          administrativeArea: jsonMap['administrativeArea'] as String?,
          subAdministrativeArea: jsonMap['subAdministrativeArea'] as String?,
          locality: jsonMap['locality'] as String?,
          subLocality: jsonMap['subLocality'] as String?,
          thoroughfare: jsonMap['thoroughfare'] as String?,
          subThoroughfare: jsonMap['subThoroughfare'] as String?,
        );
      default:
        throw Exception("Json Version $version of Placemark incompatible.");
    }
  }

  @override
  String toSql(geo.Placemark value) {
    return json.encode({
      'version': 1,
      'name': value.name,
      'street': value.street,
      'isoCountryCode': value.isoCountryCode,
      'country': value.country,
      'postalCode': value.postalCode,
      'administrativeArea': value.administrativeArea,
      'subAdministrativeArea': value.subAdministrativeArea,
      'locality': value.locality,
      'subLocality': value.subLocality,
      'thoroughfare': value.thoroughfare,
      'subThoroughfare': value.subThoroughfare,
    });
  }
}
