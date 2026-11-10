import 'package:flutter/painting.dart' show Color, ColorProperty;

import 'package:flutter/foundation.dart';

import '../tokens/token_set.dart';
import 'primitives/color_primitives.dart';
import 'value_state.dart';

/// Cores de um estado semântico de valor.
///
/// Nível: semântico.
@immutable
class GjaValueStateColors extends GjaTokenSet<GjaValueStateColors> {
  /// Cria as cores de um estado.
  const GjaValueStateColors({
    required this.foreground,
    required this.background,
    required this.hoverBackground,
    required this.border,
  });

  /// Texto e ícones do estado (≥ 4,5:1 sobre as superfícies e sobre [background]).
  final Color foreground;

  /// Fundo suave do estado (mensagens, faixas).
  final Color background;

  /// Fundo suave do estado em hover (como `sapButton_Accept_Hover_Background`).
  ///
  /// Texto em [foreground] sobre ele mantém ≥ 4,5:1.
  final Color hoverBackground;

  /// Borda do estado (≥ 3:1 sobre as superfícies).
  final Color border;

  @override
  GjaValueStateColors copyWith({
    Color? foreground,
    Color? background,
    Color? hoverBackground,
    Color? border,
  }) {
    return GjaValueStateColors(
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      hoverBackground: hoverBackground ?? this.hoverBackground,
      border: border ?? this.border,
    );
  }

  @override
  GjaValueStateColors lerp(GjaValueStateColors? other, double t) {
    if (other == null) return this;
    return GjaValueStateColors(
      foreground: Color.lerp(foreground, other.foreground, t)!,
      background: Color.lerp(background, other.background, t)!,
      hoverBackground: Color.lerp(hoverBackground, other.hoverBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaValueStateColors &&
        other.foreground == foreground &&
        other.background == background &&
        other.hoverBackground == hoverBackground &&
        other.border == border;
  }

  @override
  int get hashCode =>
      Object.hash(foreground, background, hoverBackground, border);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('foreground', foreground))
      ..add(ColorProperty('background', background))
      ..add(ColorProperty('hoverBackground', hoverBackground))
      ..add(ColorProperty('border', border));
  }
}

/// Papéis semânticos de cor e cores dos estados de valor.
///
/// Nível: semântico.
///
/// Papéis no modelo de parâmetros de tema do Fiori, sem o prefixo `sap`.
/// Widgets leem cores somente daqui, ou das famílias de controle derivadas
/// destes papéis, nunca de `GjaColorPrimitives`. [GjaColorTokens.light] e
/// [GjaColorTokens.dark] são os mapeamentos de referência; ambos atendem ao
/// contraste mínimo verificado por `gjaCheckContrast`.
@immutable
class GjaColorTokens extends GjaTokenSet<GjaColorTokens> {
  /// Cria um mapeamento de cores.
  const GjaColorTokens({
    required this.background,
    required this.base,
    required this.headerBackground,
    required this.shell,
    required this.text,
    required this.label,
    required this.link,
    required this.separator,
    required this.fieldBorder,
    required this.brand,
    required this.brandHover,
    required this.highlight,
    required this.contrastText,
    required this.hoverBackground,
    required this.selectionBackground,
    required this.selectionHoverBackground,
    required this.focus,
    required this.required,
    required this.shadow,
    required this.blockLayer,
    required this.none,
    required this.success,
    required this.warning,
    required this.error,
    required this.information,
  });

  /// Mapeamento claro de referência.
  const GjaColorTokens.light()
    : this(
        background: GjaColorPrimitives.neutral50,
        base: GjaColorPrimitives.white,
        headerBackground: GjaColorPrimitives.neutral100,
        shell: GjaColorPrimitives.white,
        text: GjaColorPrimitives.neutral900,
        label: GjaColorPrimitives.neutral600,
        link: GjaColorPrimitives.blue600,
        separator: GjaColorPrimitives.neutral200,
        fieldBorder: GjaColorPrimitives.neutral500,
        brand: GjaColorPrimitives.blue600,
        brandHover: GjaColorPrimitives.blue700,
        highlight: GjaColorPrimitives.blue800,
        contrastText: GjaColorPrimitives.white,
        hoverBackground: GjaColorPrimitives.neutral100,
        selectionBackground: GjaColorPrimitives.blue50,
        selectionHoverBackground: GjaColorPrimitives.blue100,
        focus: GjaColorPrimitives.blue600,
        required: GjaColorPrimitives.magenta600,
        shadow: GjaColorPrimitives.blackAlpha16,
        blockLayer: GjaColorPrimitives.blackAlpha40,
        none: const GjaValueStateColors(
          foreground: GjaColorPrimitives.neutral700,
          background: GjaColorPrimitives.neutral100,
          hoverBackground: GjaColorPrimitives.neutral200,
          border: GjaColorPrimitives.neutral500,
        ),
        success: const GjaValueStateColors(
          foreground: GjaColorPrimitives.green700,
          background: GjaColorPrimitives.green50,
          hoverBackground: GjaColorPrimitives.green100,
          border: GjaColorPrimitives.green600,
        ),
        warning: const GjaValueStateColors(
          foreground: GjaColorPrimitives.amber700,
          background: GjaColorPrimitives.amber50,
          hoverBackground: GjaColorPrimitives.amber100,
          border: GjaColorPrimitives.amber600,
        ),
        error: const GjaValueStateColors(
          foreground: GjaColorPrimitives.red600,
          background: GjaColorPrimitives.red50,
          hoverBackground: GjaColorPrimitives.red100,
          border: GjaColorPrimitives.red600,
        ),
        information: const GjaValueStateColors(
          foreground: GjaColorPrimitives.cyan700,
          background: GjaColorPrimitives.cyan50,
          hoverBackground: GjaColorPrimitives.cyan100,
          border: GjaColorPrimitives.cyan600,
        ),
      );

  /// Mapeamento escuro de referência.
  const GjaColorTokens.dark()
    : this(
        background: GjaColorPrimitives.neutral950,
        base: GjaColorPrimitives.neutral900,
        headerBackground: GjaColorPrimitives.neutral800,
        shell: GjaColorPrimitives.neutral900,
        text: GjaColorPrimitives.neutral50,
        label: GjaColorPrimitives.neutral300,
        link: GjaColorPrimitives.blue300,
        separator: GjaColorPrimitives.neutral700,
        fieldBorder: GjaColorPrimitives.neutral400,
        brand: GjaColorPrimitives.blue300,
        brandHover: GjaColorPrimitives.blue200,
        highlight: GjaColorPrimitives.blue100,
        contrastText: GjaColorPrimitives.blue900,
        hoverBackground: GjaColorPrimitives.neutral800,
        selectionBackground: GjaColorPrimitives.blue800,
        selectionHoverBackground: GjaColorPrimitives.blue900,
        focus: GjaColorPrimitives.blue300,
        required: GjaColorPrimitives.magenta300,
        shadow: GjaColorPrimitives.blackAlpha40,
        blockLayer: GjaColorPrimitives.blackAlpha60,
        none: const GjaValueStateColors(
          foreground: GjaColorPrimitives.neutral300,
          background: GjaColorPrimitives.neutral800,
          hoverBackground: GjaColorPrimitives.neutral700,
          border: GjaColorPrimitives.neutral400,
        ),
        success: const GjaValueStateColors(
          foreground: GjaColorPrimitives.green300,
          background: GjaColorPrimitives.green900,
          hoverBackground: GjaColorPrimitives.green800,
          border: GjaColorPrimitives.green400,
        ),
        warning: const GjaValueStateColors(
          foreground: GjaColorPrimitives.amber300,
          background: GjaColorPrimitives.amber900,
          hoverBackground: GjaColorPrimitives.amber800,
          border: GjaColorPrimitives.amber400,
        ),
        error: const GjaValueStateColors(
          foreground: GjaColorPrimitives.red300,
          background: GjaColorPrimitives.red900,
          hoverBackground: GjaColorPrimitives.red800,
          border: GjaColorPrimitives.red400,
        ),
        information: const GjaValueStateColors(
          foreground: GjaColorPrimitives.cyan300,
          background: GjaColorPrimitives.cyan900,
          hoverBackground: GjaColorPrimitives.cyan800,
          border: GjaColorPrimitives.cyan400,
        ),
      );

  /// Fundo da aplicação, atrás dos contêineres (sapBackgroundColor).
  final Color background;

  /// Fundo base de contêineres, campos e controles (sapBaseColor).
  final Color base;

  /// Fundo de cabeçalhos de lista e tabela e de áreas agrupadas.
  final Color headerBackground;

  /// Fundo da barra superior da aplicação (sapShellColor).
  final Color shell;

  /// Texto e ícones principais (sapTextColor).
  final Color text;

  /// Rótulos e texto secundário (sapContent_LabelColor).
  final Color label;

  /// Texto de links (sapLinkColor).
  final Color link;

  /// Separadores e divisores decorativos (isento de contraste).
  final Color separator;

  /// Borda de campos e controles, que precisa ser percebida (≥ 3:1).
  final Color fieldBorder;

  /// Cor da marca: ênfase e texto de ações (sapBrandColor).
  final Color brand;

  /// Fundo de ações enfatizadas em hover.
  final Color brandHover;

  /// Fundo do estado ativo (pressionado) e destaques fortes (sapHighlightColor).
  final Color highlight;

  /// Texto sobre [brand], [brandHover] e [highlight].
  final Color contrastText;

  /// Fundo de controles e itens em hover.
  final Color hoverBackground;

  /// Fundo de itens e controles selecionados.
  final Color selectionBackground;

  /// Fundo de itens selecionados em hover.
  final Color selectionHoverBackground;

  /// Contorno de foco do teclado (sapContent_FocusColor).
  final Color focus;

  /// Asterisco de campo obrigatório em rótulos (sapField_RequiredColor).
  final Color required;

  /// Cor das sombras, translúcida (sapContent_ShadowColor).
  final Color shadow;

  /// Camada de bloqueio atrás de diálogos modais, translúcida (sapBlockLayer_Background).
  final Color blockLayer;

  /// Cores do estado sem destaque semântico.
  final GjaValueStateColors none;

  /// Cores do estado de sucesso.
  final GjaValueStateColors success;

  /// Cores do estado de alerta.
  final GjaValueStateColors warning;

  /// Cores do estado de erro.
  final GjaValueStateColors error;

  /// Cores do estado informativo.
  final GjaValueStateColors information;

  /// Cores do estado [state]; todo estado tem cores definidas.
  GjaValueStateColors stateColors(GjaValueState state) {
    return switch (state) {
      GjaValueState.none => none,
      GjaValueState.success => success,
      GjaValueState.warning => warning,
      GjaValueState.error => error,
      GjaValueState.information => information,
    };
  }

  /// Papéis de cor por nome, na ordem de declaração (sem os estados de valor).
  Map<String, Color> get roles => {
    'background': background,
    'base': base,
    'headerBackground': headerBackground,
    'shell': shell,
    'text': text,
    'label': label,
    'link': link,
    'separator': separator,
    'fieldBorder': fieldBorder,
    'brand': brand,
    'brandHover': brandHover,
    'highlight': highlight,
    'contrastText': contrastText,
    'hoverBackground': hoverBackground,
    'selectionBackground': selectionBackground,
    'selectionHoverBackground': selectionHoverBackground,
    'focus': focus,
    'required': required,
    'shadow': shadow,
    'blockLayer': blockLayer,
  };

  @override
  GjaColorTokens copyWith({
    Color? background,
    Color? base,
    Color? headerBackground,
    Color? shell,
    Color? text,
    Color? label,
    Color? link,
    Color? separator,
    Color? fieldBorder,
    Color? brand,
    Color? brandHover,
    Color? highlight,
    Color? contrastText,
    Color? hoverBackground,
    Color? selectionBackground,
    Color? selectionHoverBackground,
    Color? focus,
    Color? required,
    Color? shadow,
    Color? blockLayer,
    GjaValueStateColors? none,
    GjaValueStateColors? success,
    GjaValueStateColors? warning,
    GjaValueStateColors? error,
    GjaValueStateColors? information,
  }) {
    return GjaColorTokens(
      background: background ?? this.background,
      base: base ?? this.base,
      headerBackground: headerBackground ?? this.headerBackground,
      shell: shell ?? this.shell,
      text: text ?? this.text,
      label: label ?? this.label,
      link: link ?? this.link,
      separator: separator ?? this.separator,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      brand: brand ?? this.brand,
      brandHover: brandHover ?? this.brandHover,
      highlight: highlight ?? this.highlight,
      contrastText: contrastText ?? this.contrastText,
      hoverBackground: hoverBackground ?? this.hoverBackground,
      selectionBackground: selectionBackground ?? this.selectionBackground,
      selectionHoverBackground:
          selectionHoverBackground ?? this.selectionHoverBackground,
      focus: focus ?? this.focus,
      required: required ?? this.required,
      shadow: shadow ?? this.shadow,
      blockLayer: blockLayer ?? this.blockLayer,
      none: none ?? this.none,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      information: information ?? this.information,
    );
  }

  @override
  GjaColorTokens lerp(GjaColorTokens? other, double t) {
    if (other == null) return this;
    return GjaColorTokens(
      background: Color.lerp(background, other.background, t)!,
      base: Color.lerp(base, other.base, t)!,
      headerBackground: Color.lerp(
        headerBackground,
        other.headerBackground,
        t,
      )!,
      shell: Color.lerp(shell, other.shell, t)!,
      text: Color.lerp(text, other.text, t)!,
      label: Color.lerp(label, other.label, t)!,
      link: Color.lerp(link, other.link, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandHover: Color.lerp(brandHover, other.brandHover, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      contrastText: Color.lerp(contrastText, other.contrastText, t)!,
      hoverBackground: Color.lerp(hoverBackground, other.hoverBackground, t)!,
      selectionBackground: Color.lerp(
        selectionBackground,
        other.selectionBackground,
        t,
      )!,
      selectionHoverBackground: Color.lerp(
        selectionHoverBackground,
        other.selectionHoverBackground,
        t,
      )!,
      focus: Color.lerp(focus, other.focus, t)!,
      required: Color.lerp(required, other.required, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      blockLayer: Color.lerp(blockLayer, other.blockLayer, t)!,
      none: none.lerp(other.none, t),
      success: success.lerp(other.success, t),
      warning: warning.lerp(other.warning, t),
      error: error.lerp(other.error, t),
      information: information.lerp(other.information, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GjaColorTokens &&
        other.background == background &&
        other.base == base &&
        other.headerBackground == headerBackground &&
        other.shell == shell &&
        other.text == text &&
        other.label == label &&
        other.link == link &&
        other.separator == separator &&
        other.fieldBorder == fieldBorder &&
        other.brand == brand &&
        other.brandHover == brandHover &&
        other.highlight == highlight &&
        other.contrastText == contrastText &&
        other.hoverBackground == hoverBackground &&
        other.selectionBackground == selectionBackground &&
        other.selectionHoverBackground == selectionHoverBackground &&
        other.focus == focus &&
        other.required == required &&
        other.shadow == shadow &&
        other.blockLayer == blockLayer &&
        other.none == none &&
        other.success == success &&
        other.warning == warning &&
        other.error == error &&
        other.information == information;
  }

  @override
  int get hashCode => Object.hashAll([
    background,
    base,
    headerBackground,
    shell,
    text,
    label,
    link,
    separator,
    fieldBorder,
    brand,
    brandHover,
    highlight,
    contrastText,
    hoverBackground,
    selectionBackground,
    selectionHoverBackground,
    focus,
    required,
    shadow,
    blockLayer,
    none,
    success,
    warning,
    error,
    information,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('background', background))
      ..add(ColorProperty('base', base))
      ..add(ColorProperty('headerBackground', headerBackground))
      ..add(ColorProperty('shell', shell))
      ..add(ColorProperty('text', text))
      ..add(ColorProperty('label', label))
      ..add(ColorProperty('link', link))
      ..add(ColorProperty('separator', separator))
      ..add(ColorProperty('fieldBorder', fieldBorder))
      ..add(ColorProperty('brand', brand))
      ..add(ColorProperty('brandHover', brandHover))
      ..add(ColorProperty('highlight', highlight))
      ..add(ColorProperty('contrastText', contrastText))
      ..add(ColorProperty('hoverBackground', hoverBackground))
      ..add(ColorProperty('selectionBackground', selectionBackground))
      ..add(ColorProperty('selectionHoverBackground', selectionHoverBackground))
      ..add(ColorProperty('focus', focus))
      ..add(ColorProperty('required', required))
      ..add(ColorProperty('shadow', shadow))
      ..add(ColorProperty('blockLayer', blockLayer))
      ..add(DiagnosticsProperty<GjaValueStateColors>('none', none))
      ..add(DiagnosticsProperty<GjaValueStateColors>('success', success))
      ..add(DiagnosticsProperty<GjaValueStateColors>('warning', warning))
      ..add(DiagnosticsProperty<GjaValueStateColors>('error', error))
      ..add(
        DiagnosticsProperty<GjaValueStateColors>('information', information),
      );
  }
}
