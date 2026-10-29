import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

abstract final class AppDateFormat {
  static bool _timeZonesInitialized = false;

  static String dateTime(DateTime value, {String? timeZone}) {
    final displayed = _inTimeZone(value, timeZone);
    return '${_two(displayed.day)}/${_two(displayed.month)}/${displayed.year} '
        '${_two(displayed.hour)}:${_two(displayed.minute)}';
  }

  static String durationMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$remaining min';
    if (remaining == 0) return '$hours h';
    return '$hours h $remaining min';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static DateTime _inTimeZone(DateTime value, String? timeZone) {
    if (timeZone == null || timeZone.trim().isEmpty) return value.toLocal();
    if (!_timeZonesInitialized) {
      timezone_data.initializeTimeZones();
      _timeZonesInitialized = true;
    }
    try {
      return timezone.TZDateTime.from(
        value.toUtc(),
        timezone.getLocation(timeZone),
      );
    } on timezone.LocationNotFoundException {
      return value.toLocal();
    }
  }
}
