import 'package:vitago_app/core/models/json_readers.dart';

class AssignableRole {
  const AssignableRole({required this.code, required this.name});

  factory AssignableRole.fromJson(Map<String, dynamic> json) {
    return AssignableRole(
      code: requireString(json, 'codigo'),
      name: requireString(json, 'nombre'),
    );
  }

  final String code;
  final String name;
}
