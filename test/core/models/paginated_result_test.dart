import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/models/paginated_result.dart';

void main() {
  test('interpreta la paginación documentada', () {
    final result = PaginatedResult<String>.fromJson({
      'conteo': 2,
      'pagina_siguiente': 'http://api.test/?pagina=2',
      'pagina_anterior': null,
      'resultados': [
        {'valor': 'uno'},
        {'valor': 'dos'},
      ],
    }, (json) => json['valor']! as String);

    expect(result.count, 2);
    expect(result.items, ['uno', 'dos']);
    expect(result.hasNext, isTrue);
    expect(result.hasPrevious, isFalse);
  });
}
