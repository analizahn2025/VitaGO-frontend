import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/requests/models/request_creation_options.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';

void main() {
  Map<String, dynamic> requestJson() => {
    'id': 'request-id',
    'numero': 'SOL-0001',
    'empresa_id': 'company-id',
    'sucursal_id': null,
    'solicitada_por_id': 'user-id',
    'repartidor_asignado_id': 'driver-id',
    'prioridad': 'PRIORITY',
    'modalidad': 'ENTRE_SUCURSALES',
    'tipo_servicio': {
      'id': 'service-id',
      'codigo': 'MEDICAMENTOS',
      'nombre': 'Medicamentos',
      'descripcion': null,
    },
    'origen': {
      'id': 'origin-id',
      'nombre': 'Centro médico',
      'direccion': 'Tegucigalpa',
      'latitud': '14.100000',
      'longitud': '-87.200000',
    },
    'destino': {
      'id': 'destination-id',
      'nombre': 'Hospital',
      'direccion': 'Comayagüela',
      'latitud': null,
      'longitud': null,
    },
    'destino_especial': null,
    'presentacion_ruta': 'MAPA',
    'kilometros_envio_especial': null,
    'estado': 'ASSIGNED',
    'creado_en': '2026-09-28T08:00:00-06:00',
  };

  test('interpreta el resumen exacto de una solicitud', () {
    final request = ServiceRequestSummary.fromJson(requestJson());

    expect(request.number, 'SOL-0001');
    expect(request.branchId, isNull);
    expect(request.isPriority, isTrue);
    expect(request.serviceType.name, 'Medicamentos');
    expect(request.origin.latitude, '14.100000');
    expect(request.destination?.longitude, isNull);
    expect(request.modality, RequestModalities.betweenBranches);
    expect(request.isTerminal, isFalse);
    expect(request.status, 'ASSIGNED');
    expect(request.assignedDriverId, 'driver-id');
  });

  test('interpreta detalle, artículos, eventos y asignaciones', () {
    final json = requestJson()
      ..addAll({
        'notas': 'Manejar con cuidado',
        'articulos': [
          {
            'id': 'item-id',
            'tipo_articulo': 'Caja',
            'descripcion': null,
            'cantidad': '2.00',
            'codigo_referencia': 'REF-1',
            'condicion_transporte': 'Ambiente',
            'notas': null,
          },
        ],
        'eventos': [
          {
            'id': 'event-id',
            'tipo': 'ASSIGNED',
            'realizado_por_id': 'admin-id',
            'repartidor_id': 'driver-id',
            'latitud': null,
            'longitud': null,
            'metadatos': {'origen': 'manual'},
            'creado_en': '2026-09-28T08:05:00-06:00',
          },
        ],
        'asignaciones': [
          {
            'id': 'assignment-id',
            'repartidor_id': 'driver-id',
            'asignada_por_id': 'admin-id',
            'tipo': 'ASIGNACION',
            'estado': 'ACTIVA',
            'asignada_en': '2026-09-28T08:05:00-06:00',
            'aceptada_en': null,
            'finalizada_en': null,
            'motivo': null,
          },
        ],
        'asignada_en': '2026-09-28T08:05:00-06:00',
        'llegada_recoleccion_en': null,
        'recolectada_en': null,
        'llegada_destino_en': null,
        'entregada_en': null,
        'cancelada_en': null,
        'movimiento_especial': null,
        'actualizado_en': '2026-09-28T08:05:00-06:00',
      });

    final request = ServiceRequestDetail.fromJson(json);

    expect(request.items.single.quantity, '2.00');
    expect(request.events.single.metadata['origen'], 'manual');
    expect(request.assignments.single.driverId, 'driver-id');
    expect(request.deliveredAt, isNull);
  });

  test('serializa la creación sin inventar envoltorios', () {
    const input = CreateServiceRequestInput(
      companyId: 'company-id',
      branchId: null,
      priority: 'NORMAL',
      modality: RequestModalities.betweenBranches,
      serviceTypeId: 'service-id',
      originId: 'origin-id',
      destinationId: 'destination-id',
      notes: '',
      items: [
        RequestArticleInput(
          itemType: '  Caja  ',
          quantity: '1.00',
          description: '',
        ),
      ],
    );

    expect(input.toJson(), {
      'empresa_id': 'company-id',
      'sucursal_id': null,
      'prioridad': 'NORMAL',
      'modalidad': 'ENTRE_SUCURSALES',
      'tipo_servicio_id': 'service-id',
      'origen_id': 'origin-id',
      'destino_id': 'destination-id',
      'destino_especial': null,
      'notas': null,
      'articulos': [
        {
          'tipo_articulo': 'Caja',
          'descripcion': null,
          'cantidad': '1.00',
          'codigo_referencia': null,
          'condicion_transporte': null,
          'notas': null,
        },
      ],
    });
  });

  test('mantiene la matriz de transiciones autorizada por el contrato', () {
    expect(requestTransitionMatrix['PENDING'], ['CANCELLED']);
    expect(requestTransitionMatrix['AT_PICKUP'], [
      'PICKED_UP',
      'CANCELLED',
      'PICKUP_FAILED',
    ]);
    expect(requestTransitionMatrix['AT_DESTINATION'], [
      'DELIVERED',
      'DELIVERY_FAILED',
    ]);
    expect(requestTransitionMatrix['DELIVERED'], isNull);
  });

  test('genera filtros paginados con nombres del backend', () {
    const query = RequestQuery(
      companyId: 'company-id',
      branchId: 'branch-id',
      priority: 'PRIORITY',
      status: 'PENDING',
      modality: RequestModalities.special,
      page: 2,
      pageSize: 50,
    );

    expect(query.toQueryParameters(), {
      'pagina': 2,
      'tamano_pagina': 50,
      'empresa_id': 'company-id',
      'sucursal_id': 'branch-id',
      'prioridad': 'PRIORITY',
      'estado': 'PENDING',
      'modalidad': 'ESPECIAL',
    });
  });

  test('interpreta un envío especial sin destino estructurado', () {
    final json = requestJson()
      ..addAll({
        'modalidad': 'ESPECIAL',
        'destino': null,
        'destino_especial': 'Laboratorio temporal, entrada norte',
        'presentacion_ruta': 'SOLO_KILOMETROS',
        'kilometros_envio_especial': '12.45',
      });

    final request = ServiceRequestSummary.fromJson(json);

    expect(request.isSpecial, isTrue);
    expect(request.destination, isNull);
    expect(request.destinationName, 'Laboratorio temporal, entrada norte');
    expect(request.specialKilometers, '12.45');
  });

  test('serializa un envío especial con destino libre', () {
    const input = CreateServiceRequestInput(
      companyId: 'company-id',
      branchId: 'branch-id',
      priority: 'NORMAL',
      modality: RequestModalities.special,
      serviceTypeId: 'service-id',
      originId: 'origin-id',
      destinationId: null,
      specialDestination: '  Clínica móvil  ',
      items: [RequestArticleInput(itemType: 'Caja', quantity: '1')],
    );

    expect(input.toJson()['destino_id'], isNull);
    expect(input.toJson()['destino_especial'], 'Clínica móvil');
    expect(input.toJson()['modalidad'], 'ESPECIAL');
  });

  test('interpreta las opciones de creación filtradas por el backend', () {
    final options = RequestCreationOptions.fromJson({
      'empresa_id': 'company-id',
      'sucursal_id': null,
      'modalidad_seleccionada': 'ENTRE_SUCURSALES',
      'mensaje_disponibilidad': null,
      'puede_crear_envio_especial': false,
      'modalidades': [
        {
          'codigo': 'ENTRE_SUCURSALES',
          'nombre': 'Entre sucursales',
          'requiere_destino_registrado': true,
          'presentacion_ruta': 'MAPA',
        },
      ],
      'origenes': [
        {
          'sucursal_id': 'branch-id',
          'sucursal_nombre': 'Sucursal Centro',
          'ubicacion': {
            'id': 'origin-id',
            'nombre': 'Sucursal Centro',
            'tipo_codigo': 'SUCURSAL',
            'departamento': 'Francisco Morazán',
            'municipio': 'Distrito Central',
            'ciudad': 'Tegucigalpa',
            'colonia': 'Centro',
            'direccion': 'Avenida principal',
            'latitud': '14.101200',
            'longitud': '-87.193100',
          },
        },
      ],
      'destinos': [
        {
          'sucursal_id': 'destination-branch-id',
          'sucursal_nombre': 'Sucursal Norte',
          'ubicacion': {
            'id': 'destination-id',
            'nombre': 'Sucursal Norte',
            'tipo_codigo': 'SUCURSAL',
            'departamento': 'Francisco Morazán',
            'municipio': 'Distrito Central',
            'ciudad': 'Tegucigalpa',
            'colonia': 'El Hato',
            'direccion': 'Bulevar del Norte',
            'latitud': '14.120000',
            'longitud': '-87.180000',
          },
        },
      ],
    });

    expect(options.selectedModality, RequestModalities.betweenBranches);
    expect(options.availabilityMessage, isNull);
    expect(options.canCreateSpecial, isFalse);
    expect(options.modalities.single.routePresentation, 'MAPA');
    expect(options.origins.single.branchId, 'branch-id');
    expect(options.origins.single.location.city, 'Tegucigalpa');
    expect(options.destinations.single.displayName, 'Sucursal Norte');
  });

  test('interpreta el mensaje de disponibilidad como estado vacío', () {
    final options = RequestCreationOptions.fromJson({
      'empresa_id': 'company-id',
      'sucursal_id': null,
      'modalidad_seleccionada': 'ENTRE_SUCURSALES',
      'mensaje_disponibilidad':
          'No hay sucursales disponibles para crear solicitudes.',
      'puede_crear_envio_especial': false,
      'modalidades': const [],
      'origenes': const [],
      'destinos': const [],
    });

    expect(
      options.availabilityMessage,
      'No hay sucursales disponibles para crear solicitudes.',
    );
    expect(options.origins, isEmpty);
  });

  test('genera la consulta de opciones sin parámetros vacíos', () {
    const query = RequestCreationOptionsQuery(
      companyId: 'company-id',
      modality: RequestModalities.betweenBranches,
      originId: 'origin-id',
    );

    expect(query.toQueryParameters(), {
      'empresa_id': 'company-id',
      'modalidad': 'ENTRE_SUCURSALES',
      'origen_id': 'origin-id',
    });
  });

  test('encadena opciones entre sucursales usando ubicacion.id', () {
    const initialQuery = RequestCreationOptionsQuery(
      companyId: 'company-id',
      modality: RequestModalities.betweenBranches,
    );
    const destinationQuery = RequestCreationOptionsQuery(
      companyId: 'company-id',
      modality: RequestModalities.betweenBranches,
      originId: 'origin-location-id',
    );

    expect(initialQuery.toQueryParameters(), {
      'empresa_id': 'company-id',
      'modalidad': 'ENTRE_SUCURSALES',
    });
    expect(
      destinationQuery.toQueryParameters()['origen_id'],
      'origin-location-id',
    );
  });

  test('la asignación manual envía el id del perfil de motorista', () {
    const input = RequestAssignmentInput(
      driverId: 'driver-profile-id',
      reason: 'Asignación operativa',
    );

    expect(input.toJson()['repartidor_id'], 'driver-profile-id');
  });

  test('interpreta los conteos y recientes del resumen solicitante', () {
    final summary = RequesterSummary.fromJson({
      'total': 12,
      'pendientes': 3,
      'activas': 4,
      'entregadas': 3,
      'fallidas': 1,
      'canceladas': 1,
      'recientes': [requestJson()],
    });

    expect(summary.total, 12);
    expect(summary.pending, 3);
    expect(summary.active, 4);
    expect(summary.delivered, 3);
    expect(summary.failed, 1);
    expect(summary.cancelled, 1);
    expect(summary.recent.single.number, 'SOL-0001');
  });

  test('genera el alcance opcional del resumen solicitante', () {
    const query = RequesterSummaryQuery(
      companyId: 'company-id',
      branchId: 'branch-id',
    );

    expect(query.toQueryParameters(), {
      'empresa_id': 'company-id',
      'sucursal_id': 'branch-id',
    });
  });
}
