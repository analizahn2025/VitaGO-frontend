import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/core/models/scoped_role.dart';

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.firstNames,
    required this.lastNames,
    required this.status,
    required this.roles,
    this.phone,
    this.companyId,
    this.branchId,
    this.createdAt,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final rawRoles = jsonMapList(json['roles'] ?? const [], 'roles');
    final createdAtText = optionalString(json, 'creado_en');
    return ManagedUser(
      id: requireString(json, 'id'),
      email: requireString(json, 'correo'),
      firstNames: requireString(json, 'nombres'),
      lastNames: requireString(json, 'apellidos'),
      phone: optionalString(json, 'telefono'),
      companyId: optionalString(json, 'empresa_id'),
      branchId: optionalString(json, 'sucursal_id'),
      status: requireString(json, 'estado'),
      roles: rawRoles.map(ScopedRole.fromJson).toList(growable: false),
      createdAt: createdAtText == null
          ? null
          : DateTime.tryParse(createdAtText)?.toLocal(),
    );
  }

  final String id;
  final String email;
  final String firstNames;
  final String lastNames;
  final String? phone;
  final String? companyId;
  final String? branchId;
  final String status;
  final List<ScopedRole> roles;
  final DateTime? createdAt;

  String get fullName => '$firstNames $lastNames'.trim();
}
