import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/core/device/device_location_service.dart';

/// Small, reusable map bitmaps made from VitaGo's original mascot.
class DriverMarkerIcons {
  const DriverMarkerIcons({required this.mascot, required this.heading});

  final BitmapDescriptor mascot;
  final BitmapDescriptor heading;

  static const mascotSize = 56.0;
  static const headingSize = 80.0;
  static const mascotAsset = 'assets/branding/corporate/app_icon.png';

  static ({Color color, double ratio, Future<DriverMarkerIcons> icons})? _cache;

  /// Decoding and rasterization happen once, never on GPS updates.
  static Future<DriverMarkerIcons> load({
    required Color color,
    required double devicePixelRatio,
  }) {
    final ratio = devicePixelRatio.isFinite
        ? devicePixelRatio.clamp(1.0, 3.0).toDouble()
        : 2.0;
    final cached = _cache;
    if (cached != null && cached.color == color && cached.ratio == ratio) {
      return cached.icons;
    }
    final icons = _create(color, ratio);
    _cache = (color: color, ratio: ratio, icons: icons);
    // Allow another screen to retry if the bundle or renderer failed.
    icons.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (identical(_cache?.icons, icons)) _cache = null;
      },
    );
    return icons;
  }

  static Future<DriverMarkerIcons> _create(Color color, double ratio) async {
    final data = await rootBundle.load(mascotAsset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: (mascotSize * ratio).ceil(),
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        final mascot = await _bitmap(mascotSize, ratio, (canvas) {
          const center = Offset(mascotSize / 2, mascotSize / 2);
          canvas.drawCircle(center, 28, Paint()..color = Colors.white);
          canvas.save();
          canvas.clipPath(Path()..addOval(const Rect.fromLTWH(4, 4, 48, 48)));
          canvas.drawImageRect(
            frame.image,
            Rect.fromLTWH(
              0,
              0,
              frame.image.width.toDouble(),
              frame.image.height.toDouble(),
            ),
            const Rect.fromLTWH(4, 4, 48, 48),
            Paint()..filterQuality = FilterQuality.medium,
          );
          canvas.restore();
          canvas.drawCircle(
            center,
            25.5,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        });
        final heading = await _bitmap(headingSize, ratio, (canvas) {
          final arrow = Path()
            ..moveTo(40, 3)
            ..lineTo(31, 17)
            ..lineTo(49, 17)
            ..close();
          canvas.drawPath(
            arrow,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = 4,
          );
          canvas.drawPath(arrow, Paint()..color = color);
        });
        return DriverMarkerIcons(mascot: mascot, heading: heading);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  static Future<BitmapDescriptor> _bitmap(
    double size,
    double ratio,
    void Function(Canvas canvas) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    paint(canvas);
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(
        (size * ratio).ceil(),
        (size * ratio).ceil(),
      );
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('No se pudo generar el marcador.');
        return BitmapDescriptor.bytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          imagePixelRatio: ratio,
          width: size,
          height: size,
        );
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }
}

/// Hide an unavailable bearing, or a noisy bearing while stationary.
double? driverMarkerHeading(DeviceLocation location) {
  final heading = location.headingDegrees;
  if (heading == null || !heading.isFinite || heading < 0 || heading >= 360) {
    return null;
  }
  final speed = location.speedMetersPerSecond;
  if (speed != null && (!speed.isFinite || speed < 0.5)) return null;
  return heading;
}
