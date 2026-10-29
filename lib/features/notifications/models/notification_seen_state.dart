import 'package:vitago_app/features/notifications/models/driver_notification.dart';

/// "Seen in the bell" is local presentation state, not the server's read flag.
class NotificationSeenState {
  const NotificationSeenState({
    this.opened = false,
    this.through,
    this.ids = const {},
  });

  factory NotificationSeenState.fromJson(Map<String, dynamic> json) =>
      NotificationSeenState(
        opened: json['opened'] == true,
        through: json['through'] is String
            ? DateTime.tryParse(json['through'] as String)?.toUtc()
            : null,
        ids: Set.unmodifiable(
          (json['ids'] as List? ?? const []).whereType<String>(),
        ),
      );

  final bool opened;
  final DateTime? through;
  final Set<String> ids;

  bool isNew(DriverNotification item) {
    if (item.isRead || ids.contains(item.id)) return false;
    final date = item.createdAt;
    // ID ties preserve a newly received event with the same server timestamp.
    return through == null || date == null || !date.isBefore(through!);
  }

  NotificationSeenState acknowledge(Iterable<DriverNotification> items) {
    var boundary = through;
    final seenIds = {...ids};
    for (final item in items) {
      seenIds.add(item.id);
      if (item.createdAt case final date?) {
        if (boundary == null || date.isAfter(boundary)) boundary = date.toUtc();
      }
    }
    return NotificationSeenState(
      opened: true,
      through: boundary,
      ids: Set.unmodifiable(
        seenIds.skip(seenIds.length > 512 ? seenIds.length - 512 : 0),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'opened': opened,
    'through': through?.toUtc().toIso8601String(),
    'ids': ids.toList(),
  };
}
