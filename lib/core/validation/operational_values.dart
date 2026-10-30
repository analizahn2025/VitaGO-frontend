String? tubeCountError(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Indica la cantidad de tubos.';
  final count = RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) : null;
  return count != null && count >= 1 && count <= 2147483647
      ? null
      : 'Usa un entero entre 1 y 2147483647.';
}

String? nonNegativeContainerCountError(String? value, String label) {
  final text = value?.trim() ?? '';
  final count = RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) : null;
  return count != null && count <= 2147483647
      ? null
      : 'Indica $label con un entero entre 0 y 2147483647.';
}

String? containerLoadError(String? tubes, String? flasks) {
  final tubeCount = int.tryParse(tubes?.trim() ?? '');
  final flaskCount = int.tryParse(flasks?.trim() ?? '');
  return tubeCount == 0 && flaskCount == 0
      ? 'Indica al menos un tubo o un frasco.'
      : null;
}

String normalizeTemperature(String value) => value.trim().replaceAll(',', '.');

String? containerTemperatureError(String? value) {
  final text = normalizeTemperature(value ?? '');
  if (text.isEmpty) return 'Indica la temperatura del contenedor.';
  return RegExp(r'^[+-]?\d{1,4}(\.\d{1,2})?$').hasMatch(text)
      ? null
      : 'Usa un valor entre -9999.99 y 9999.99, con hasta dos decimales.';
}
