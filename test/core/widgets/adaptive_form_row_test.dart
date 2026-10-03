import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/widgets/adaptive_form_row.dart';

void main() {
  testWidgets('apila los campos en una pantalla angosta', (tester) async {
    await _pumpRow(tester, width: 320);

    final first = tester.getTopLeft(find.byKey(const Key('first-field')));
    final second = tester.getTopLeft(find.byKey(const Key('second-field')));

    expect(second.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('apila los campos cuando el texto del sistema es grande', (
    tester,
  ) async {
    await _pumpRow(tester, width: 700, textScaleFactor: 1.5);

    final first = tester.getTopLeft(find.byKey(const Key('first-field')));
    final second = tester.getTopLeft(find.byKey(const Key('second-field')));

    expect(second.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('usa una fila cuando hay espacio suficiente', (tester) async {
    await _pumpRow(tester, width: 700);

    final first = tester.getTopLeft(find.byKey(const Key('first-field')));
    final second = tester.getTopLeft(find.byKey(const Key('second-field')));

    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
  });
}

Future<void> _pumpRow(
  WidgetTester tester, {
  required double width,
  double textScaleFactor = 1,
}) {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: AdaptiveFormRow(
              children: [
                SizedBox(key: Key('first-field'), height: 56),
                SizedBox(key: Key('second-field'), height: 56),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
