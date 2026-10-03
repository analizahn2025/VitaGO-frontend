enum ScopeType {
  global,
  company,
  branch;

  factory ScopeType.parse(String value) {
    return switch (value.trim().toUpperCase()) {
      'GLOBAL' => ScopeType.global,
      'EMPRESA' => ScopeType.company,
      'SUCURSAL' => ScopeType.branch,
      _ => throw FormatException('Tipo de alcance no reconocido: $value'),
    };
  }

  String get apiValue => switch (this) {
    ScopeType.global => 'GLOBAL',
    ScopeType.company => 'EMPRESA',
    ScopeType.branch => 'SUCURSAL',
  };

  String get label => switch (this) {
    ScopeType.global => 'Global',
    ScopeType.company => 'Empresa',
    ScopeType.branch => 'Sucursal',
  };
}
