/// Helpers internos de interpolação dos conjuntos de tokens.
///
/// Não são exportados: os conjuntos de `gja_foundation` os importam por
/// caminho relativo (design D5).
library;

/// Interpola duas durações por microssegundos, com arredondamento.
Duration lerpDurationValue(Duration a, Duration b, double t) {
  final micros = a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t;
  return Duration(microseconds: micros.round());
}

/// Interpola um token discreto: [a] antes de `t = 0.5`, [b] a partir dele.
V lerpDiscrete<V>(V a, V b, double t) => t < 0.5 ? a : b;
