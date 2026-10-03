import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/routing/app_router.dart';

void main() {
  test('construye una ruta directa para el detalle de solicitud', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    router.goNamed(
      'request-detail',
      pathParameters: {'requestId': 'request-id'},
    );

    expect(
      router.routeInformationProvider.value.uri.path,
      '/solicitudes/request-id',
    );
  });
}
