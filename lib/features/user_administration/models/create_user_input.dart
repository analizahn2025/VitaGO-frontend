import 'package:vitago_app/core/permissions/scope_type.dart';

class CreateUserInput {
  const CreateUserInput({
    required this.email,
    required this.firstNames,
    required this.lastNames,
    required this.roleCode,
    required this.scopeType,
    this.phone,
    this.temporaryPassword,
    this.externalAuthenticationId,
    this.companyId,
    this.branchId,
  });

  final String email;
  final String firstNames;
  final String lastNames;
  final String? phone;
  final String? temporaryPassword;
  final String? externalAuthenticationId;
  final String roleCode;
  final ScopeType scopeType;
  final String? companyId;
  final String? branchId;

  Map<String, dynamic> toJson({required bool usesLocalAuthentication}) {
    final data = <String, dynamic>{
      'correo': email.trim(),
      'nombres': firstNames.trim(),
      'apellidos': lastNames.trim(),
      'telefono': _nullable(phone),
      'rol_codigo': roleCode,
      'tipo_alcance': scopeType.apiValue,
      if (scopeType != ScopeType.global) 'empresa_id': companyId,
      if (scopeType == ScopeType.branch) 'sucursal_id': branchId,
    };

    if (usesLocalAuthentication) {
      data['contrasena_temporal'] = temporaryPassword;
    } else {
      data['identificador_autenticacion_externa'] = externalAuthenticationId;
    }
    return data;
  }

  static String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class AssignableRolesQuery {
  const AssignableRolesQuery({
    required this.scopeType,
    this.companyId,
    this.branchId,
  });

  final ScopeType scopeType;
  final String? companyId;
  final String? branchId;

  Map<String, dynamic> toQueryParameters() => {
    'tipo_alcance': scopeType.apiValue,
    if (scopeType != ScopeType.global) 'empresa_id': companyId,
    if (scopeType == ScopeType.branch) 'sucursal_id': branchId,
  };

  @override
  bool operator ==(Object other) {
    return other is AssignableRolesQuery &&
        other.scopeType == scopeType &&
        other.companyId == companyId &&
        other.branchId == branchId;
  }

  @override
  int get hashCode => Object.hash(scopeType, companyId, branchId);
}
