import 'package:flutter/foundation.dart';

/// Contrato comum dos conjuntos de tokens semânticos e de componente.
///
/// Nível: semântico ou componente (cada subclasse declara o seu).
///
/// Todo conjunto é imutável, tem construtor `const`, `copyWith`, [lerp],
/// igualdade por valor (`==` e `hashCode`) e expõe cada token em
/// `debugFillProperties`. A classe base não implementa a igualdade: cada
/// subclasse a declara para todos os seus campos.
///
/// Os primitivos não são conjuntos: são constantes de escala da biblioteca
/// `package:gja_foundation/gja_primitives.dart`.
///
/// Exemplo de conjunto:
///
/// ```dart
/// @immutable
/// class FadeTokens extends GjaTokenSet<FadeTokens> {
///   const FadeTokens({required this.duration, required this.curve});
///
///   final Duration duration;
///   final Curve curve;
///
///   @override
///   FadeTokens copyWith({Duration? duration, Curve? curve}) => FadeTokens(
///         duration: duration ?? this.duration,
///         curve: curve ?? this.curve,
///       );
///
///   @override
///   FadeTokens lerp(FadeTokens? other, double t) {
///     if (other == null) return this;
///     return FadeTokens(
///       duration: lerpDurationValue(duration, other.duration, t),
///       curve: t < 0.5 ? curve : other.curve,
///     );
///   }
///
///   @override
///   bool operator ==(Object other) =>
///       other is FadeTokens &&
///       other.duration == duration &&
///       other.curve == curve;
///
///   @override
///   int get hashCode => Object.hash(duration, curve);
///
///   @override
///   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
///     super.debugFillProperties(properties);
///     properties
///       ..add(DiagnosticsProperty<Duration>('duration', duration))
///       ..add(DiagnosticsProperty<Curve>('curve', curve));
///   }
/// }
/// ```
@immutable
abstract class GjaTokenSet<T extends GjaTokenSet<T>> with Diagnosticable {
  /// Construtor `const` para as subclasses.
  const GjaTokenSet();

  /// Retorna um novo conjunto com os campos informados substituídos.
  ///
  /// As subclasses declaram um parâmetro nomeado opcional por token. Sem
  /// argumentos, o resultado é igual a este conjunto.
  T copyWith();

  /// Interpola este conjunto até [other].
  ///
  /// Em `t = 0` o resultado é igual a este conjunto e em `t = 1`, igual a
  /// [other]. Tokens contínuos são interpolados; tokens discretos trocam em
  /// `t = 0.5`. Com [other] nulo, retorna este conjunto.
  T lerp(T? other, double t);
}
