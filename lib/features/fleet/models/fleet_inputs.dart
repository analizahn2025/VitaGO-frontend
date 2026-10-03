class CreateVehicleInput {
  const CreateVehicleInput({
    required this.plate,
    required this.type,
    required this.status,
    this.companyId,
    this.brand,
    this.model,
    this.year,
    this.notes,
  });

  final String? companyId;
  final String plate;
  final String type;
  final String? brand;
  final String? model;
  final int? year;
  final String status;
  final String? notes;

  Map<String, dynamic> toJson({required bool isCorporate}) => {
    if (isCorporate) 'empresa_id': companyId,
    'placa': plate.trim().toUpperCase(),
    'tipo': type,
    'marca': _nullable(brand),
    'modelo': _nullable(model),
    'anio': year,
    'estado': status,
    'notas': _nullable(notes),
  };
}

class CreateDriverInput {
  const CreateDriverInput({
    required this.userId,
    required this.vehicleId,
    this.companyId,
  });

  final String userId;
  final String? companyId;
  final String vehicleId;

  Map<String, dynamic> toJson({required bool isCorporate}) => {
    'usuario_id': userId,
    if (isCorporate) 'empresa_id': companyId,
    'vehiculo_id': vehicleId,
  };
}

class UpdateDriverOperationInput {
  const UpdateDriverOperationInput({this.operationalStatus, this.reason});

  final String? operationalStatus;
  final String? reason;

  Map<String, dynamic> toJson() => {
    if (operationalStatus != null) 'estado_operativo': operationalStatus,
    'motivo': _nullable(reason),
  };
}

String? _nullable(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
