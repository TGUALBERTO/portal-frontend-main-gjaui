import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Nível de um [GjaTitle], como o `sap.ui.core.TitleLevel` do SAPUI5.
///
/// Serve tanto ao nível semântico ([GjaTitle.level]) quanto ao estilo
/// visual ([GjaTitle.titleStyle]).
enum GjaTitleLevel {
  /// Sem nível explícito: o nível do estilo (ou 2), ou o estilo H5.
  auto,

  /// Nível 1 (`header1`).
  h1,

  /// Nível 2 (`header2`).
  h2,

  /// Nível 3 (`header3`).
  h3,

  /// Nível 4 (`header4`).
  h4,

  /// Nível 5 (`header5`).
  h5,

  /// Nível 6 (`header6`).
  h6,
}

/// Exibe o título de uma página, seção, cartão ou diálogo, como o
/// `sap.m.Title` do SAPUI5.
///
/// O título é sempre anunciado como cabeçalho, com o nível de [level]; com
/// `auto`, o de [titleStyle], ou 2 se ele também for `auto`. [titleStyle]
/// define o estilo, e `auto` é o H5.
/// A cor é `text` do tema ativo. Sem [wrapping], o título ocupa uma linha e
/// termina com reticências; o leitor de tela lê o texto completo.
///
/// ```dart
/// GjaTitle('Pedidos em aberto', level: GjaTitleLevel.h2,
///     titleStyle: GjaTitleLevel.h3)
/// ```
class GjaTitle extends StatelessWidget {
  /// Cria o título [text].
  const GjaTitle(
    this.text, {
    this.level = GjaTitleLevel.auto,
    this.titleStyle = GjaTitleLevel.auto,
    this.wrapping = false,
    this.textAlign = TextAlign.start,
    super.key,
  });

  /// Texto exibido.
  final String text;

  /// Nível semântico do cabeçalho; `auto` segue [titleStyle].
  final GjaTitleLevel level;

  /// Estilo visual; `auto` usa o H5.
  final GjaTitleLevel titleStyle;

  /// Se o título quebra linhas; sem quebra, ocupa uma linha com reticências.
  final bool wrapping;

  /// Alinhamento horizontal.
  final TextAlign textAlign;

  static TextStyle _style(GjaTypographyTokens t, GjaTitleLevel style) =>
      switch (style) {
        GjaTitleLevel.h1 => t.header1,
        GjaTitleLevel.h2 => t.header2,
        GjaTitleLevel.h3 => t.header3,
        GjaTitleLevel.h4 => t.header4,
        GjaTitleLevel.h5 || GjaTitleLevel.auto => t.header5,
        GjaTitleLevel.h6 => t.header6,
      };

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    return Semantics(
      header: true,
      // Como o `_getAriaLevel` do `sap.m.Title`.
      headingLevel: switch ((level, titleStyle)) {
        (GjaTitleLevel.auto, GjaTitleLevel.auto) => 2,
        (GjaTitleLevel.auto, _) => titleStyle.index,
        _ => level.index,
      },
      child: Text(
        text,
        style: _style(
          theme.typography,
          titleStyle,
        ).copyWith(color: theme.colors.text),
        maxLines: wrapping ? null : 1,
        overflow: wrapping ? TextOverflow.clip : TextOverflow.ellipsis,
        textAlign: textAlign,
      ),
    );
  }
}
