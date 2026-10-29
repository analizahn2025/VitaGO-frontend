import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/app/theme/app_colors.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/routes/maps/driver_marker_icons.dart';

void main() {
  test('solo muestra un rumbo GPS válido y evita el ruido al detenerse', () {
    DeviceLocation location(double? heading, [double? speed]) => DeviceLocation(
      latitude: 14.07,
      longitude: -87.19,
      recordedAt: DateTime.utc(2026, 10, 28),
      headingDegrees: heading,
      speedMetersPerSecond: speed,
    );

    for (final heading in [null, -1.0, 360.0, double.nan, double.infinity]) {
      expect(driverMarkerHeading(location(heading, 5)), isNull);
    }
    for (final speed in [0.0, 0.1, -1.0, double.nan, double.infinity]) {
      expect(driverMarkerHeading(location(90, speed)), isNull);
    }
    expect(driverMarkerHeading(location(0, 5)), 0);
    expect(driverMarkerHeading(location(359, 0.5)), 359);
    expect(driverMarkerHeading(location(180)), 180);
  });

  testWidgets('reutiliza los PNG nítidos con esquinas transparentes', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final color = AppColors.corporate.primary;
      final request = DriverMarkerIcons.load(color: color, devicePixelRatio: 2);
      final icons = await request;
      expect(
        DriverMarkerIcons.load(color: color, devicePixelRatio: 2),
        same(request),
      );

      for (final (bitmap, size) in [
        (icons.mascot, DriverMarkerIcons.mascotSize),
        (icons.heading, DriverMarkerIcons.headingSize),
      ]) {
        final png = bitmap as BytesMapBitmap;
        expect(png.width, size);
        expect(png.height, size);
        final codec = await ui.instantiateImageCodec(png.byteData);
        final frame = await codec.getNextFrame();
        try {
          expect(frame.image.width, size * 2);
          expect(frame.image.height, size * 2);
          final pixels = await frame.image.toByteData();
          expect(pixels!.getUint8(3), 0);
          final center = (frame.image.width ~/ 2);
          final alpha = pixels.getUint8(
            (center * frame.image.width + center) * 4 + 3,
          );
          expect(alpha, bitmap == icons.mascot ? 255 : 0);
        } finally {
          frame.image.dispose();
          codec.dispose();
        }
      }
    });
  });
}
