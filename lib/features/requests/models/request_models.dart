import 'package:vitago_app/core/models/json_readers.dart';

class RequestServiceType {
  const RequestServiceType({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  factory RequestServiceType.fromJson(Map<String, dynamic> json) {
    return RequestServiceType(
      id: requireString(json, 'id'),
      code: requireString(json, 'codigo'),
      name: requireString(json, 'nombre'),
      description: optionalString(json, 'descripcion'),
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
}

class RequestPoint {
  const RequestPoint({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory RequestPoint.fromJson(Map<String, dynamic> json) {
    return RequestPoint(
      id: requireString(json, 'id'),
      name: requireString(json, 'nombre'),
      address: requireString(json, 'direccion'),
      latitude: optionalString(json, 'latitud'),
      longitude: optionalString(json, 'longitud'),
    );
  }

  final String id;
  final String name;
  final String address;
  final String? latitude;
  final String? longitude;
}

class ServiceRequestSummary {
  const ServiceRequestSummary({
    required this.id,
    required this.number,
    required this.companyId,
    required this.requestedById,
    required this.priority,
    required this.modality,
    required this.serviceType,
    required this.origin,
    required this.routePresentation,
    required this.status,
    required this.createdAt,
    this.branchId,
    this.assignedDriverId,
    this.destination,
    this.specialDestination,
    this.specialKilometers,
  });

  factory ServiceRequestSummary.fromJson(Map<String, dynamic> json) {
    final destinationJson = optionalJsonMap(json, 'destino');
    return ServiceRequestSummary(
      id: requireString(json, 'id'),
      number: requireString(json, 'numero'),
      companyId: requireString(json, 'empresa_id'),
      branchId: optionalString(json, 'sucursal_id'),
      requestedById: requireString(json, 'solicitada_por_id'),
      assignedDriverId: optionalString(json, 'repartidor_asignado_id'),
      priority: requireString(json, 'prioridad'),
      modality: requireString(json, 'modalidad'),
      serviceType: RequestServiceType.fromJson(
        requireJsonMap(json['tipo_servicio'], 'tipo_servicio'),
      ),
      origin: RequestPoint.fromJson(requireJsonMap(json['origen'], 'origen')),
      destination: destinationJson == null
          ? null
          : RequestPoint.fromJson(destinationJson),
      specialDestination: optionalString(json, 'destino_especial'),
      routePresentation: requireString(json, 'presentacion_ruta'),
      specialKilometers: optionalString(json, 'kilometros_envio_especial'),
      status: requireString(json, 'estado'),
      createdAt: requireDateTime(json, 'creado_en'),
    );
  }

  final String id;
  final String number;
  final String companyId;
  final String? branchId;
  final String requestedById;
  final String? assignedDriverId;
  final String priority;
  final String modality;
  final RequestServiceType serviceType;
  final RequestPoint origin;
  final RequestPoint? destination;
  final String? specialDestination;
  final String routePresentation;
  final String? specialKilometers;
  final String status;
  final DateTime createdAt;

  bool get isPriority => priority.toUpperCase() == 'PRIORITY';
  bool get isSpecial => modality.toUpperCase() == RequestModalities.special;
  bool get isTerminal => requestTerminalStates.contains(status.toUpperCase());
  String get destinationName =>
      destination?.name ?? specialDestination ?? 'Destino no informado';
}

class ServiceRequestDetail {
  const ServiceRequestDetail({
    required this.summary,
    required this.items,
    required this.events,
    required this.assignments,
    required this.updatedAt,
    this.notes,
    this.assignedAt,
    this.arrivedPickupAt,
    this.pickedUpAt,
    this.arrivedDestinationAt,
    this.deliveredAt,
    this.cancelledAt,
    this.specialMovement,
  });

  factory ServiceRequestDetail.fromJson(Map<String, dynamic> json) {
    final movementJson = optionalJsonMap(json, 'movimiento_especial');
    return ServiceRequestDetail(
      summary: ServiceRequestSummary.fromJson(json),
      notes: optionalString(json, 'notas'),
      items: jsonMapList(
        json['articulos'],
        'articulos',
      ).map(RequestArticle.fromJson).toList(growable: false),
      events: jsonMapList(
        json['eventos'],
        'eventos',
      ).map(RequestEvent.fromJson).toList(growable: false),
      assignments: jsonMapList(
        json['asignaciones'],
        'asignaciones',
      ).map(RequestAssignment.fromJson).toList(growable: false),
      assignedAt: optionalDateTime(json, 'asignada_en'),
      arrivedPickupAt: optionalDateTime(json, 'llegada_recoleccion_en'),
      pickedUpAt: optionalDateTime(json, 'recolectada_en'),
      arrivedDestinationAt: optionalDateTime(json, 'llegada_destino_en'),
      deliveredAt: optionalDateTime(json, 'entregada_en'),
      cancelledAt: optionalDateTime(json, 'cancelada_en'),
      specialMovement: movementJson == null
          ? null
          : SpecialRequestMovement.fromJson(movementJson),
      updatedAt: requireDateTime(json, 'actualizado_en'),
    );
  }

  final ServiceRequestSummary summary;
  final String? notes;
  final List<RequestArticle> items;
  final List<RequestEvent> events;
  final List<RequestAssignment> assignments;
  final DateTime? assignedAt;
  final DateTime? arrivedPickupAt;
  final DateTime? pickedUpAt;
  final DateTime? arrivedDestinationAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final SpecialRequestMovement? specialMovement;
  final DateTime updatedAt;

  String get id => summary.id;
  String get number => summary.number;
  String get status => summary.status;
  String get priority => summary.priority;
  String? get assignedDriverId => summary.assignedDriverId;
  bool get isTerminal => summary.isTerminal;
  bool get isSpecial => summary.isSpecial;
}

class SpecialRequestMovement {
  const SpecialRequestMovement({
    required this.id,
    required this.driverId,
    required this.shiftId,
    required this.status,
    required this.startedAt,
    required this.recordsConsidered,
    required this.recordsDiscarded,
    this.finishedAt,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.traveledKilometers,
  });

  factory SpecialRequestMovement.fromJson(Map<String, dynamic> json) {
    return SpecialRequestMovement(
      id: requireString(json, 'id'),
      driverId: requireString(json, 'repartidor_id'),
      shiftId: requireString(json, 'jornada_id'),
      status: requireString(json, 'estado'),
      startedAt: requireDateTime(json, 'iniciada_en'),
      finishedAt: optionalDateTime(json, 'finalizada_en'),
      startLatitude: optionalString(json, 'latitud_inicio'),
      startLongitude: optionalString(json, 'longitud_inicio'),
      endLatitude: optionalString(json, 'latitud_fin'),
      endLongitude: optionalString(json, 'longitud_fin'),
      traveledKilometers: optionalString(json, 'kilometros_recorridos'),
      recordsConsidered: optionalInt(json, 'registros_considerados'),
      recordsDiscarded: optionalInt(json, 'registros_descartados'),
    );
  }

  final String id;
  final String driverId;
  final String shiftId;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? startLatitude;
  final String? startLongitude;
  final String? endLatitude;
  final String? endLongitude;
  final String? traveledKilometers;
  final int recordsConsidered;
  final int recordsDiscarded;
}

class RequestArticle {
  const RequestArticle({
    required this.id,
    required this.itemType,
    required this.quantity,
    this.description,
    this.referenceCode,
    this.transportCondition,
    this.notes,
  });

  factory RequestArticle.fromJson(Map<String, dynamic> json) {
    return RequestArticle(
      id: requireString(json, 'id'),
      itemType: requireString(json, 'tipo_articulo'),
      description: optionalString(json, 'descripcion'),
      quantity: requireString(json, 'cantidad'),
      referenceCode: optionalString(json, 'codigo_referencia'),
      transportCondition: optionalString(json, 'condicion_transporte'),
      notes: optionalString(json, 'notas'),
    );
  }

  final String id;
  final String itemType;
  final String? description;
  final String quantity;
  final String? referenceCode;
  final String? transportCondition;
  final String? notes;
}

class RequestEvent {
  const RequestEvent({
    required this.id,
    required this.type,
    required this.metadata,
    required this.createdAt,
    this.performedById,
    this.driverId,
    this.latitude,
    this.longitude,
  });

  factory RequestEvent.fromJson(Map<String, dynamic> json) {
    return RequestEvent(
      id: requireString(json, 'id'),
      type: requireString(json, 'tipo'),
      performedById: optionalString(json, 'realizado_por_id'),
      driverId: optionalString(json, 'repartidor_id'),
      latitude: optionalString(json, 'latitud'),
      longitude: optionalString(json, 'longitud'),
      metadata: optionalJsonMap(json, 'metadatos') ?? const {},
      createdAt: requireDateTime(json, 'creado_en'),
    );
  }

  final String id;
  final String type;
  final String? performedById;
  final String? driverId;
  final String? latitude;
  final String? longitude;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}

class RequestAssignment {
  const RequestAssignment({
    required this.id,
    required this.driverId,
    required this.assignedById,
    required this.type,
    required this.status,
    required this.assignedAt,
    this.acceptedAt,
    this.finishedAt,
    this.reason,
  });

  factory RequestAssignment.fromJson(Map<String, dynamic> json) {
    return RequestAssignment(
      id: requireString(json, 'id'),
      driverId: requireString(json, 'repartidor_id'),
      assignedById: requireString(json, 'asignada_por_id'),
      type: requireString(json, 'tipo'),
      status: requireString(json, 'estado'),
      assignedAt: requireDateTime(json, 'asignada_en'),
      acceptedAt: optionalDateTime(json, 'aceptada_en'),
      finishedAt: optionalDateTime(json, 'finalizada_en'),
      reason: optionalString(json, 'motivo'),
    );
  }

  final String id;
  final String driverId;
  final String assignedById;
  final String type;
  final String status;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? finishedAt;
  final String? reason;
}

const requestTerminalStates = {
  'DELIVERED',
  'CANCELLED',
  'PICKUP_FAILED',
  'DELIVERY_FAILED',
};

const requestTransitionMatrix = <String, List<String>>{
  'PENDING': ['CANCELLED'],
  'ASSIGNED': ['GOING_TO_PICKUP', 'CANCELLED'],
  'GOING_TO_PICKUP': ['AT_PICKUP', 'CANCELLED', 'PICKUP_FAILED'],
  'AT_PICKUP': ['PICKED_UP', 'CANCELLED', 'PICKUP_FAILED'],
  'PICKED_UP': ['IN_TRANSIT', 'DELIVERY_FAILED'],
  'IN_TRANSIT': ['AT_DESTINATION', 'DELIVERY_FAILED'],
  'AT_DESTINATION': ['DELIVERED', 'DELIVERY_FAILED'],
};

abstract final class RequestModalities {
  static const betweenBranches = 'ENTRE_SUCURSALES';
  static const transportCompany = 'EMPRESA_TRANSPORTE';
  static const special = 'ESPECIAL';
  static const open = 'ABIERTO';
}

String requestModalityLabel(String modality) =>
    switch (modality.toUpperCase()) {
      RequestModalities.betweenBranches => 'Entre sucursales',
      RequestModalities.transportCompany => 'Empresa de transporte',
      RequestModalities.special => 'Envío especial',
      RequestModalities.open => 'Abierto',
      _ => modality.replaceAll('_', ' ').toLowerCase(),
    };

String requestStatusLabel(String status) => switch (status.toUpperCase()) {
  'PENDING' => 'Pendiente',
  'ASSIGNED' => 'Asignada',
  'GOING_TO_PICKUP' => 'Hacia recolección',
  'AT_PICKUP' => 'En recolección',
  'PICKED_UP' => 'Recolectada',
  'IN_TRANSIT' => 'En tránsito',
  'AT_DESTINATION' => 'En destino',
  'DELIVERED' => 'Entregada',
  'CANCELLED' => 'Cancelada',
  'PICKUP_FAILED' => 'Recolección fallida',
  'DELIVERY_FAILED' => 'Entrega fallida',
  _ => status.replaceAll('_', ' ').toLowerCase(),
};

String? requestNextOperationalStatus(String status) =>
    switch (status.toUpperCase()) {
      'ASSIGNED' => 'GOING_TO_PICKUP',
      'GOING_TO_PICKUP' => 'AT_PICKUP',
      'AT_PICKUP' => 'PICKED_UP',
      'PICKED_UP' => 'IN_TRANSIT',
      'IN_TRANSIT' => 'AT_DESTINATION',
      'AT_DESTINATION' => 'DELIVERED',
      _ => null,
    };

String requestTransitionActionLabel(String targetStatus) =>
    switch (targetStatus.toUpperCase()) {
      'GOING_TO_PICKUP' => 'Ir a recolectar',
      'AT_PICKUP' => 'Llegué al origen',
      'PICKED_UP' => 'Confirmar recolección',
      'IN_TRANSIT' => 'Iniciar traslado',
      'AT_DESTINATION' => 'Llegué al destino',
      'DELIVERED' => 'Confirmar entrega',
      'PICKUP_FAILED' => 'Reportar recolección fallida',
      'DELIVERY_FAILED' => 'Reportar entrega fallida',
      'CANCELLED' => 'Cancelar solicitud',
      _ => 'Actualizar estado',
    };

String? requestTransitionActionLabelForStatus(String currentStatus) {
  final target = requestNextOperationalStatus(currentStatus);
  return target == null ? null : requestTransitionActionLabel(target);
}
