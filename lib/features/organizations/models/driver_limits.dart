import 'package:vitago_app/core/models/json_readers.dart';

class DriverLimits {
  const DriverLimits({
    required this.scope,
    required this.tubeLimit,
    required this.requestLimit,
    this.flaskLimit,
    this.companyId,
  });
  factory DriverLimits.fromJson(Map<String, dynamic> json) {
    final tubes = nullableInt(json, 'limite_tubos');
    final requests = nullableInt(json, 'limite_solicitudes');
    final flasks = nullableInt(json, 'limite_frascos');
    final scope = requireString(json, 'alcance');
    if (tubes == null ||
        tubes < 1 ||
        tubes > 2147483647 ||
        requests == null ||
        requests < 1 ||
        requests > 5 ||
        (flasks != null && (flasks < 1 || flasks > 2147483647)) ||
        !const {'EMPRESA', 'RED'}.contains(scope)) {
      throw const FormatException('Cupos incompletos o inválidos.');
    }
    return DriverLimits(
      scope: scope,
      companyId: optionalString(json, 'empresa_id'),
      tubeLimit: tubes,
      flaskLimit: flasks,
      requestLimit: requests,
    );
  }
  final String scope;
  final String? companyId;
  final int tubeLimit;
  final int? flaskLimit;
  final int requestLimit;
}

class UpdateDriverLimitsInput {
  const UpdateDriverLimitsInput({
    this.tubeLimit,
    this.flaskLimit,
    this.requestLimit,
    this.reason,
  });
  final int? tubeLimit;
  final int? flaskLimit;
  final int? requestLimit;
  final String? reason;
  Map<String, dynamic> toJson() => {
    'limite_tubos': ?tubeLimit,
    'limite_frascos': ?flaskLimit,
    'limite_solicitudes': ?requestLimit,
    if (reason?.trim().isNotEmpty == true) 'motivo': reason!.trim(),
  };
}
