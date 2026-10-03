abstract final class AppDateFormat {
  static String dateTime(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.day)}/${_two(local.month)}/${local.year} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  static String durationMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$remaining min';
    if (remaining == 0) return '$hours h';
    return '$hours h $remaining min';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
