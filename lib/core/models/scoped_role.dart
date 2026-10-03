import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';

class ScopedRole {
  const ScopedRole({
    required this.code,
    required this.name,
    required this.scopeType,
    this.companyId,
    this.branchId,
  });

  factory ScopedRole.fromJson(Map<String, dynamic> json) {
    return ScopedRole(
      code: requireString(json, 'codigo'),
      name: requireString(json, 'nombre'),
      scopeType: ScopeType.parse(requireString(json, 'tipo_alcance')),
      companyId: optionalString(json, 'empresa_id'),
      branchId: optionalString(json, 'sucursal_id'),
    );
  }

  final String code;
  final String name;
  final ScopeType scopeType;
  final String? companyId;
  final String? branchId;
}
