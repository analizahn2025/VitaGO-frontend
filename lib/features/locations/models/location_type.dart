import 'package:vitago_app/core/models/json_readers.dart';

class LocationType {
  const LocationType({
    required this.id,
    required this.code,
    required this.name,
  });

  factory LocationType.fromJson(Map<String, dynamic> json) {
    return LocationType(
      id: requireString(json, 'id'),
      code: requireString(json, 'codigo'),
      name: requireString(json, 'nombre'),
    );
  }

  final String id;
  final String code;
  final String name;
}
