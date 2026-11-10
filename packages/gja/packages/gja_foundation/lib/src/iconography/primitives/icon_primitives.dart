/// Fonte de ícones e escala primitiva de tamanhos de ícone.
///
/// Nível: primitivo.
///
/// A fonte Lucide (licença ISC) é empacotada em `gja_foundation`. Com
/// [fontFamily] e [fontPackage], uma aplicação declara qualquer outro ícone da
/// fonte como constante, pelo código do mapa oficial
/// (`fonts/lucide/codepoints.json`):
///
/// ```dart
/// const anchor = IconData(
///   0xe03f,
///   fontFamily: GjaIconPrimitives.fontFamily,
///   fontPackage: GjaIconPrimitives.fontPackage,
/// );
/// ```
///
/// Widgets não leem os tamanhos daqui: eles usam `GjaIconTokens`.
abstract final class GjaIconPrimitives {
  /// Família da fonte de ícones.
  static const fontFamily = 'Lucide';

  /// Pacote que empacota a fonte de ícones.
  static const fontPackage = 'gja_foundation';

  /// 12 px.
  static const size12 = 12.0;

  /// 16 px.
  static const size16 = 16.0;

  /// 20 px.
  static const size20 = 20.0;

  /// 24 px.
  static const size24 = 24.0;

  /// 32 px.
  static const size32 = 32.0;

  /// 40 px.
  static const size40 = 40.0;

  /// 48 px.
  static const size48 = 48.0;

  /// Escala completa, em ordem crescente.
  static const sizes = <String, double>{
    'size12': size12,
    'size16': size16,
    'size20': size20,
    'size24': size24,
    'size32': size32,
    'size40': size40,
    'size48': size48,
  };
}
