import 'package:vitago_app/core/models/json_readers.dart';

class PaginatedResult<T> {
  const PaginatedResult({
    required this.count,
    required this.items,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = jsonMapList(json['resultados'], 'resultados');
    return PaginatedResult(
      count: optionalInt(json, 'conteo', fallback: rawItems.length),
      items: rawItems.map(itemFromJson).toList(growable: false),
      hasNext: json['pagina_siguiente'] != null,
      hasPrevious: json['pagina_anterior'] != null,
    );
  }

  final int count;
  final List<T> items;
  final bool hasNext;
  final bool hasPrevious;
}
