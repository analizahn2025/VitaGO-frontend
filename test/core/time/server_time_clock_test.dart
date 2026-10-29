import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/time/server_time_clock.dart';

void main() {
  test('estima UTC desde hora del servidor y tiempo monotónico', () {
    var elapsed = const Duration(seconds: 10);
    final clock = ServerTimeClock.withElapsedReader(() => elapsed);

    clock.synchronize(
      serverTime: DateTime.parse('2026-10-20T18:00:00+00:00'),
      operationalTimeZone: 'America/Tegucigalpa',
    );
    elapsed = const Duration(seconds: 17, milliseconds: 250);

    expect(clock.currentUtc(), DateTime.parse('2026-10-20T18:00:07.250Z'));
    expect(clock.operationalTimeZone, 'America/Tegucigalpa');
  });

  test('invalida el anclaje si el reloj monotónico pierde continuidad', () {
    var elapsed = const Duration(minutes: 2);
    final clock = ServerTimeClock.withElapsedReader(() => elapsed);
    clock.synchronize(
      serverTime: DateTime.parse('2026-10-20T18:00:00Z'),
      operationalTimeZone: 'America/Tegucigalpa',
    );

    elapsed = Duration.zero;

    expect(clock.currentUtc(), isNull);
    expect(clock.isSynchronized, isFalse);
    expect(clock.operationalTimeZone, isNull);
  });
}
