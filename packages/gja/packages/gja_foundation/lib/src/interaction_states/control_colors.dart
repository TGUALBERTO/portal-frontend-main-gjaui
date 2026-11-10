import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color, ColorProperty;

import '../color/color_tokens.dart';
import '../color/primitives/color_primitives.dart';
import '../color/value_state.dart';
import '../tokens/token_set.dart';
import 'interaction_state.dart';

/// Família de controle, no modelo dos tipos de botão e itens de lista do Fiori.
///
/// Nível: semântico.
enum GjaControlFamily {
  /// Controle padrão (botão Default): fundo base, borda e texto da marca.
  standard,

  /// Ação enfatizada (botão Emphasized): fundo da marca, texto de contraste.
  emphasized,

  /// Controle sem fundo (botão Transparent): só o texto da marca.
  transparent,

  /// Ação positiva (botão Accept): só as cores do estado de valor `success`.
  accept,

  /// Ação negativa (botão Reject): só as cores do estado de valor `error`.
  reject,

  /// Ação que pede atenção (botão Attention): só as cores do estado de valor
  /// `warning`.
  attention,

  /// Item de lista ou linha de tabela.
  list,
}

/// Fundo, borda e texto de um controle em um estado.
///
/// Nível: semântico.
@immutable
class GjaStateColors extends GjaTokenSet<GjaStateColors> {
  /// Cria as cores de um estado.
  const GjaStateColors({
    required this.background,
    required this.border,
    required this.text,
  });

  /// Fundo do controle.
  final Color background;

  /// Borda do controle (transparente quando a família não tem borda).
  final Color border;

  /// Texto e ícones do controle.
  final Color text;

  @override
  GjaStateColors copyWith({Color? background, Color? border, Color? text}) {
    return GjaStateColors(
      background: background ?? this.background,
      border: border ?? this.border,
      text: text ?? this.text,
    );
  }

  @override
  GjaStateColors lerp(GjaStateColors? other, double t) {
    if (other == null) return this;
    return GjaStateColors(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaStateColors &&
        other.background == background &&
        other.border == border &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(background, border, text);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('background', background))
      ..add(ColorProperty('border', border))
      ..add(ColorProperty('text', text));
  }
}

/// Cores de uma família de controle em cada estado.
///
/// Nível: semântico.
///
/// Derivadas dos papéis de cor por [GjaControlColors.of], como os
/// parâmetros derivados do Fiori: trocar `brand` no tema alcança todas as
/// famílias. Use [resolve] para obter as cores de um conjunto de estados.
@immutable
class GjaControlColors extends GjaTokenSet<GjaControlColors> {
  /// Cria as cores de uma família.
  const GjaControlColors({
    required this.normal,
    required this.hover,
    required this.active,
    required this.selected,
    required this.selectedHover,
  });

  /// Cores de [family] derivadas de [colors].
  factory GjaControlColors.of(
    GjaControlFamily family,
    GjaColorTokens colors,
  ) {
    const none = GjaColorPrimitives.transparent;
    final c = colors;
    GjaStateColors s(Color background, Color border, Color text) =>
        GjaStateColors(background: background, border: border, text: text);
    final active = s(c.highlight, c.highlight, c.contrastText);
    return switch (family) {
      GjaControlFamily.standard => GjaControlColors(
        normal: s(c.base, c.fieldBorder, c.brand),
        hover: s(c.hoverBackground, c.fieldBorder, c.brand),
        active: active,
        selected: s(c.selectionBackground, c.brand, c.brand),
        selectedHover: s(c.selectionHoverBackground, c.brand, c.brand),
      ),
      GjaControlFamily.emphasized => GjaControlColors(
        normal: s(c.brand, c.brand, c.contrastText),
        hover: s(c.brandHover, c.brandHover, c.contrastText),
        active: active,
        selected: active,
        selectedHover: active,
      ),
      GjaControlFamily.transparent => GjaControlColors(
        normal: s(none, none, c.brand),
        hover: s(c.hoverBackground, none, c.brand),
        active: s(c.highlight, none, c.contrastText),
        selected: s(c.selectionBackground, none, c.brand),
        selectedHover: s(c.selectionHoverBackground, none, c.brand),
      ),
      GjaControlFamily.accept => _semantic(c, GjaValueState.success),
      GjaControlFamily.reject => _semantic(c, GjaValueState.error),
      GjaControlFamily.attention => _semantic(c, GjaValueState.warning),
      GjaControlFamily.list => GjaControlColors(
        normal: s(c.base, none, c.text),
        hover: s(c.hoverBackground, none, c.text),
        active: s(c.highlight, none, c.contrastText),
        selected: s(c.selectionBackground, none, c.text),
        selectedHover: s(c.selectionHoverBackground, none, c.text),
      ),
    };
  }

  /// Família de uma ação semântica, só com as cores do estado de valor
  /// [state], como os botões Accept, Reject e Attention do Horizon.
  ///
  /// Normal = (`background`, `border`, `foreground`); o hover usa o
  /// `hoverBackground` do estado; ativo, selecionado e selecionado com hover
  /// invertem o normal: (`foreground`, `foreground`, `background`).
  static GjaControlColors _semantic(
    GjaColorTokens c,
    GjaValueState state,
  ) {
    final s = c.stateColors(state);
    final active = GjaStateColors(
      background: s.foreground,
      border: s.foreground,
      text: s.background,
    );
    return GjaControlColors(
      normal: GjaStateColors(
        background: s.background,
        border: s.border,
        text: s.foreground,
      ),
      hover: GjaStateColors(
        background: s.hoverBackground,
        border: s.border,
        text: s.foreground,
      ),
      active: active,
      selected: active,
      selectedHover: active,
    );
  }

  /// Estado normal (e desabilitado, com a opacidade de desabilitado).
  final GjaStateColors normal;

  /// Ponteiro sobre o controle.
  final GjaStateColors hover;

  /// Controle pressionado.
  final GjaStateColors active;

  /// Controle selecionado.
  final GjaStateColors selected;

  /// Controle selecionado com o ponteiro sobre ele.
  final GjaStateColors selectedHover;

  /// Estados por nome, na ordem de declaração.
  Map<String, GjaStateColors> get states => {
    'normal': normal,
    'hover': hover,
    'active': active,
    'selected': selected,
    'selectedHover': selectedHover,
  };

  /// Cores para [states], na precedência do Fiori.
  ///
  /// `disabled` → normal (a opacidade vem de
  /// `GjaInteractionStateTokens.opacity`); `pressed` → ativo;
  /// `selected` com `hovered` → selecionado com hover; `selected` →
  /// selecionado; `hovered` → hover; demais → normal. `focused` não altera
  /// as cores.
  GjaStateColors resolve(Set<GjaInteractionState> states) {
    bool has(GjaInteractionState s) => states.contains(s);
    if (has(GjaInteractionState.disabled)) return normal;
    if (has(GjaInteractionState.pressed)) return active;
    if (has(GjaInteractionState.selected)) {
      return has(GjaInteractionState.hovered) ? selectedHover : selected;
    }
    if (has(GjaInteractionState.hovered)) return hover;
    return normal;
  }

  @override
  GjaControlColors copyWith({
    GjaStateColors? normal,
    GjaStateColors? hover,
    GjaStateColors? active,
    GjaStateColors? selected,
    GjaStateColors? selectedHover,
  }) {
    return GjaControlColors(
      normal: normal ?? this.normal,
      hover: hover ?? this.hover,
      active: active ?? this.active,
      selected: selected ?? this.selected,
      selectedHover: selectedHover ?? this.selectedHover,
    );
  }

  @override
  GjaControlColors lerp(GjaControlColors? other, double t) {
    if (other == null) return this;
    return GjaControlColors(
      normal: normal.lerp(other.normal, t),
      hover: hover.lerp(other.hover, t),
      active: active.lerp(other.active, t),
      selected: selected.lerp(other.selected, t),
      selectedHover: selectedHover.lerp(other.selectedHover, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaControlColors &&
        other.normal == normal &&
        other.hover == hover &&
        other.active == active &&
        other.selected == selected &&
        other.selectedHover == selectedHover;
  }

  @override
  int get hashCode =>
      Object.hash(normal, hover, active, selected, selectedHover);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final MapEntry(key: name, value: colors) in states.entries) {
      properties.add(DiagnosticsProperty<GjaStateColors>(name, colors));
    }
  }
}
