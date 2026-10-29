import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/tracking/storage/arrival_presentation_store.dart';

void main() {
  test('recuerda evento tras recrear store y aísla cuenta/servidor', () async {
    final disk = _MemorySecureStore();
    final first = SecureArrivalPresentationStore(disk);
    expect(await first.wasShown('corporate|driver-1', 'event-1'), isFalse);
    await first.markShown('corporate|driver-1', 'event-1');
    final restored = SecureArrivalPresentationStore(disk);
    expect(await restored.wasShown('corporate|driver-1', 'event-1'), isTrue);
    expect(await restored.wasShown('corporate|driver-2', 'event-1'), isFalse);
    expect(await restored.wasShown('network|driver-1', 'event-1'), isFalse);
    await restored.markShown('corporate|driver-1', 'event-1');
    expect(disk.data.values.single, '["event-1"]');
  });
}

class _MemorySecureStore implements SecureStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}
