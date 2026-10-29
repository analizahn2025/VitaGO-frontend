import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';

LatLng? routeLocationPosition(RouteLocation? location) {
  if (location == null) return null;
  final latitude = double.tryParse(location.latitude);
  final longitude = double.tryParse(location.longitude);
  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }
  return LatLng(latitude, longitude);
}

List<LatLng> routePolylinePoints(
  DriverRoute route, {
  RoadRoute? roadRoute,
  bool? showRoute,
}) {
  if (!route.map.showMap || !(showRoute ?? route.map.showRoute)) {
    return const [];
  }
  final road = roadRoute ?? route.roadRoute;
  if (road.status != 'CALCULADA' ||
      !road.breakdownAvailable ||
      road.visualizationMode != 'UN_TRAMO') {
    return const [];
  }
  // A valid suffix may reuse geometry from an older calculatedVersion.
  if (route.currentVersion != null &&
      road.currentVersion != null &&
      road.currentVersion != route.currentVersion) {
    return const [];
  }
  final flow = route.flow;
  if (flow?.isAutomatic != true) return const [];
  final selectedId = flow?.segmentId;
  if (selectedId == null) return const [];
  final segment = road.segments
      .where((entry) => entry.id == selectedId)
      .firstOrNull;
  if (segment == null || segment.withoutMovement) return const [];
  if (segment.requestId != flow?.requestId ||
      segment.stopType != flow?.stopType) {
    return const [];
  }
  if (!route.stops.any(
    (stop) =>
        stop.requestId == segment.requestId && stop.type == segment.stopType,
  )) {
    return const [];
  }
  // The global polyline is compatibility data, never a fallback for missing legs.
  final encoded = segment.encodedPolyline;
  if (encoded == null || encoded.isEmpty) return const [];
  try {
    return decodeEncodedPolyline(encoded);
  } on FormatException {
    return const [];
  }
}

List<LatLng> decodeEncodedPolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;

  while (index < encoded.length) {
    final latitudeValue = _decodeValue(encoded, index);
    index = latitudeValue.nextIndex;
    latitude += latitudeValue.delta;

    if (index >= encoded.length) {
      throw const FormatException('La polilínea está incompleta.');
    }
    final longitudeValue = _decodeValue(encoded, index);
    index = longitudeValue.nextIndex;
    longitude += longitudeValue.delta;

    if (latitude.abs() > 9000000 || longitude.abs() > 18000000) {
      throw const FormatException(
        'La polilínea contiene coordenadas inválidas.',
      );
    }

    points.add(LatLng(latitude / 1e5, longitude / 1e5));
  }
  return List.unmodifiable(points);
}

_DecodedValue _decodeValue(String encoded, int startIndex) {
  var index = startIndex;
  var result = 0;
  var shift = 0;
  var byte = 0;

  do {
    if (index >= encoded.length || shift > 30) {
      throw const FormatException('La polilínea no es válida.');
    }
    byte = encoded.codeUnitAt(index++) - 63;
    if (byte < 0 || byte > 63) {
      throw const FormatException('La polilínea no es válida.');
    }
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20);

  final delta = (result & 1) == 1 ? ~(result >> 1) : result >> 1;
  return _DecodedValue(delta: delta, nextIndex: index);
}

class _DecodedValue {
  const _DecodedValue({required this.delta, required this.nextIndex});

  final int delta;
  final int nextIndex;
}
