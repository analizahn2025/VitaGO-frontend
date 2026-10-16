import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/widgets/entity_list_tile.dart';

void main() {
  testWidgets('se adapta a una pantalla angosta con texto y estado extensos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: EntityListTile(
            icon: Icons.person_outline,
            title: 'Nombre completo de una persona usuaria',
            subtitle: 'persona.con.correo.extenso@empresa.com',
            status: 'PENDIENTE_ACTIVACION',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PENDIENTE ACTIVACION'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
