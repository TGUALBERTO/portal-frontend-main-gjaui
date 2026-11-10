import 'package:flutter/foundation.dart';

import 'token_set.dart';

/// Conjunto de tokens próprio da aplicação, identificado pelo seu tipo.
///
/// Nível: semântico ou componente, conforme a aplicação define.
///
/// Segue o mesmo contrato de [GjaTokenSet] (imutável, `copyWith`, [lerp] e
/// igualdade por valor). É registrado em [GjaTokenExtensions] e buscado com
/// [GjaTokenExtensions.get].
///
/// Exemplo:
///
/// ```dart
/// @immutable
/// class BrandTokens extends GjaTokenExtension<BrandTokens> {
///   const BrandTokens({required this.logoHeight});
///
///   final double logoHeight;
///
///   @override
///   BrandTokens copyWith({double? logoHeight}) =>
///       BrandTokens(logoHeight: logoHeight ?? this.logoHeight);
///
///   @override
///   BrandTokens lerp(BrandTokens? other, double t) => other == null
///       ? this
///       : BrandTokens(logoHeight: lerpDouble(logoHeight, other.logoHeight, t)!);
///
///   @override
///   bool operator ==(Object other) =>
///       other is BrandTokens && other.logoHeight == logoHeight;
///
///   @override
///   int get hashCode => logoHeight.hashCode;
/// }
///
/// final extensions = GjaTokenExtensions([const BrandTokens(logoHeight: 32)]);
/// final brand = extensions.get<BrandTokens>(); // BrandTokens?
/// ```
@immutable
abstract class GjaTokenExtension<T extends GjaTokenExtension<T>>
    extends GjaTokenSet<T> {
  /// Construtor `const` para as subclasses.
  const GjaTokenExtension();

  /// Chave de registro: o tipo concreto da extensão.
  Object get type => T;
}

/// Coleção imutável de extensões de tokens da aplicação, indexada por tipo.
///
/// Nível: semântico ou componente (agrega as extensões registradas).
@immutable
class GjaTokenExtensions with Diagnosticable {
  /// Cria a coleção a partir de [extensions].
  ///
  /// Em modo debug, falha se duas extensões tiverem o mesmo tipo.
  GjaTokenExtensions([
    Iterable<GjaTokenExtension<dynamic>> extensions = const [],
  ]) : _byType = _index(extensions);

  /// Coleção sem extensões.
  const GjaTokenExtensions.empty() : _byType = const {};

  const GjaTokenExtensions._(this._byType);

  /// Extensões por tipo. Guardadas como `Object` porque o tipo auto-referente
  /// instanciado com `dynamic` não é aceito pelo compilador em mapas.
  final Map<Object, Object> _byType;

  static Map<Object, Object> _index(
    Iterable<GjaTokenExtension<dynamic>> extensions,
  ) {
    final byType = <Object, Object>{};
    for (final extension in extensions) {
      assert(
        !byType.containsKey(extension.type),
        'extensão de tokens registrada duas vezes: ${extension.type}',
      );
      byType[extension.type] = extension;
    }
    return Map.unmodifiable(byType);
  }

  /// Extensões registradas, em ordem de registro.
  Iterable<Object> get values => _byType.values;

  /// Retorna a extensão do tipo [T], ou `null` se ela não foi registrada.
  T? get<T extends GjaTokenExtension<T>>() => _byType[T] as T?;

  /// Interpola esta coleção até [other], extensão por extensão.
  ///
  /// Extensões do mesmo tipo usam o próprio `lerp`. Extensões presentes em
  /// só uma das coleções são mantidas como estão. Com [other] nulo, retorna
  /// esta coleção.
  GjaTokenExtensions lerp(GjaTokenExtensions? other, double t) {
    if (other == null) return this;
    final result = <Object, Object>{
      for (final MapEntry(key: type, value: extension) in _byType.entries)
        type: _lerpExtension(extension, other._byType[type], t),
    };
    for (final MapEntry(key: type, value: extension) in other._byType.entries) {
      result.putIfAbsent(type, () => extension);
    }
    return GjaTokenExtensions._(Map.unmodifiable(result));
  }

  static Object _lerpExtension(Object a, Object? b, double t) {
    if (b == null) return a;
    // `lerp` é covariante no tipo concreto; a chave garante o mesmo tipo.
    return (a as dynamic).lerp(b, t) as Object;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaTokenExtensions && mapEquals(other._byType, _byType);
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _byType.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final MapEntry(key: type, value: extension) in _byType.entries) {
      properties.add(DiagnosticsProperty<Object>('$type', extension));
    }
  }
}
