import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/fleet/models/fleet_inputs.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';

void main() {
  Map<String, dynamic> vehicleJson() => {
    'id': 'vehicle-id',
    'empresa_id': 'company-id',
    'placa': 'HAA-1234',
    'tipo': 'MOTOCICLETA',
    'marca': 'Honda',
    'modelo': 'Cargo',
    'anio': 2025,
    'capacidad_carga_kg': '35.50',
    'estado': 'ACTIVO',
    'notas': null,
    'creado_en': '2026-09-28T08:00:00-06:00',
    'actualizado_en': '2026-09-28T08:00:00-06:00',
  };

  test('interpreta vehículo con campos opcionales', () {
    final vehicle = Vehicle.fromJson(vehicleJson());

    expect(vehicle.plate, 'HAA-1234');
    expect(vehicle.loadCapacityKg, '35.50');
    expect(vehicle.notes, isNull);
    expect(vehicle.displayName, contains('Honda Cargo'));
  });

  test('interpreta motorista con vehículo anidado', () {
    final driver = DriverProfile.fromJson({
      'id': 'driver-id',
      'usuario': {
        'id': 'user-id',
        'correo': 'motorista@vitago.test',
        'nombres': 'Ana',
        'apellidos': 'López',
        'telefono': null,
        'estado': 'ACTIVO',
      },
      'empresa_id': 'company-id',
      'vehiculo': vehicleJson(),
      'estado_operativo': 'AVAILABLE',
      'capacidad': 'AVAILABLE_SPACE',
      'solicitudes_activas': 2,
      'limite_solicitudes': 5,
      'puede_recibir_solicitudes': true,
      'activo': true,
      'creado_en': '2026-09-28T08:00:00-06:00',
      'actualizado_en': '2026-09-28T08:10:00-06:00',
    });

    expect(driver.user.fullName, 'Ana López');
    expect(driver.vehicle?.plate, 'HAA-1234');
    expect(driver.operationalStatus, 'AVAILABLE');
    expect(driver.activeRequests, 2);
    expect(driver.requestLimit, 5);
    expect(driver.canReceiveRequests, isTrue);
    expect(driver.active, isTrue);
  });

  test('acepta motorista sin vehículo', () {
    final driver = DriverProfile.fromJson({
      'id': 'driver-id',
      'usuario': {
        'id': 'user-id',
        'correo': 'motorista@vitago.test',
        'nombres': 'Ana',
        'apellidos': 'López',
        'telefono': null,
        'estado': 'ACTIVO',
      },
      'empresa_id': null,
      'vehiculo': null,
      'estado_operativo': 'OFFLINE',
      'capacidad': 'EMPTY',
      'activo': false,
      'creado_en': '2026-09-28T08:00:00-06:00',
      'actualizado_en': '2026-09-28T08:10:00-06:00',
    });

    expect(driver.companyId, isNull);
    expect(driver.vehicle, isNull);
    expect(driver.active, isFalse);
  });

  test('incluye empresa al crear vehículo corporate y la omite en network', () {
    const input = CreateVehicleInput(
      companyId: 'company-id',
      plate: ' haa-1234 ',
      type: 'MOTOCICLETA',
      status: 'ACTIVO',
    );

    expect(input.toJson(isCorporate: true)['empresa_id'], 'company-id');
    expect(input.toJson(isCorporate: true)['placa'], 'HAA-1234');
    expect(
      input.toJson(isCorporate: true).containsKey('capacidad_carga_kg'),
      isFalse,
    );
    expect(input.toJson(isCorporate: false).containsKey('empresa_id'), isFalse);
  });

  test('incluye empresa al registrar motorista solo en corporate', () {
    const input = CreateDriverInput(
      userId: 'user-id',
      companyId: 'company-id',
      vehicleId: 'vehicle-id',
    );

    expect(input.toJson(isCorporate: true), {
      'usuario_id': 'user-id',
      'empresa_id': 'company-id',
      'vehiculo_id': 'vehicle-id',
    });
    expect(input.toJson(isCorporate: false), {
      'usuario_id': 'user-id',
      'vehiculo_id': 'vehicle-id',
    });
  });

  test('serializa actualización operativa', () {
    const input = UpdateDriverOperationInput(
      operationalStatus: 'PAUSED',
      reason: 'Descanso programado',
    );

    expect(input.toJson(), {
      'estado_operativo': 'PAUSED',
      'motivo': 'Descanso programado',
    });
  });

  test('omite campos operativos que el motorista no modificó', () {
    const input = UpdateDriverOperationInput(reason: 'Espacio liberado');

    expect(input.toJson(), {'motivo': 'Espacio liberado'});
  });
}
