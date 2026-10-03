import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/widgets/required_gps_body.dart';

void main() {
  testWidgets('bloquea la operación cuando el GPS está apagado', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceEnabledProvider.overrideWith(
            (ref) => Stream.value(false),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: RequiredGpsBody(child: Text('Contenido operativo')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('GPS apagado'), findsOneWidget);
    expect(
      find.text('No puedes continuar porque tienes el GPS apagado.'),
      findsOneWidget,
    );
    expect(find.text('Contenido operativo'), findsNothing);
  });

  testWidgets('muestra la operación cuando el GPS está encendido', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceEnabledProvider.overrideWith(
            (ref) => Stream.value(true),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: RequiredGpsBody(child: Text('Contenido operativo')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Contenido operativo'), findsOneWidget);
    expect(find.text('GPS apagado'), findsNothing);
  });
}
