Map<String, dynamic> requireJsonMap(Object? value, String context) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw FormatException('$context no tiene el formato esperado.');
}

String requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  throw FormatException('El campo $key no está presente en la respuesta.');
}

String? optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool optionalBool(
  Map<String, dynamic> json,
  String key, {
  bool fallback = false,
}) {
  final value = json[key];
  return value is bool ? value : fallback;
}

int optionalInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime requireDateTime(Map<String, dynamic> json, String key) {
  final raw = requireString(json, key);
  final value = DateTime.tryParse(raw);
  if (value == null) {
    throw FormatException('El campo $key no contiene una fecha válida.');
  }
  return value;
}

DateTime? optionalDateTime(Map<String, dynamic> json, String key) {
  final raw = optionalString(json, key);
  if (raw == null) return null;
  final value = DateTime.tryParse(raw);
  if (value == null) {
    throw FormatException('El campo $key no contiene una fecha válida.');
  }
  return value;
}

Map<String, dynamic>? optionalJsonMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  return requireJsonMap(value, key);
}

List<Map<String, dynamic>> jsonMapList(Object? value, String context) {
  if (value is! List) {
    throw FormatException('$context no contiene una lista válida.');
  }
  return value
      .map((item) => requireJsonMap(item, context))
      .toList(growable: false);
}
