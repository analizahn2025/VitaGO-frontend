class UpdateUserInput {
  const UpdateUserInput({
    required this.firstNames,
    required this.lastNames,
    required this.status,
    this.phone,
  });

  final String firstNames;
  final String lastNames;
  final String? phone;
  final String status;

  Map<String, dynamic> toJson() => {
    'nombres': firstNames.trim(),
    'apellidos': lastNames.trim(),
    'telefono': _nullable(phone),
    'estado': status,
  };

  static String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
