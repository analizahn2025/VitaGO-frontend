import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';

class UserRoleAssignment {
  const UserRoleAssignment({
    required this.id,
    required this.role,
    required this.scopeType,
    required this.active,
    required this.assignedAt,
    this.companyId,
    this.branchId,
    this.assignedById,
    this.revokedById,
    this.revokedAt,
  });

  factory UserRoleAssignment.fromJson(Map<String, dynamic> json) {
    final roleJson = requireJsonMap(json['rol'], 'rol');
    return UserRoleAssignment(
      id: requireString(json, 'id'),
      role: UserRoleDefinition.fromJson(roleJson),
      scopeType: ScopeType.parse(requireString(json, 'tipo_alcance')),
      companyId: optionalString(json, 'empresa_id'),
      branchId: optionalString(json, 'sucursal_id'),
      active: json['activo'] == true,
      assignedById: optionalString(json, 'asignado_por_id'),
      assignedAt: DateTime.parse(requireString(json, 'asignado_en')).toLocal(),
      revokedById: optionalString(json, 'revocado_por_id'),
      revokedAt: _optionalDate(json, 'revocado_en'),
    );
  }

  final String id;
  final UserRoleDefinition role;
  final ScopeType scopeType;
  final String? companyId;
  final String? branchId;
  final bool active;
  final String? assignedById;
  final DateTime assignedAt;
  final String? revokedById;
  final DateTime? revokedAt;

  static DateTime? _optionalDate(Map<String, dynamic> json, String key) {
    final value = optionalString(json, key);
    return value == null ? null : DateTime.parse(value).toLocal();
  }
}

class UserRoleDefinition {
  const UserRoleDefinition({
    required this.code,
    required this.name,
    required this.allowsGlobalScope,
    required this.allowsCompanyScope,
    required this.allowsBranchScope,
    this.description,
  });

  factory UserRoleDefinition.fromJson(Map<String, dynamic> json) {
    return UserRoleDefinition(
      code: requireString(json, 'codigo'),
      name: requireString(json, 'nombre'),
      description: optionalString(json, 'descripcion'),
      allowsGlobalScope: json['permite_alcance_global'] == true,
      allowsCompanyScope: json['permite_alcance_empresa'] == true,
      allowsBranchScope: json['permite_alcance_sucursal'] == true,
    );
  }

  final String code;
  final String name;
  final String? description;
  final bool allowsGlobalScope;
  final bool allowsCompanyScope;
  final bool allowsBranchScope;
}

class AssignUserRoleInput {
  const AssignUserRoleInput({
    required this.roleCode,
    required this.scopeType,
    this.companyId,
    this.branchId,
  });

  final String roleCode;
  final ScopeType scopeType;
  final String? companyId;
  final String? branchId;

  Map<String, dynamic> toJson() => {
    'rol_codigo': roleCode,
    'tipo_alcance': scopeType.apiValue,
    'empresa_id': scopeType == ScopeType.global ? null : companyId,
    'sucursal_id': scopeType == ScopeType.branch ? branchId : null,
  };
}
