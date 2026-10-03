import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverTrackingStatusProvider =
    NotifierProvider<DriverTrackingStatusController, DriverTrackingStatus>(
      DriverTrackingStatusController.new,
    );

class DriverTrackingStatus {
  const DriverTrackingStatus({
    this.active = false,
    this.sending = false,
    this.lastSyncedAt,
    this.error,
  });

  final bool active;
  final bool sending;
  final DateTime? lastSyncedAt;
  final String? error;

  DriverTrackingStatus copyWith({
    bool? active,
    bool? sending,
    DateTime? lastSyncedAt,
    String? error,
    bool clearError = false,
  }) {
    return DriverTrackingStatus(
      active: active ?? this.active,
      sending: sending ?? this.sending,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class DriverTrackingStatusController extends Notifier<DriverTrackingStatus> {
  @override
  DriverTrackingStatus build() => const DriverTrackingStatus();

  void setActive(bool value) {
    state = state.copyWith(active: value, clearError: value);
  }

  void setSending(bool value) {
    state = state.copyWith(sending: value);
  }

  void markSynced(DateTime value) {
    state = state.copyWith(
      active: true,
      sending: false,
      lastSyncedAt: value,
      clearError: true,
    );
  }

  void reportError(String message) {
    state = state.copyWith(sending: false, error: message);
  }
}
