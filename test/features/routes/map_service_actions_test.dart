import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/core/navigation/route_activity_observer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/providers/evidence_providers.dart';
import 'package:vitago_app/features/evidence/repositories/evidence_repository.dart';
import 'package:vitago_app/features/evidence/services/evidence_capture_service.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/request_stage_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/requests/views/confirm_request_stage_view.dart';
import 'package:vitago_app/features/requests/views/transition_request_view.dart';
import 'package:vitago_app/features/requests/views/widgets/driver_request_actions.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/models/driver_route_flow.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/routes/repositories/routes_repository.dart';
import 'package:vitago_app/features/routes/views/driver_route_map_view.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/controllers/driver_arrivals_controller.dart';
import 'package:vitago_app/features/tracking/models/driver_arrival.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/storage/arrival_presentation_store.dart';
import 'package:vitago_app/features/tracking/widgets/driver_arrival_listener.dart';
import 'package:vitago_app/features/tracking/services/tracking_queue_coordinator.dart';

void main() {
  testWidgets(
    'temperatura requerida y corrección tras400 conservan la fotografía',
    (tester) async {
      final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
        'first': _request('first', 'AT_PICKUP'),
      });
      await harness.pump(tester);
      await _openAction(tester, 'Tomar foto de recolección');
      await tester.tap(find.widgetWithText(FilledButton, 'Tomar foto'));
      await _pumpChanges(tester);
      final send = find.widgetWithText(
        FilledButton,
        'Enviar foto y confirmar recolección',
      );
      await tester.tap(send);
      await _pumpChanges(tester);
      expect(harness.evidence.uploads, isEmpty);
      expect(
        find.text('Indica la temperatura del contenedor.'),
        findsOneWidget,
      );
      final field = find.widgetWithText(
        TextFormField,
        'Temperatura del contenedor (°C)',
      );
      await tester.enterText(field, '4.501');
      await tester.tap(send);
      await _pumpChanges(tester);
      expect(harness.evidence.uploads, isEmpty);
      await tester.enterText(field, '4,50');
      harness.evidence.uploadFailure = const AppFailure(
        message: 'Temperatura inválida.',
        statusCode: 400,
        fieldErrors: {
          'temperatura_contenedor_c': ['Revisa la lectura del contenedor.'],
        },
      );
      await tester.tap(send);
      await _pumpChanges(tester);
      expect(harness.evidence.uploads, hasLength(1));
      expect(harness.evidence.uploads.single.temperatureC, '4.50');
      expect(tester.widget<TextFormField>(field).controller!.text, '4,50');
      expect(tester.widget<TextFormField>(field).enabled, isTrue);
      expect(find.text('Revisa la lectura del contenedor.'), findsOneWidget);
      harness.evidence.uploadFailure = null;
      await tester.enterText(field, '5.25');
      await tester.tap(send);
      await _pumpChanges(tester);
      expect(harness.evidence.uploads, hasLength(2));
      expect(harness.evidence.uploads.last.temperatureC, '5.25');
      expect(
        harness.evidence.uploads.first.filePath,
        harness.evidence.uploads.last.filePath,
      );
      expect(harness.requests.transitions, isEmpty);
      expect(find.byType(ConfirmRequestStageView), findsNothing);
      expect(harness.routes.calculateCalls, 0);
    },
  );

  testWidgets('intercala recoger A, recoger B, entregar B y entregar A', (
    tester,
  ) async {
    final harness = _MapHarness(
      _route([
        _stop('first', 'AT_PICKUP'),
        _stop('second', 'ASSIGNED', order: 2),
        _stop('second', 'ASSIGNED', type: 'ENTREGA', order: 3),
        _stop('first', 'AT_PICKUP', type: 'ENTREGA', order: 4),
      ]),
      {
        'first': _request('first', 'AT_PICKUP'),
        'second': _request('second', 'ASSIGNED'),
      },
    );
    void plan(List<(String, String)> pairs, {DriverArrival? arrival}) {
      harness.routes.current = _route([
        for (var i = 0; i < pairs.length; i++)
          _stop(
            pairs[i].$1,
            harness.requests.details[pairs[i].$1]!.status,
            type: pairs[i].$2,
            order: i + 1,
          ),
      ], arrival: arrival);
    }

    harness.evidence.pickupResponseStatus = 'PICKED_UP';
    harness.evidence.onUpload = (id, type) {
      if (id == 'first' && type == 'FOTO_RECOLECCION') {
        harness.requests.details['first'] = _request('first', 'PICKED_UP');
        harness.requests.details['second'] = _request(
          'second',
          'GOING_TO_PICKUP',
        );
        plan([
          ('second', 'RECOLECCION'),
          ('second', 'ENTREGA'),
          ('first', 'ENTREGA'),
        ]);
      } else if (id == 'second' && type == 'FOTO_RECOLECCION') {
        harness.requests.details['second'] = _request('second', 'IN_TRANSIT');
        plan([('second', 'ENTREGA'), ('first', 'ENTREGA')]);
      } else if (id == 'second') {
        harness.requests.details['second'] = _request('second', 'DELIVERED');
        harness.requests.details['first'] = _request('first', 'IN_TRANSIT');
        plan([('first', 'ENTREGA')]);
      } else {
        harness.requests.details['first'] = _request('first', 'DELIVERED');
        plan([]);
      }
    };
    Future<void> arrive(String id, {bool delivery = false}) async {
      final event = DriverArrival(
        eventId: '$id-${delivery ? 'delivery' : 'pickup'}',
        requestId: id,
        status: delivery ? 'AT_DESTINATION' : 'AT_PICKUP',
        stopType: delivery ? 'ENTREGA' : 'RECOLECCION',
        detectedAt: DateTime.utc(2026, 10, 26),
        source: 'GPS',
        screen: delivery ? 'ENTREGA' : 'RECOLECCION',
      );
      harness.requests.details[id] = _request(id, event.status);
      plan([
        for (final stop in harness.routes.current.stops)
          (stop.requestId, stop.type),
      ], arrival: event);
      _signalArrival(tester, event);
      await _pumpChanges(tester);
      await _pumpChanges(tester);
      expect(find.byType(ConfirmRequestStageView), findsOneWidget);
    }

    await harness.pump(tester, arrivals: true);
    await _sendPhoto(tester, 'recolección');
    expect(find.byType(ConfirmRequestStageView), findsNothing);
    expect(harness.requests.details['first']!.status, 'PICKED_UP');
    expect(harness.selectedActions(tester).request.id, 'second');
    expect(harness.routes.current.stops.map((stop) => stop.requestId), [
      'second',
      'second',
      'first',
    ]);
    await arrive('second');
    harness.evidence.pickupResponseStatus = 'IN_TRANSIT';
    await _sendPhoto(tester, 'recolección');
    expect(harness.selectedActions(tester).stopType, 'ENTREGA');
    await arrive('second', delivery: true);
    await _sendPhoto(tester, 'entrega');
    expect(harness.selectedActions(tester).request.id, 'first');
    expect(harness.selectedActions(tester).stopType, 'ENTREGA');
    await arrive('first', delivery: true);
    await _sendPhoto(tester, 'entrega');
    expect(harness.operations, [
      'upload:first:FOTO_RECOLECCION',
      'upload:second:FOTO_RECOLECCION',
      'upload:second:FOTO_ENTREGA',
      'upload:first:FOTO_ENTREGA',
    ]);
    expect(harness.requests.transitions, isEmpty);
    expect(harness.routes.current.flow!.hasNoServices, isTrue);
    expect(harness.routes.calculateCalls, 0);
  });

  testWidgets('recupera PICKED_UP tras respuesta perdida y sigue otra parada', (
    tester,
  ) async {
    final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
      'first': _request('first', 'AT_PICKUP'),
      'second': _request('second', 'GOING_TO_PICKUP'),
    });
    harness.evidence.pickupResponseStatus = 'PICKED_UP';
    harness.evidence.loseResponse = true;
    harness.evidence.onUpload = (id, type) {
      harness.requests.details[id] = _request(id, 'PICKED_UP');
      harness.routes.current = _route([
        _stop('second', 'GOING_TO_PICKUP'),
        _stop(id, 'PICKED_UP', type: 'ENTREGA', order: 2),
      ]);
    };
    await harness.pump(tester);
    await _openAction(tester, 'Tomar foto de recolección');
    await _sendPhoto(tester, 'recolección');
    await tester.tap(find.text('Verificar estado del servicio'));
    await _pumpChanges(tester);
    expect(harness.evidence.uploads, hasLength(1));
    expect(find.byType(ConfirmRequestStageView), findsNothing);
    expect(harness.selectedActions(tester).request.id, 'second');
    expect(harness.requests.transitions, isEmpty);
    expect(harness.routes.calculateCalls, 0);
  });

  testWidgets(
    'no envía ni duplica fotos mientras espera la captura de ubicación',
    (tester) async {
      final pending = Completer<DeviceLocation>();
      final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
        'first': _request('first', 'AT_PICKUP'),
      });
      await harness.pump(tester, location: pending.future);
      await _openAction(tester, 'Tomar foto de recolección');
      await tester.tap(find.widgetWithText(FilledButton, 'Tomar foto'));
      await _pumpChanges(tester);
      final send = find.widgetWithText(
        FilledButton,
        'Enviar foto y confirmar recolección',
      );
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      expect(harness.evidence.uploads, isEmpty);
      pending.complete(
        DeviceLocation(
          latitude: 14.071,
          longitude: -87.191,
          recordedAt: DateTime.utc(2026, 10, 26),
        ),
      );
      await _pumpChanges(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Temperatura del contenedor (°C)'),
        '4.50',
      );
      final callback = tester.widget<FilledButton>(send).onPressed!;
      callback();
      callback();
      await _pumpChanges(tester);
      expect(harness.evidence.uploads, hasLength(1));
      expect(harness.requests.transitions, isEmpty);
    },
  );
  testWidgets(
    'el encargo especial conserva señal manual y la foto finaliza sin otra transición',
    (tester) async {
      final harness = _MapHarness(
        _route([_stop('first', 'IN_TRANSIT', type: 'ENVIO_ESPECIAL')]),
        {'first': _request('first', 'IN_TRANSIT', special: true)},
      );
      harness.requests.onTransition = (id, status) {
        harness.routes.current = _route([
          _stop(id, status, type: 'ENVIO_ESPECIAL'),
        ]);
      };
      await harness.pump(tester);
      expect(find.text('Tomar foto de entrega'), findsNothing);
      await _openAction(tester, 'Finalizar encargo');
      final signal = find.descendant(
        of: find.byType(TransitionRequestView),
        matching: find.widgetWithText(FilledButton, 'Finalizar encargo'),
      );
      await tester.ensureVisible(signal);
      await tester.tap(signal);
      await _pumpChanges(tester);
      expect(harness.requests.transitions.single.target, 'AT_DESTINATION');
      await _openAction(tester, 'Tomar foto de entrega');
      await _sendPhoto(tester, 'entrega');
      expect(harness.requests.transitions, hasLength(1));
      expect(harness.requests.details['first']!.status, 'DELIVERED');
      expect(harness.evidence.uploads.single.type, 'FOTO_ENTREGA');
      expect(harness.routes.calculateCalls, 0);
    },
  );
  testWidgets(
    'abre el mapa del flujo sin aceptar y vuelve a espera tras la última foto',
    (tester) async {
      final harness = _MapHarness(
        _route([_stop('first', 'IN_TRANSIT', type: 'ENTREGA')]),
        {'first': _request('first', 'IN_TRANSIT')},
      );
      await harness.pump(tester, arrivals: true, startAtHome: true);
      expect(find.byType(DriverRouteMapView), findsOneWidget);
      expect(harness.requests.transitions, isEmpty);
      harness.routes.current = _route([
        _stop('first', 'AT_DESTINATION', type: 'ENTREGA'),
      ], arrival: _arrival(delivery: true));
      harness.requests.details['first'] = _request('first', 'AT_DESTINATION');
      _signalArrival(tester, _arrival(delivery: true));
      await _pumpChanges(tester);
      await _pumpChanges(tester);
      expect(find.byType(ConfirmRequestStageView), findsOneWidget);
      await _sendPhoto(tester, 'entrega');
      await _pumpChanges(tester);
      await _pumpChanges(tester);
      expect(find.byType(DriverRouteMapView), findsNothing);
      expect(find.text('Pantalla de espera'), findsOneWidget);
      expect(harness.operations, ['upload:first:FOTO_ENTREGA']);
    },
  );
  testWidgets('la llegada abre solo la foto, sin transición adicional', (
    tester,
  ) async {
    final harness = _MapHarness(
      _route([_stop('first', 'AT_PICKUP')], arrival: _arrival()),
      {'first': _request('first', 'AT_PICKUP')},
    );
    await harness.pump(tester, arrivals: true);
    expect(find.byType(ConfirmRequestStageView), findsOneWidget);
    expect(find.byType(TransitionRequestView), findsNothing);
    expect(harness.operations, isEmpty);
  });

  testWidgets('flujo_actual recupera la foto incluso sin llegada_actual', (
    tester,
  ) async {
    final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
      'first': _request('first', 'AT_PICKUP'),
    });
    await harness.pump(tester, arrivals: true);
    expect(find.byType(ConfirmRequestStageView), findsOneWidget);
    expect(harness.requests.transitions, isEmpty);
  });

  testWidgets('en camino no hay inicio, aceptación ni selectores', (
    tester,
  ) async {
    final harness = _MapHarness(
      _route([
        _stop('first', 'GOING_TO_PICKUP'),
        _stop('second', 'ASSIGNED', order: 2),
      ]),
      {
        'first': _request('first', 'GOING_TO_PICKUP'),
        'second': _request('second', 'ASSIGNED'),
      },
    );
    await harness.pump(tester);
    await _expandPanel(tester);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Ir a recolectar'), findsNothing);
    expect(find.text('Iniciar traslado'), findsNothing);
    expect(find.text('Confirmar recolección'), findsNothing);
    expect(find.text('Aceptar'), findsNothing);
    expect(harness.operations, isEmpty);
  });

  testWidgets('foto de recolección avanza a entrega sin POST de transición', (
    tester,
  ) async {
    final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
      'first': _request('first', 'AT_PICKUP'),
    });
    await harness.pump(tester);
    final map = tester.element(find.byKey(const Key('map-surface')));
    await _openAction(tester, 'Tomar foto de recolección');
    await _sendPhoto(tester, 'recolección');
    expect(harness.operations, ['upload:first:FOTO_RECOLECCION']);
    expect(harness.selectedActions(tester).request.status, 'IN_TRANSIT');
    expect(harness.selectedActions(tester).stopType, 'ENTREGA');
    expect(tester.element(find.byKey(const Key('map-surface'))), same(map));
    expect(find.byType(ConfirmRequestStageView), findsNothing);
    expect(harness.routes.calculateCalls, 0);
  });

  testWidgets(
    'foto de entrega selecciona automáticamente el siguiente servicio',
    (tester) async {
      final harness = _MapHarness(
        _route([
          _stop('first', 'AT_DESTINATION', type: 'ENTREGA'),
          _stop('second', 'ASSIGNED', order: 2),
        ]),
        {
          'first': _request('first', 'AT_DESTINATION'),
          'second': _request('second', 'ASSIGNED'),
        },
      );
      harness.evidence.saved['first'] = [_evidence('first', 'FOTO_ENTREGA')];
      await harness.pump(tester);
      await _openAction(tester, 'Tomar foto de entrega');
      await _sendPhoto(tester, 'entrega');
      expect(harness.operations, ['upload:first:FOTO_ENTREGA']);
      expect(harness.selectedActions(tester).request.id, 'second');
      expect(find.byType(TransitionRequestView), findsNothing);
      expect(harness.requests.transitions, isEmpty);
    },
  );

  testWidgets('respuesta perdida consulta estado sin reenviar la foto', (
    tester,
  ) async {
    final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
      'first': _request('first', 'AT_PICKUP'),
    });
    harness.evidence.loseResponse = true;
    await harness.pump(tester);
    await _openAction(tester, 'Tomar foto de recolección');
    await _sendPhoto(tester, 'recolección');
    expect(find.text('Verificar estado del servicio'), findsOneWidget);
    await tester.tap(find.text('Verificar estado del servicio'));
    await _pumpChanges(tester);
    expect(harness.evidence.uploads, hasLength(1));
    expect(harness.requests.transitions, isEmpty);
    expect(find.byType(ConfirmRequestStageView), findsNothing);
    expect(harness.selectedActions(tester).request.status, 'IN_TRANSIT');
  });

  testWidgets(
    'una foto rechazada no se reenvía hasta verificar y confirmar manualmente',
    (tester) async {
      final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
        'first': _request('first', 'AT_PICKUP'),
      });
      harness.evidence.uploadFailure = const AppFailure(
        message: 'Imagen no válida.',
        statusCode: 400,
      );
      await harness.pump(tester);
      await _openAction(tester, 'Tomar foto de recolección');
      await _sendPhoto(tester, 'recolección');
      expect(find.textContaining('HTTP 400'), findsOneWidget);
      await tester.tap(find.text('Verificar estado del servicio'));
      await _pumpChanges(tester);
      expect(harness.evidence.uploads, hasLength(1));
      expect(
        find.text('La foto no se registró. Puedes enviarla de nuevo.'),
        findsOneWidget,
      );
      harness.evidence.uploadFailure = null;
      await tester.tap(find.text('Enviar foto y confirmar recolección'));
      await _pumpChanges(tester);
      expect(harness.evidence.uploads, hasLength(2));
      expect(harness.requests.transitions, isEmpty);
    },
  );

  testWidgets('después de 201 un fallo de refresco reintenta solo lecturas', (
    tester,
  ) async {
    final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
      'first': _request('first', 'AT_PICKUP'),
    });
    await harness.pump(tester);
    await _openAction(tester, 'Tomar foto de recolección');
    harness.routes.readFailure = const AppFailure(message: 'Sin conexión.');
    await _sendPhoto(tester, 'recolección');
    expect(find.text('Actualizar servicio'), findsOneWidget);
    harness.routes.readFailure = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Actualizar servicio'));
    await _pumpChanges(tester);
    expect(harness.evidence.uploads, hasLength(1));
    expect(harness.requests.transitions, isEmpty);
    expect(find.byType(ConfirmRequestStageView), findsNothing);
  });

  testWidgets('GPS apagado bloquea la foto sin alterar el estado', (
    tester,
  ) async {
    final gps = StreamController<bool>()..add(true);
    addTearDown(gps.close);
    final harness = _MapHarness(_route([_stop('first', 'AT_PICKUP')]), {
      'first': _request('first', 'AT_PICKUP'),
    });
    await harness.pump(tester, gpsEnabled: gps.stream);
    await _openAction(tester, 'Tomar foto de recolección');
    await tester.tap(find.widgetWithText(FilledButton, 'Tomar foto'));
    await _pumpChanges(tester);
    gps.add(false);
    await _pumpChanges(tester);
    final button = find.widgetWithText(
      FilledButton,
      'Enviar foto y confirmar recolección',
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(harness.operations, isEmpty);
    gps.add(true);
    await _pumpChanges(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Temperatura del contenedor (°C)'),
      '4.50',
    );
    await tester.tap(button);
    await _pumpChanges(tester);
    expect(harness.operations, ['upload:first:FOTO_RECOLECCION']);
  });

  testWidgets('la llegada en segundo plano espera reanudación', (tester) async {
    final harness = _MapHarness(_route([_stop('first', 'GOING_TO_PICKUP')]), {
      'first': _request('first', 'GOING_TO_PICKUP'),
    });
    await harness.pump(tester, arrivals: true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    harness.routes.current = _route([
      _stop('first', 'AT_PICKUP'),
    ], arrival: _arrival());
    harness.requests.details['first'] = _request('first', 'AT_PICKUP');
    _signalArrival(tester, _arrival());
    await _pumpChanges(tester);
    expect(find.byType(ConfirmRequestStageView), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpChanges(tester);
    await _pumpChanges(tester);
    expect(find.byType(ConfirmRequestStageView), findsOneWidget);
    expect(harness.requests.transitions, isEmpty);
  });

  testWidgets('no repite la pantalla de una llegada ya mostrada', (
    tester,
  ) async {
    final harness = _MapHarness(
      _route([_stop('first', 'AT_PICKUP')], arrival: _arrival()),
      {'first': _request('first', 'AT_PICKUP')},
    );
    await harness.pump(tester, arrivals: true);
    Navigator.of(tester.element(find.byType(ConfirmRequestStageView))).pop();
    await _pumpChanges(tester);
    _signalArrival(tester, _arrival());
    await _pumpChanges(tester);
    expect(find.byType(ConfirmRequestStageView), findsNothing);
  });
}

Future<void> _sendPhoto(WidgetTester tester, String stage) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Tomar foto'));
  await _pumpChanges(tester);
  if (stage == 'recolección') {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Temperatura del contenedor (°C)'),
      '4.50',
    );
  }
  await tester.tap(
    find.widgetWithText(FilledButton, 'Enviar foto y confirmar $stage'),
  );
  await _pumpChanges(tester);
}

Future<void> _expandPanel(WidgetTester tester) async {
  final panel = find
      .descendant(
        of: find.byType(DriverRouteMapView),
        matching: find.byType(ListView),
      )
      .first;
  await tester.drag(panel, const Offset(0, -500));
  await tester.pumpAndSettle();
}

Future<void> _openAction(WidgetTester tester, String label) async {
  await _expandPanel(tester);
  final button = find.descendant(
    of: find.byType(DriverRequestActions),
    matching: find.widgetWithText(FilledButton, label),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await _pumpChanges(tester);
}

Future<void> _pumpChanges(WidgetTester tester) async {
  // The underlying action keeps a spinner while its modal is open.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

class _MapHarness {
  _MapHarness(this.initial, Map<String, ServiceRequestDetail> details) {
    routes = _FakeRoutes(initial);
    requests = _FakeRequests(details, operations);
    evidence = _FakeEvidence(operations);
    evidence.onUpload = (id, type) {
      final status = type == 'FOTO_RECOLECCION' ? 'IN_TRANSIT' : 'DELIVERED';
      requests.details[id] = _request(
        id,
        status,
        special: requests.details[id]!.isSpecial,
      );
      final remaining = routes.current.stops
          .where((stop) => stop.requestId != id)
          .toList();
      routes.current = _route([
        if (status == 'IN_TRANSIT') _stop(id, status, type: 'ENTREGA'),
        ...remaining,
      ]);
    };
  }

  final DriverRoute initial;
  final operations = <String>[];
  late final _FakeRoutes routes;
  late final _FakeRequests requests;
  late final _FakeEvidence evidence;

  DriverRequestActions selectedActions(WidgetTester tester) =>
      tester.widget<DriverRequestActions>(find.byType(DriverRequestActions));

  Future<void> pump(
    WidgetTester tester, {
    Stream<bool>? gpsEnabled,
    bool arrivals = false,
    bool startAtHome = false,
    Future<DeviceLocation>? location,
    _ArrivalHistory? history,
  }) async {
    tester.view.physicalSize = const Size(600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trackingConfigurationProvider.overrideWith(
            (ref) async => TrackingConfiguration.defaults,
          ),
          appConfigProvider.overrideWithValue(
            AppConfig(
              mode: AppMode.corporate,
              apiBaseUri: Uri.parse('http://localhost:8001/api/v1/'),
            ),
          ),
          arrivalPresentationStoreProvider.overrideWithValue(
            history ?? _ArrivalHistory(),
          ),
          requestsRepositoryProvider.overrideWithValue(requests),
          routesRepositoryProvider.overrideWithValue(routes),
          evidenceRepositoryProvider.overrideWithValue(evidence),
          evidenceCaptureServiceProvider.overrideWithValue(_FakeCamera()),
          deviceLocationServiceProvider.overrideWithValue(
            _FakeLocation(location),
          ),
          locationServiceEnabledProvider.overrideWith(
            (ref) => gpsEnabled ?? Stream.value(true),
          ),
          activeShiftControllerProvider.overrideWith((ref) async => _shift),
          requestStageActionsControllerProvider.overrideWithValue(
            RequestStageActionsController(
              evidence,
              requests,
              _UnusedTracking(),
              routeReader: () => routes.getMyRoute(),
            ),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final map = DriverRouteMapView(
              route: initial,
              roadRoute: initial.roadRoute,
              profile: _driver,
              canCalculate: true,
              mapForTesting: const ColoredBox(
                key: Key('map-surface'),
                color: Colors.blueGrey,
              ),
            );
            return MaterialApp(
              navigatorObservers: [ref.watch(routeActivityObserverProvider)],
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                settings: RouteSettings(
                  name: startAtHome ? 'home' : 'driver-route-map',
                ),
                builder: (_) => arrivals
                    ? DriverArrivalListener(
                        profile: _driver,
                        mapViewBuilderForTesting: (route) => DriverRouteMapView(
                          route: route,
                          roadRoute: route.roadRoute,
                          profile: _driver,
                          canCalculate: true,
                          mapForTesting: const ColoredBox(
                            key: Key('map-surface'),
                            color: Colors.blueGrey,
                          ),
                        ),
                        child: startAtHome
                            ? const Scaffold(body: Text('Pantalla de espera'))
                            : map,
                      )
                    : map,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

class _FakeRequests implements RequestsRepository {
  _FakeRequests(this.details, this.operations);

  final Map<String, ServiceRequestDetail> details;
  final List<String> operations;
  final reads = <String>[];
  final transitions = <({String id, String target})>[];
  void Function(String id, String target)? onTransition;
  AppFailure? failure;

  @override
  Future<ServiceRequestDetail> getRequest(String requestId) async {
    reads.add(requestId);
    return details[requestId]!;
  }

  @override
  Future<ServiceRequestDetail> transitionRequest(
    String requestId,
    RequestTransitionInput input,
  ) async {
    transitions.add((id: requestId, target: input.targetStatus));
    operations.add('transition:$requestId:${input.targetStatus}');
    if (failure case final error?) throw error;
    final updated = _request(
      requestId,
      input.targetStatus,
      special: details[requestId]!.isSpecial,
    );
    details[requestId] = updated;
    onTransition?.call(requestId, input.targetStatus);
    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRoutes implements RoutesRepository {
  _FakeRoutes(this.current);

  DriverRoute current;
  int readCalls = 0;
  int calculateCalls = 0;
  AppFailure? readFailure;

  @override
  Future<DriverRoute> getMyRoute() async {
    readCalls++;
    if (readFailure case final error?) throw error;
    return current;
  }

  @override
  Future<RoadRoute> calculate(CalculateRouteInput input) async {
    calculateCalls++;
    return current.roadRoute;
  }
}

class _FakeEvidence implements EvidenceRepository {
  _FakeEvidence(this.operations);

  final List<String> operations;
  final saved = <String, List<OperationalEvidence>>{};
  final uploads = <EvidenceUploadInput>[];
  void Function(String id, String type)? onUpload;
  bool loseResponse = false;
  String pickupResponseStatus = 'IN_TRANSIT';
  AppFailure? uploadFailure;

  @override
  Future<PaginatedResult<OperationalEvidence>> getRequestEvidence({
    required String requestId,
    required int page,
  }) async {
    final items = saved[requestId] ?? const <OperationalEvidence>[];
    return PaginatedResult(
      count: items.length,
      items: items,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  Future<OperationalEvidence> uploadRequestEvidence(
    String requestId,
    EvidenceUploadInput input,
  ) async {
    operations.add('upload:$requestId:${input.type}');
    uploads.add(input);
    if (uploadFailure case final error?) throw error;
    final evidence = _evidence(
      requestId,
      input.type!,
      status: input.type == 'FOTO_RECOLECCION'
          ? pickupResponseStatus
          : 'DELIVERED',
    );
    saved.putIfAbsent(requestId, () => []).add(evidence);
    onUpload?.call(requestId, input.type!);
    if (loseResponse) {
      throw const AppFailure(message: 'Se perdió la respuesta.');
    }
    return evidence;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCamera extends EvidenceCaptureService {
  @override
  Future<XFile?> recoverLostPhoto() async => null;

  @override
  Future<XFile?> takePhoto() async => XFile.fromData(
    Uint8List.fromList([1, 2, 3]),
    path: 'test-photo.jpg',
    name: 'test-photo.jpg',
    mimeType: 'image/jpeg',
  );
}

class _FakeLocation extends DeviceLocationService {
  const _FakeLocation([this.result]);
  final Future<DeviceLocation>? result;

  @override
  Future<DeviceLocation> getCurrentLocation() async =>
      result ??
      DeviceLocation(
        latitude: 14.071,
        longitude: -87.191,
        recordedAt: DateTime.utc(2026, 10, 22),
      );
}

class _UnusedTracking implements TrackingQueueCoordinator {
  @override
  Future<TrackingPointInput> capture(
    String shiftId,
    DeviceLocation location, {
    DateTime? recordedAt,
  }) async => TrackingPointInput(
    clientId: 'point',
    latitude: location.latitudeText,
    longitude: location.longitudeText,
    recordedAt: recordedAt ?? DateTime.utc(2026, 10, 26),
  );
  @override
  Future<int> flush(String shiftId, {required int maximumBatchSize}) async => 0;
  @override
  Future<List<GpsSessionManifest>> manifest(String shiftId) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DriverRouteStop _stop(
  String id,
  String status, {
  int order = 1,
  String type = 'RECOLECCION',
}) => DriverRouteStop(
  order: order,
  requestId: id,
  requestNumber: 'SOL-$id',
  priority: 'NORMAL',
  modality: 'ENTRE_SUCURSALES',
  requestStatus: status,
  type: type,
  routePresentation: type == 'ENVIO_ESPECIAL' ? 'SOLO_KILOMETROS' : 'MAPA',
  location: type == 'ENVIO_ESPECIAL'
      ? null
      : RouteLocation(
          id: 'location-$id-$type',
          name: 'Sucursal $id $type',
          address: 'Dirección $id',
          latitude: '14.072300',
          longitude: '-87.192100',
        ),
);

DriverRouteFlow _flow(DriverRouteStop stop) => DriverRouteFlow(
  mode: 'AUTOMATICO',
  requestId: stop.requestId,
  status: stop.requestStatus,
  stopType: stop.type,
  segmentId: '${stop.requestId}:${stop.type}',
  requiresSpecialCompletion:
      stop.type == 'ENVIO_ESPECIAL' && stop.requestStatus == 'IN_TRANSIT',
  screen: stop.type == 'ENVIO_ESPECIAL' && stop.requestStatus == 'IN_TRANSIT'
      ? 'FINALIZAR_ESPECIAL'
      : stop.requestStatus == 'AT_PICKUP'
      ? 'RECOLECCION'
      : stop.requestStatus == 'AT_DESTINATION'
      ? 'ENTREGA'
      : 'MAPA',
  requiredEvidence: stop.requestStatus == 'AT_PICKUP'
      ? 'FOTO_RECOLECCION'
      : stop.requestStatus == 'AT_DESTINATION'
      ? 'FOTO_ENTREGA'
      : null,
);

DriverRoute _route(
  List<DriverRouteStop> stops, {
  DriverRouteStop? next,
  DriverArrival? arrival,
}) => DriverRoute(
  driverId: 'driver-id',
  shiftId: 'shift-id',
  currentVersion: 1,
  orderType: 'ASIGNACION',
  routeCalculated: false,
  currentArrival: arrival,
  flow: stops.isEmpty
      ? const DriverRouteFlow(mode: 'AUTOMATICO', screen: 'SIN_SERVICIOS')
      : _flow(next ?? stops.first),
  stops: stops,
  nextStop: next ?? (stops.isEmpty ? null : stops.first),
  map: const RouteMapConfiguration(
    mode: 'INTEGRADO',
    provider: 'GOOGLE_MAPS',
    showMap: true,
    showRoute: false,
    allowsExternalNavigation: false,
  ),
  roadRoute: const RoadRoute(
    status: 'PENDIENTE',
    provider: 'GOOGLE_MAPS',
    includesCompletedSegments: false,
    metricsInResponse: false,
  ),
);

ServiceRequestDetail _request(
  String id,
  String status, {
  String driverId = 'driver-id',
  bool special = false,
}) => ServiceRequestDetail(
  summary: ServiceRequestSummary(
    id: id,
    number: 'SOL-$id',
    companyId: 'company-id',
    requestedById: 'requester-id',
    assignedDriverId: driverId,
    priority: 'NORMAL',
    modality: special ? 'ESPECIAL' : 'ENTRE_SUCURSALES',
    serviceType: const RequestServiceType(
      id: 'service-id',
      code: 'PAQUETE',
      name: 'Paquete',
    ),
    origin: const RequestPoint(
      id: 'origin-id',
      name: 'Sucursal de origen',
      address: 'Dirección de origen',
    ),
    destination: special
        ? null
        : const RequestPoint(
            id: 'destination-id',
            name: 'Sucursal de destino',
            address: 'Dirección de destino',
          ),
    routePresentation: 'MAPA',
    status: status,
    createdAt: DateTime.utc(2026, 10, 22),
  ),
  items: const [],
  events: const [],
  assignments: const [],
  specialMovement: special
      ? SpecialRequestMovement(
          id: 'movement',
          driverId: driverId,
          shiftId: 'shift-id',
          status: 'ACTIVO',
          startedAt: DateTime.utc(2026, 10, 26),
          recordsConsidered: 0,
          recordsDiscarded: 0,
        )
      : null,
  updatedAt: DateTime.utc(2026, 10, 22),
);

OperationalEvidence _evidence(
  String requestId,
  String type, {
  String? status,
}) => OperationalEvidence(
  id: '$requestId-$type',
  requestId: requestId,
  requestStatus:
      status ?? (type == 'FOTO_RECOLECCION' ? 'IN_TRANSIT' : 'DELIVERED'),
  driverId: 'driver-id',
  type: type,
  contentType: 'image/jpeg',
  sizeBytes: 3,
  latitude: '14.071000',
  longitude: '-87.191000',
  capturedAt: DateTime.utc(2026, 10, 22),
  fileAvailable: true,
  createdAt: DateTime.utc(2026, 10, 22),
);

final _shift = DriverShift.fromJson({
  'id': 'shift-id',
  'repartidor_id': 'driver-id',
  'estado': 'ACTIVA',
  'iniciada_en': '2026-10-22T12:00:00Z',
  'creado_en': '2026-10-22T12:00:00Z',
  'actualizado_en': '2026-10-22T12:00:00Z',
});

final _driver = UserProfile.fromJson({
  'usuario': {
    'id': 'driver-user-id',
    'correo': 'driver@example.com',
    'nombres': 'Motorista',
    'apellidos': 'Prueba',
    'estado': 'ACTIVO',
  },
  'roles': [
    {
      'codigo': 'REPARTIDOR_CORPORATIVO',
      'nombre': 'Motorista',
      'tipo_alcance': 'EMPRESA',
      'empresa_id': 'company-id',
    },
  ],
  'permisos': [
    'solicitud.ver_asignadas',
    'solicitud.actualizar_estado',
    'evidencia.ver',
    'evidencia.crear',
    'ruta.calcular',
    'repartidor.registrar_ubicacion',
  ],
});

DriverArrival _arrival({bool delivery = false}) => DriverArrival(
  eventId: delivery ? 'event-delivery' : 'event-pickup',
  requestId: 'first',
  status: delivery ? 'AT_DESTINATION' : 'AT_PICKUP',
  stopType: delivery ? 'ENTREGA' : 'RECOLECCION',
  detectedAt: DateTime.utc(2026, 10, 23, 18),
  source: 'GPS',
  screen: delivery ? 'ENTREGA' : 'RECOLECCION',
);

void _signalArrival(WidgetTester tester, DriverArrival arrival) {
  ProviderScope.containerOf(tester.element(find.byType(DriverRouteMapView)))
      .read(driverArrivalsProvider.notifier)
      .received([arrival]);
}

class _ArrivalHistory implements ArrivalPresentationStore {
  final events = <String>{};
  @override
  Future<bool> wasShown(String scope, String eventId) async =>
      events.contains('$scope|$eventId');
  @override
  Future<void> markShown(String scope, String eventId) async {
    events.add('$scope|$eventId');
  }
}
