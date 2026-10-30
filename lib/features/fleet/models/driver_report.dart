import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/features/fleet/models/driver_load_snapshot.dart';

String? operationalDateError(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) || text == '9999-12-31') {
    return 'Usa una fecha válida con formato AAAA-MM-DD.';
  }
  final parsed = DateTime.tryParse(text);
  return parsed != null &&
          parsed.year >= 1 &&
          parsed.toIso8601String().startsWith(text)
      ? null
      : 'La fecha no existe.';
}

class DriverReportQuery {
  const DriverReportQuery({
    this.date,
    this.companyId,
    this.driverId,
    this.active,
    this.page = 1,
  });
  final String? date, companyId, driverId;
  final bool? active;
  final int page;
  Map<String, dynamic> toJson() => {
    if (date?.isNotEmpty == true) 'fecha_operativa': date,
    'empresa_id': ?companyId,
    'repartidor_id': ?driverId,
    'activo': ?active,
    'pagina': page,
    'tamano_pagina': 20,
  };
  @override
  bool operator ==(Object other) =>
      other is DriverReportQuery &&
      other.date == date &&
      other.companyId == companyId &&
      other.driverId == driverId &&
      other.active == active &&
      other.page == page;
  @override
  int get hashCode => Object.hash(date, companyId, driverId, active, page);
}

class DriverTemperatureReading {
  const DriverTemperatureReading({
    required this.id,
    required this.requestId,
    required this.number,
    required this.capturedAt,
    this.temperature,
    this.source,
  });
  factory DriverTemperatureReading.fromJson(Map<String, dynamic> json) =>
      DriverTemperatureReading(
        id: requireString(json, 'id'),
        requestId: requireString(json, 'solicitud_id'),
        number: requireString(json, 'numero_solicitud'),
        capturedAt: requireDateTime(json, 'capturada_en'),
        temperature: optionalString(json, 'temperatura_contenedor_c'),
        source: optionalString(json, 'fuente_temperatura'),
      );
  final String id, requestId, number;
  final DateTime capturedAt;
  final String? temperature, source;
}

class DriverDailyReport {
  DriverDailyReport.fromJson(Map<String, dynamic> json) {
    final driver = requireJsonMap(json['repartidor'], 'repartidor');
    driverId = requireString(driver, 'id');
    name =
        '${requireString(driver, 'nombres')} ${requireString(driver, 'apellidos')}'
            .trim();
    companyId = optionalString(driver, 'empresa_id');
    companyName = optionalString(driver, 'empresa_nombre');
    active = optionalBool(driver, 'activo');
    date = requireString(json, 'fecha_operativa');
    zone = requireString(json, 'zona_horaria_operativa');
    generatedAt = requireDateTime(json, 'generado_en');
    final period = requireJsonMap(json['periodo'], 'periodo');
    periodStart = requireDateTime(period, 'desde');
    periodEnd = requireDateTime(period, 'hasta_exclusivo');
    final requests = requireJsonMap(json['solicitudes'], 'solicitudes');
    assigned = optionalInt(requests, 'asignadas');
    pickedUp = optionalInt(requests, 'recolectadas');
    delivered = optionalInt(requests, 'entregadas');
    failed = optionalInt(requests, 'fallidas');
    cancelled = optionalInt(requests, 'canceladas');
    final tubes = requireJsonMap(json['tubos'], 'tubos');
    knownPickedTubes = optionalInt(tubes, 'recogidos_conocidos');
    knownDeliveredTubes = optionalInt(tubes, 'entregados_conocidos');
    pickupsWithoutTubes = optionalInt(tubes, 'recolecciones_sin_cantidad');
    deliveriesWithoutTubes = optionalInt(tubes, 'entregas_sin_cantidad');
    final flasks = optionalJsonMap(json, 'frascos');
    knownPickedFlasks = flasks == null
        ? null
        : nullableInt(flasks, 'recogidos_conocidos');
    knownDeliveredFlasks = flasks == null
        ? null
        : nullableInt(flasks, 'entregados_conocidos');
    pickupsWithoutFlasks = flasks == null
        ? null
        : nullableInt(flasks, 'recolecciones_sin_cantidad');
    deliveriesWithoutFlasks = flasks == null
        ? null
        : nullableInt(flasks, 'entregas_sin_cantidad');
    final mileage = requireJsonMap(json['kilometraje'], 'kilometraje');
    measuredKm = optionalString(mileage, 'kilometros_medidos');
    consolidatedKm = optionalString(mileage, 'kilometros_consolidados');
    completeMileage = optionalBool(mileage, 'completo');
    closedShifts = optionalInt(mileage, 'jornadas_cerradas');
    measuredShifts = optionalInt(mileage, 'jornadas_con_medicion');
    consolidatedShifts = optionalInt(mileage, 'jornadas_consolidadas');
    unclosedShifts = optionalInt(mileage, 'jornadas_sin_cierre_en_periodo');
    final temperatures = requireJsonMap(json['temperaturas'], 'temperaturas');
    minC = optionalString(temperatures, 'minima_c');
    maxC = optionalString(temperatures, 'maxima_c');
    averageC = optionalString(temperatures, 'promedio_c');
    readings = optionalInt(temperatures, 'lecturas_registradas');
    readingsWithTemperature = optionalInt(
      temperatures,
      'lecturas_con_temperatura',
    );
    readingsWithoutTemperature = optionalInt(
      temperatures,
      'lecturas_sin_temperatura',
    );
    recentReadings = jsonMapList(
      temperatures['ultimas_lecturas'],
      'ultimas_lecturas',
    ).map(DriverTemperatureReading.fromJson).toList(growable: false);
    currentLoad = DriverLoadSnapshot.fromJson(
      requireJsonMap(json['carga_actual'], 'carga_actual'),
    );
  }
  late final String driverId, name, date, zone;
  late final String? companyId,
      companyName,
      measuredKm,
      consolidatedKm,
      minC,
      maxC,
      averageC;
  late final bool active, completeMileage;
  late final DateTime periodStart, periodEnd, generatedAt;
  late final int assigned,
      pickedUp,
      delivered,
      failed,
      cancelled,
      knownPickedTubes,
      knownDeliveredTubes,
      pickupsWithoutTubes,
      deliveriesWithoutTubes,
      closedShifts,
      measuredShifts,
      consolidatedShifts,
      unclosedShifts,
      readings,
      readingsWithTemperature,
      readingsWithoutTemperature;
  late final List<DriverTemperatureReading> recentReadings;
  late final int? knownPickedFlasks,
      knownDeliveredFlasks,
      pickupsWithoutFlasks,
      deliveriesWithoutFlasks;
  late final DriverLoadSnapshot currentLoad;
}
