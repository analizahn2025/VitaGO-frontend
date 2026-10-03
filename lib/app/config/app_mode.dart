enum AppMode {
  corporate,
  external;

  static AppMode parse(String value) {
    return switch (value.trim().toUpperCase()) {
      'CORPORATE' || 'CORPORATIVO' => AppMode.corporate,
      'EXTERNAL' || 'EXTERNO' => AppMode.external,
      _ => throw const FormatException(
        'APP_MODE debe ser CORPORATE o EXTERNAL.',
      ),
    };
  }

  String get apiValue => switch (this) {
    AppMode.corporate => 'CORPORATE',
    AppMode.external => 'EXTERNAL',
  };

  String get productName => switch (this) {
    AppMode.corporate => 'VitaGo Corporate',
    AppMode.external => 'VitaGo Network',
  };
}
