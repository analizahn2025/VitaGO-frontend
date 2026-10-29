import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/core/device/device_location_service.dart';

/// Presentation-only progress over the original road geometry.
/// It never snaps the GPS marker, changes service state or requests a new route.
class RoutePolylineProgress {
  String? _segmentId;
  List<LatLng> _points = const [];
  List<double> _distances = const [];
  double _progress = 0;
  LatLng? _previousPosition;
  DeviceLocation? _lastLocation;
  List<LatLng> _remaining = const [];

  List<LatLng> remaining({
    required String segmentId,
    required List<LatLng> points,
    required DeviceLocation? location,
  }) {
    if (_segmentId != segmentId || !listEquals(points, _points)) {
      _segmentId = segmentId;
      _points = List.unmodifiable(points);
      _remaining = _points;
      _distances = [0];
      for (var index = 1; index < points.length; index++) {
        _distances.add(
          _distances.last + _distance(points[index - 1], points[index]),
        );
      }
      _progress = 0;
      _previousPosition = null;
      _lastLocation = null;
    }
    if (location == null ||
        points.length < 2 ||
        identical(location, _lastLocation)) {
      return _remaining;
    }
    _lastLocation = location;
    final accuracy = location.accuracyMeters;
    if (!location.latitude.isFinite ||
        !location.longitude.isFinite ||
        location.latitude.abs() > 90 ||
        location.longitude.abs() > 180 ||
        (accuracy != null &&
            (!accuracy.isFinite || accuracy < 0 || accuracy > 50))) {
      return _remaining;
    }
    final position = LatLng(location.latitude, location.longitude);
    // Do not jump to a much later leg at a crossing or parallel street.
    final maxAdvance = _previousPosition == null
        ? double.infinity
        : math.max(80.0, _distance(_previousPosition!, position) * 2.5 + 30);
    var bestDistance = double.infinity;
    var nextProgress = _progress;
    for (var index = 0; index < points.length - 1; index++) {
      final start = points[index];
      final end = points[index + 1];
      final scale = math.cos(position.latitude * math.pi / 180);
      final dx = (end.longitude - start.longitude) * scale;
      final dy = end.latitude - start.latitude;
      final lengthSquared = dx * dx + dy * dy;
      if (lengthSquared == 0) continue;
      final fraction =
          (((position.longitude - start.longitude) * scale * dx +
                      (position.latitude - start.latitude) * dy) /
                  lengthSquared)
              .clamp(0.0, 1.0);
      final along =
          _distances[index] +
          (_distances[index + 1] - _distances[index]) * fraction;
      if (along < _progress - 10 || along > _progress + maxAdvance) continue;
      final projected = LatLng(
        start.latitude + (end.latitude - start.latitude) * fraction,
        start.longitude + (end.longitude - start.longitude) * fraction,
      );
      final distance = _distance(position, projected);
      // Near ties prefer the earlier point, preserving loops not yet travelled.
      if (distance < bestDistance - 2) {
        bestDistance = distance;
        nextProgress = along;
      }
    }
    // Poor GPS or an off-route rider must not erase an untravelled road.
    if (bestDistance > 35) return _remaining;
    _previousPosition = position;
    if (nextProgress <= _progress + 2) return _remaining;
    _progress = nextProgress;
    if (_progress >= _distances.last - 0.5) {
      _remaining = const [];
      return _remaining;
    }
    for (var index = 0; index < points.length - 1; index++) {
      if (_distances[index + 1] <= _progress) continue;
      final fraction =
          (_progress - _distances[index]) /
          (_distances[index + 1] - _distances[index]);
      final start = points[index];
      final end = points[index + 1];
      _remaining = List.unmodifiable([
        LatLng(
          start.latitude + (end.latitude - start.latitude) * fraction,
          start.longitude + (end.longitude - start.longitude) * fraction,
        ),
        ...points.skip(index + 1),
      ]);
      break;
    }
    return _remaining;
  }

  static double _distance(LatLng first, LatLng second) {
    const metersPerDegree = 111195.0;
    final scale = math.cos((first.latitude + second.latitude) * math.pi / 360);
    final dx = (first.longitude - second.longitude) * scale;
    final dy = first.latitude - second.latitude;
    return math.sqrt(dx * dx + dy * dy) * metersPerDegree;
  }
}
