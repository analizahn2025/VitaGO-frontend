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
    this.pendingPoints = 0,
    this.error,
  });

  final bool active;
  final bool sending;
  final DateTime? lastSyncedAt;
  final int pendingPoints;
  final String? error;

  DriverTrackingStatus copyWith({
    bool? active,
    bool? sending,
    DateTime? lastSyncedAt,
    int? pendingPoints,
    String? error,
    bool clearError = false,
  }) {
    return DriverTrackingStatus(
      active: active ?? this.active,
      sending: sending ?? this.sending,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingPoints: pendingPoints ?? this.pendingPoints,
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

  void markSynced(DateTime value, {int pendingPoints = 0}) {
    state = state.copyWith(
      active: true,
      sending: false,
      lastSyncedAt: value,
      pendingPoints: pendingPoints,
      clearError: true,
    );
  }

  void setPendingPoints(int value) {
    state = state.copyWith(pendingPoints: value);
  }

  void reportError(String message) {
    state = state.copyWith(sending: false, error: message);
  }
}
