import '../shadow_layer.dart';

/// Sombras primitivas: geometria em camadas, sem cor.
///
/// Nível: primitivo.
///
/// Nomeadas e desenhadas como os parâmetros `sapContent_Shadow0`…`3` e
/// `sapContent_HeaderShadow` do Horizon. [shadow0] tem duas camadas difusas
/// curtas; [shadow1] a [shadow3] têm um contorno de 1 px e uma camada difusa
/// que cresce com a profundidade. Valores provisórios (ADR 0009). Widgets não
/// leem estes valores: eles usam as sombras e papéis de `GjaShadowTokens`.
abstract final class GjaShadowPrimitives {
  /// Sem sombra.
  static const none = <GjaShadowLayer>[];

  /// Contorno de 1 px das sombras de sobreposição.
  static const _outline = GjaShadowLayer(
    offsetY: 0,
    blurRadius: 0,
    spreadRadius: 1,
  );

  /// Sombra de cartões e blocos (`sapContent_Shadow0`).
  static const shadow0 = <GjaShadowLayer>[
    GjaShadowLayer(offsetY: 0, blurRadius: 2),
    GjaShadowLayer(offsetY: 2, blurRadius: 4),
  ];

  /// Sombra baixa (`sapContent_Shadow1`).
  static const shadow1 = <GjaShadowLayer>[
    _outline,
    GjaShadowLayer(offsetY: 2, blurRadius: 8, opacity: 0.5),
  ];

  /// Sombra de popovers e menus (`sapContent_Shadow2`).
  static const shadow2 = <GjaShadowLayer>[
    _outline,
    GjaShadowLayer(offsetY: 10, blurRadius: 30, opacity: 0.5),
  ];

  /// Sombra de diálogos (`sapContent_Shadow3`).
  static const shadow3 = <GjaShadowLayer>[
    _outline,
    GjaShadowLayer(offsetY: 20, blurRadius: 80, opacity: 0.5),
  ];

  /// Sombra curta para baixo, de cabeçalhos e barras fixas
  /// (`sapContent_HeaderShadow`).
  static const header = <GjaShadowLayer>[
    GjaShadowLayer(offsetY: 2, blurRadius: 4, opacity: 0.5),
  ];

  /// Sombras por nome: [none] e [shadow0] a [shadow3] em ordem crescente de
  /// profundidade, seguidas de [header].
  static const values = <String, List<GjaShadowLayer>>{
    'none': none,
    'shadow0': shadow0,
    'shadow1': shadow1,
    'shadow2': shadow2,
    'shadow3': shadow3,
    'header': header,
  };
}
