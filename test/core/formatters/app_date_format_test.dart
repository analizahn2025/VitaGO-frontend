import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';

void main() {
  test('muestra la hora UTC en la zona operativa del backend', () {
    final value = DateTime.parse('2026-10-20T18:00:00Z');

    expect(
      AppDateFormat.dateTime(value, timeZone: 'America/Tegucigalpa'),
      '20/10/2026 12:00',
    );
  });
}
