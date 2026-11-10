import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show BoxShadow, Color, Offset;

import '../tokens/token_set.dart';
import 'primitives/shadow_primitives.dart';
import 'shadow_layer.dart';

/// Sombras e papéis semânticos, no modelo dos parâmetros `sapContent_Shadow*`
/// do Fiori.
///
/// Nível: semântico.
///
/// Cada sombra ou papel é uma lista de camadas sem cor. Widgets obtêm sombras
/// com [boxShadows], passando a cor `shadow` do tema ativo
/// (ex.: `shadows.boxShadows(shadows.card, colors.shadow)`). A geometria é
/// a mesma nos modos claro e escuro; só a cor muda.
@immutable
class GjaShadowTokens extends GjaTokenSet<GjaShadowTokens> {
  /// Cria um mapeamento de sombras.
  const GjaShadowTokens({
    required this.none,
    required this.shadow0,
    required this.shadow1,
    required this.shadow2,
    required this.shadow3,
    required this.card,
    required this.popover,
    required this.dialog,
    required this.dragged,
    required this.header,
  });

  /// Mapeamento de referência, como no Horizon: `card` = [shadow0],
  /// `popover` = [shadow2], `dialog` = [shadow3], `dragged` = [shadow3]
  /// (provisório, ADR 0009) e `header` = sombra de cabeçalho.
  const GjaShadowTokens.fallback()
    : this(
        none: GjaShadowPrimitives.none,
        shadow0: GjaShadowPrimitives.shadow0,
        shadow1: GjaShadowPrimitives.shadow1,
        shadow2: GjaShadowPrimitives.shadow2,
        shadow3: GjaShadowPrimitives.shadow3,
        card: GjaShadowPrimitives.shadow0,
        popover: GjaShadowPrimitives.shadow2,
        dialog: GjaShadowPrimitives.shadow3,
        dragged: GjaShadowPrimitives.shadow3,
        header: GjaShadowPrimitives.header,
      );

  /// Sem sombra; para interpolar ou desligar a sombra de um papel.
  final List<GjaShadowLayer> none;

  /// Sombra de cartões (`sapContent_Shadow0`).
  final List<GjaShadowLayer> shadow0;

  /// Sombra baixa (`sapContent_Shadow1`).
  final List<GjaShadowLayer> shadow1;

  /// Sombra de popovers (`sapContent_Shadow2`).
  final List<GjaShadowLayer> shadow2;

  /// Sombra de diálogos (`sapContent_Shadow3`).
  final List<GjaShadowLayer> shadow3;

  /// Cartões e blocos.
  final List<GjaShadowLayer> card;

  /// Popovers, menus, listas suspensas e dicas.
  final List<GjaShadowLayer> popover;

  /// Diálogos e painéis modais.
  final List<GjaShadowLayer> dialog;

  /// Item arrastado.
  final List<GjaShadowLayer> dragged;

  /// Cabeçalhos e barras fixas (`sapContent_HeaderShadow`).
  final List<GjaShadowLayer> header;

  /// Sombras e papéis por nome, na ordem de declaração.
  Map<String, List<GjaShadowLayer>> get values => {
    'none': none,
    'shadow0': shadow0,
    'shadow1': shadow1,
    'shadow2': shadow2,
    'shadow3': shadow3,
    'card': card,
    'popover': popover,
    'dialog': dialog,
    'dragged': dragged,
    'header': header,
  };

  /// Sombras de caixa de [shadow] com a cor [shadowColor].
  ///
  /// Cada camada vira um [BoxShadow] com sua geometria e a cor recebida, com
  /// a opacidade multiplicada pelo fator da camada.
  List<BoxShadow> boxShadows(List<GjaShadowLayer> shadow, Color shadowColor) {
    return [
      for (final layer in shadow)
        BoxShadow(
          color: shadowColor.withValues(alpha: shadowColor.a * layer.opacity),
          offset: Offset(0, layer.offsetY),
          blurRadius: layer.blurRadius,
          spreadRadius: layer.spreadRadius,
        ),
    ];
  }

  @override
  GjaShadowTokens copyWith({
    List<GjaShadowLayer>? none,
    List<GjaShadowLayer>? shadow0,
    List<GjaShadowLayer>? shadow1,
    List<GjaShadowLayer>? shadow2,
    List<GjaShadowLayer>? shadow3,
    List<GjaShadowLayer>? card,
    List<GjaShadowLayer>? popover,
    List<GjaShadowLayer>? dialog,
    List<GjaShadowLayer>? dragged,
    List<GjaShadowLayer>? header,
  }) {
    final result = GjaShadowTokens(
      none: none ?? this.none,
      shadow0: shadow0 ?? this.shadow0,
      shadow1: shadow1 ?? this.shadow1,
      shadow2: shadow2 ?? this.shadow2,
      shadow3: shadow3 ?? this.shadow3,
      card: card ?? this.card,
      popover: popover ?? this.popover,
      dialog: dialog ?? this.dialog,
      dragged: dragged ?? this.dragged,
      header: header ?? this.header,
    );
    assert(() {
      for (final MapEntry(key: name, value: level) in result.values.entries) {
        if (level.any((layer) => !layer.isValid)) {
          throw AssertionError(
            'sombra "$name" tem camada inválida (valores finitos, desfoque e '
            'expansão ≥ 0, opacidade entre 0 e 1): $level',
          );
        }
      }
      return true;
    }());
    return result;
  }

  @override
  GjaShadowTokens lerp(GjaShadowTokens? other, double t) {
    if (other == null) return this;
    List<GjaShadowLayer> mix(
      List<GjaShadowLayer> a,
      List<GjaShadowLayer> b,
    ) => GjaShadowLayer.lerpList(a, b, t);
    return GjaShadowTokens(
      none: mix(none, other.none),
      shadow0: mix(shadow0, other.shadow0),
      shadow1: mix(shadow1, other.shadow1),
      shadow2: mix(shadow2, other.shadow2),
      shadow3: mix(shadow3, other.shadow3),
      card: mix(card, other.card),
      popover: mix(popover, other.popover),
      dialog: mix(dialog, other.dialog),
      dragged: mix(dragged, other.dragged),
      header: mix(header, other.header),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaShadowTokens &&
        listEquals(other.none, none) &&
        listEquals(other.shadow0, shadow0) &&
        listEquals(other.shadow1, shadow1) &&
        listEquals(other.shadow2, shadow2) &&
        listEquals(other.shadow3, shadow3) &&
        listEquals(other.card, card) &&
        listEquals(other.popover, popover) &&
        listEquals(other.dialog, dialog) &&
        listEquals(other.dragged, dragged) &&
        listEquals(other.header, header);
  }

  @override
  int get hashCode => Object.hashAll([
    for (final level in values.values) Object.hashAll(level),
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final MapEntry(key: name, value: level) in values.entries) {
      properties.add(IterableProperty<GjaShadowLayer>(name, level));
    }
  }
}
