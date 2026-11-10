import 'dart:ui' show Color;

/// Razão de contraste WCAG 2.1 entre duas cores opacas, de 1 a 21.
///
/// Simétrica na ordem dos argumentos. Para uma cor translúcida, use
/// [gjaContrastRatioOver], que a compõe sobre o fundo.
///
/// Lança [ArgumentError] se alguma das cores não for opaca.
double gjaContrastRatio(Color a, Color b) {
  _requireOpaque(a, 'a');
  _requireOpaque(b, 'b');
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Razão de contraste de [foreground], possivelmente translúcida, composta
/// sobre [background], que deve ser opaco.
double gjaContrastRatioOver(Color foreground, Color background) {
  _requireOpaque(background, 'background');
  return gjaContrastRatio(
    Color.alphaBlend(foreground, background),
    background,
  );
}

void _requireOpaque(Color color, String name) {
  if (color.a < 1) {
    throw ArgumentError.value(
      color,
      name,
      'cor translúcida: informe a cor de fundo com gjaContrastRatioOver',
    );
  }
}
