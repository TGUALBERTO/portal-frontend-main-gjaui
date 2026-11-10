import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Consultas de responsividade do GJA: classe de tamanho da tela e
/// densidade recomendada.
///
/// Equivale às faixas de `sap.ui.Device.media` do SAPUI5. Para a classe do
/// espaço disponível de um widget, use [GjaResponsiveBuilder].
abstract final class GjaResponsive {
  /// Classe de tamanho da largura da janela, com [breakpoints] ou, sem eles,
  /// com os limiares do tema ativo (`GjaThemeData.of`).
  ///
  /// Sob um [GjaScreenSizeScope] com os mesmos [breakpoints], quem chama
  /// só é reconstruído quando a classe muda. Sem o escopo, a classe é a
  /// mesma, mas quem chama depende do tamanho da `MediaQuery` e é
  /// reconstruído a cada mudança de largura ou altura.
  static GjaSizeClass screenSizeClassOf(
    BuildContext context, {
    GjaBreakpointTokens? breakpoints,
  }) {
    final effective = breakpoints ?? GjaThemeData.of(context).breakpoints;
    final scope = context
        .getInheritedWidgetOfExactType<_ScreenSizeClassScope>();
    if (scope != null && scope.breakpoints == effective) {
      return context
          .dependOnInheritedWidgetOfExactType<_ScreenSizeClassScope>()!
          .sizeClass;
    }
    return effective.classify(MediaQuery.sizeOf(context).width);
  }

  /// Densidade inicial recomendada para [platform] (por padrão,
  /// `defaultTargetPlatform`): compacta em desktop, de entrada por ponteiro,
  /// e `cozy` (confortável) em dispositivos de toque.
  ///
  /// É só um padrão: a aplicação escolhe a densidade do tema.
  static GjaDensity recommendedDensity([TargetPlatform? platform]) {
    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => GjaDensity.compact,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => GjaDensity.cozy,
    };
  }
}

/// Publica a classe de tamanho da tela para a subárvore.
///
/// Os widgets que a leem com [GjaResponsive.screenSizeClassOf] só são
/// reconstruídos quando a classe muda, e não a cada mudança de largura dentro
/// da classe nem de altura. `GjaApp` insere este escopo; aplicações com
/// `WidgetsApp` o colocam no `builder`.
class GjaScreenSizeScope extends StatelessWidget {
  /// Cria o escopo em volta de [child].
  const GjaScreenSizeScope({
    required this.child,
    this.breakpoints,
    super.key,
  });

  /// Limiares usados na classificação; nulos usam os do tema ativo.
  final GjaBreakpointTokens? breakpoints;

  /// Subárvore que recebe a classe.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final effective = breakpoints ?? GjaThemeData.of(context).breakpoints;
    return _ScreenSizeClassScope(
      breakpoints: effective,
      sizeClass: effective.classify(MediaQuery.sizeOf(context).width),
      child: child,
    );
  }
}

class _ScreenSizeClassScope extends InheritedWidget {
  const _ScreenSizeClassScope({
    required this.breakpoints,
    required this.sizeClass,
    required super.child,
  });

  final GjaBreakpointTokens breakpoints;
  final GjaSizeClass sizeClass;

  @override
  bool updateShouldNotify(_ScreenSizeClassScope old) =>
      old.sizeClass != sizeClass || old.breakpoints != breakpoints;
}

/// Constrói o conteúdo com a classe de tamanho da largura disponível para
/// ele, e não a da janela.
///
/// Equivale aos controles do SAPUI5 que reagem à largura do próprio
/// contêiner. Largura sem limite resulta em `extraLarge`.
class GjaResponsiveBuilder extends StatelessWidget {
  /// Cria o construtor.
  const GjaResponsiveBuilder({
    required this.builder,
    this.breakpoints,
    super.key,
  });

  /// Constrói o conteúdo para a classe do espaço disponível.
  final Widget Function(BuildContext context, GjaSizeClass sizeClass) builder;

  /// Limiares usados na classificação; nulos usam os do tema ativo.
  final GjaBreakpointTokens? breakpoints;

  @override
  Widget build(BuildContext context) {
    final effective = breakpoints ?? GjaThemeData.of(context).breakpoints;
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, effective.classify(constraints.maxWidth)),
    );
  }
}

/// Valor por classe de tamanho, com herança da classe menor.
///
/// Equivale aos spans `XL/L/M/S` do SAPUI5: [small] é obrigatório, e uma
/// classe sem valor próprio usa o da maior classe menor que tenha valor.
@immutable
class GjaResponsiveValue<T extends Object> {
  /// Cria o valor responsivo.
  const GjaResponsiveValue({
    required this.small,
    this.medium,
    this.large,
    this.extraLarge,
  });

  /// Valor de `small`, base das demais classes.
  final T small;

  /// Valor próprio de `medium`, ou nulo para herdar.
  final T? medium;

  /// Valor próprio de `large`, ou nulo para herdar.
  final T? large;

  /// Valor próprio de `extraLarge`, ou nulo para herdar.
  final T? extraLarge;

  /// Valor de [sizeClass].
  T resolve(GjaSizeClass sizeClass) {
    final own = <T?>[small, medium, large, extraLarge];
    for (var i = sizeClass.index; i > 0; i--) {
      final value = own[i];
      if (value != null) return value;
    }
    return small;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaResponsiveValue<T> &&
        other.small == small &&
        other.medium == medium &&
        other.large == large &&
        other.extraLarge == extraLarge;
  }

  @override
  int get hashCode => Object.hash(small, medium, large, extraLarge);

  @override
  String toString() =>
      'GjaResponsiveValue<$T>(small: $small, medium: $medium, '
      'large: $large, extraLarge: $extraLarge)';
}
