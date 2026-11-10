import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'lerp.dart';
import 'primitives/motion_primitives.dart';
import 'token_set.dart';

/// Papéis semânticos de movimento: durações e curvas de animação.
///
/// Nível: semântico.
///
/// Widgets animam somente com estes papéis, nunca com literais de `Duration`
/// ou de `Curve`. As durações devem ser não decrescentes
/// (`instant ≤ short ≤ medium ≤ long`), e [instant] deve valer zero. O
/// construtor `const` não consegue verificar isso (comparar `Duration` não é
/// uma expressão constante); [copyWith] verifica com `assert` em modo debug.
@immutable
class GjaMotionTokens extends GjaTokenSet<GjaMotionTokens> {
  /// Cria um mapeamento de movimento.
  const GjaMotionTokens({
    required this.instant,
    required this.short,
    required this.medium,
    required this.long,
    required this.standard,
    required this.enter,
    required this.exit,
  });

  /// Mapeamento usado quando o tema não define outro.
  const GjaMotionTokens.fallback()
    : this(
        instant: GjaMotionPrimitives.duration0,
        short: GjaMotionPrimitives.duration100,
        medium: GjaMotionPrimitives.duration200,
        long: GjaMotionPrimitives.duration300,
        standard: GjaMotionPrimitives.curveEaseInOut,
        enter: GjaMotionPrimitives.curveEaseOut,
        exit: GjaMotionPrimitives.curveEaseIn,
      );

  /// Mudança sem animação perceptível.
  final Duration instant;

  /// Retorno imediato a interações pequenas (hover, pressionado).
  final Duration short;

  /// Transições de componentes (expandir, mostrar sobreposição).
  final Duration medium;

  /// Transições de área grande (página, painel lateral).
  final Duration long;

  /// Curva para movimentos dentro da tela (`ease-in-out` na referência).
  final Curve standard;

  /// Curva para elementos que entram na tela (`ease-out` na referência).
  final Curve enter;

  /// Curva para elementos que saem da tela (`ease-in` na referência).
  final Curve exit;

  @override
  GjaMotionTokens copyWith({
    Duration? instant,
    Duration? short,
    Duration? medium,
    Duration? long,
    Curve? standard,
    Curve? enter,
    Curve? exit,
  }) {
    final result = GjaMotionTokens(
      instant: instant ?? this.instant,
      short: short ?? this.short,
      medium: medium ?? this.medium,
      long: long ?? this.long,
      standard: standard ?? this.standard,
      enter: enter ?? this.enter,
      exit: exit ?? this.exit,
    );
    assert(
      result._hasValidOrder,
      'durações devem satisfazer instant == 0 e instant ≤ short ≤ medium ≤ long: $result',
    );
    return result;
  }

  bool get _hasValidOrder =>
      instant == Duration.zero &&
      instant <= short &&
      short <= medium &&
      medium <= long;

  @override
  GjaMotionTokens lerp(GjaMotionTokens? other, double t) {
    if (other == null) return this;
    return GjaMotionTokens(
      instant: lerpDurationValue(instant, other.instant, t),
      short: lerpDurationValue(short, other.short, t),
      medium: lerpDurationValue(medium, other.medium, t),
      long: lerpDurationValue(long, other.long, t),
      standard: lerpDiscrete(standard, other.standard, t),
      enter: lerpDiscrete(enter, other.enter, t),
      exit: lerpDiscrete(exit, other.exit, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaMotionTokens &&
        other.instant == instant &&
        other.short == short &&
        other.medium == medium &&
        other.long == long &&
        other.standard == standard &&
        other.enter == enter &&
        other.exit == exit;
  }

  @override
  int get hashCode =>
      Object.hash(instant, short, medium, long, standard, enter, exit);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Duration>('instant', instant))
      ..add(DiagnosticsProperty<Duration>('short', short))
      ..add(DiagnosticsProperty<Duration>('medium', medium))
      ..add(DiagnosticsProperty<Duration>('long', long))
      ..add(DiagnosticsProperty<Curve>('standard', standard))
      ..add(DiagnosticsProperty<Curve>('enter', enter))
      ..add(DiagnosticsProperty<Curve>('exit', exit));
  }
}
