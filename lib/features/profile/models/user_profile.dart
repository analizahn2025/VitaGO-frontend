import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/core/models/scoped_role.dart';
import 'package:vitago_app/core/permissions/app_roles.dart';

class UserProfile {
  UserProfile({
    required this.user,
    required this.roles,
    required Iterable<String> permissions,
    this.company,
    this.branch,
  }) : permissions = Set.unmodifiable(permissions);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final userJson = requireJsonMap(json['usuario'], 'usuario');
    final companyJson = optionalJsonMap(json, 'empresa');
    final branchJson = optionalJsonMap(json, 'sucursal');
    final rawRoles = jsonMapList(json['roles'] ?? const [], 'roles');
    final rawPermissions = json['permisos'];
    if (rawPermissions is! List) {
      throw const FormatException('permisos no contiene una lista válida.');
    }

    return UserProfile(
      user: ProfileUser.fromJson(userJson),
      company: companyJson == null
          ? null
          : ProfileOrganization.fromJson(companyJson),
      branch: branchJson == null
          ? null
          : ProfileOrganization.fromJson(branchJson),
      roles: rawRoles.map(ScopedRole.fromJson).toList(growable: false),
      permissions: rawPermissions
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty),
    );
  }

  final ProfileUser user;
  final ProfileOrganization? company;
  final ProfileOrganization? branch;
  final List<ScopedRole> roles;
  final Set<String> permissions;

  bool can(String permission) => permissions.contains(permission);

  bool get isMasterAdmin =>
      roles.any((role) => role.code.toUpperCase() == AppRoles.masterAdmin);

  bool get isDriver => roles.any((role) {
    final code = role.code.toUpperCase();
    return code == 'REPARTIDOR_CORPORATIVO' || code == 'REPARTIDOR_RED';
  });
}

class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.email,
    required this.firstNames,
    required this.lastNames,
    required this.status,
    this.phone,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: requireString(json, 'id'),
      email: requireString(json, 'correo'),
      firstNames: requireString(json, 'nombres'),
      lastNames: requireString(json, 'apellidos'),
      phone: optionalString(json, 'telefono'),
      status: requireString(json, 'estado'),
    );
  }

  final String id;
  final String email;
  final String firstNames;
  final String lastNames;
  final String? phone;
  final String status;

  String get fullName => '$firstNames $lastNames'.trim();
}

class ProfileOrganization {
  const ProfileOrganization({required this.id, required this.name});

  factory ProfileOrganization.fromJson(Map<String, dynamic> json) {
    return ProfileOrganization(
      id: requireString(json, 'id'),
      name: requireString(json, 'nombre'),
    );
  }

  final String id;
  final String name;
}
