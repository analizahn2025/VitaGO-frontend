import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/shifts/repositories/shifts_repository.dart';
import 'package:vitago_app/features/shifts/widgets/driver_lunch_section.dart';

void main() {
  testWidgets('Cuenta exige confirmación antes de iniciar almuerzo', (
    tester,
  ) async {
    final repository = _LunchRepository();
    await _pumpLunch(tester, repository);

    expect(find.text('Mi jornada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('start-lunch-account')));
    await tester.pumpAndSettle();
    expect(repository.startCalls, 0);
    expect(find.text('Confirmar almuerzo'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.startCalls, 0);

    await tester.tap(find.byKey(const Key('start-lunch-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar almuerzo'));
    await tester.pumpAndSettle();
    expect(repository.startCalls, 1);
    expect(find.byKey(const Key('finish-lunch-account')), findsOneWidget);

    await tester.tap(find.byKey(const Key('finish-lunch-account')));
    await tester.pumpAndSettle();
    expect(repository.finishCalls, 0);
    await tester.tap(find.text('Confirmar regreso'));
    await tester.pumpAndSettle();
    expect(repository.finishCalls, 1);
    expect(find.byKey(const Key('start-lunch-account')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oculta el almuerzo antes de publicar el contrato 0.42', (
    tester,
  ) async {
    await _pumpLunch(tester, _LunchRepository(), contractAvailable: false);
    expect(find.text('Mi jornada'), findsNothing);
    expect(find.text('Iniciar almuerzo'), findsNothing);
  });
}

Future<void> _pumpLunch(
  WidgetTester tester,
  _LunchRepository repository, {
  bool contractAvailable = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeShiftDayControllerProvider.overrideWith(
          (ref) async => ActiveShiftDay(
            shift: repository.shift,
            serverTime: DateTime.utc(2026, 10, 30, 14),
            scheduledCloseAt: DateTime.utc(2026, 10, 31, 4),
            canStartShift: contractAvailable ? false : null,
          ),
        ),
        activeShiftControllerProvider.overrideWith(
          (ref) async => repository.shift,
        ),
        ownDriverProfileControllerProvider.overrideWith(
          (ref) async => repository.driver,
        ),
        driverDeliveryControllerProvider.overrideWith(
          (ref) async => const DriverDeliveryBoard(inProgress: [], history: []),
        ),
        shiftActionsControllerProvider.overrideWithValue(
          ShiftActionsController(repository),
        ),
        myRouteProvider.overrideWith(
          (ref) async => throw const AppFailure(message: 'Ruta en pausa'),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverLunchSection(canUpdate: true),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _LunchRepository extends Fake implements ShiftsRepository {
  bool onLunch = false;
  int startCalls = 0;
  int finishCalls = 0;

  DriverShift get shift => DriverShift.fromJson({
    'id': 'jornada-1',
    'repartidor_id': 'motorista-1',
    'estado': 'ACTIVA',
    'iniciada_en': '2026-10-30T08:00:00-06:00',
    'puede_operar': !onLunch,
    'en_almuerzo': onLunch,
    'creado_en': '2026-10-30T08:00:00-06:00',
    'actualizado_en': '2026-10-30T08:00:00-06:00',
  });

  DriverProfile get driver => DriverProfile.fromJson({
    'id': 'motorista-1',
    'usuario': {
      'id': 'usuario-1',
      'correo': 'motorista@example.com',
      'nombres': 'Ana',
      'apellidos': 'Rivera',
      'estado': 'ACTIVO',
    },
    'estado_operativo': onLunch ? 'PAUSED' : 'AVAILABLE',
    'en_almuerzo': onLunch,
    'almuerzo_iniciado_en': onLunch ? '2026-10-30T12:00:00-06:00' : null,
    'capacidad': 'AVAILABLE',
    'activo': true,
    'creado_en': '2026-10-30T08:00:00-06:00',
    'actualizado_en': '2026-10-30T08:00:00-06:00',
  });

  @override
  Future<DriverShift> startLunch(String shiftId) async {
    startCalls++;
    onLunch = true;
    return shift;
  }

  @override
  Future<DriverShift> finishLunch(String shiftId) async {
    finishCalls++;
    onLunch = false;
    return shift;
  }
}
