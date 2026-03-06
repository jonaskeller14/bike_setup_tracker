import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:geocoding/geocoding.dart' as geo;

export 'package:geocoding/geocoding.dart';

class PlacemarkConverter extends TypeConverter<geo.Placemark, String> {
  const PlacemarkConverter();

  @override
  geo.Placemark fromSql(String fromDb) {
    final Map<String, dynamic> jsonMap = json.decode(fromDb);
    final int? version = jsonMap["version"];
    switch (version) {
      case null || 1:
        return geo.Placemark(
          name: jsonMap['name'],
          street: jsonMap['street'],
          isoCountryCode: jsonMap['isoCountryCode'],
          country: jsonMap['country'],
          postalCode: jsonMap['postalCode'],
          administrativeArea: jsonMap['administrativeArea'],
          subAdministrativeArea: jsonMap['subAdministrativeArea'],
          locality: jsonMap['locality'],
          subLocality: jsonMap['subLocality'],
          thoroughfare: jsonMap['thoroughfare'],
          subThoroughfare: jsonMap['subThoroughfare'],
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
