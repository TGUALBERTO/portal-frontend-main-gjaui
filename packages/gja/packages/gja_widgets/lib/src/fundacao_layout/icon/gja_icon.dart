import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Papel de tamanho de um [GjaIcon], conforme `GjaIconTokens`.
enum GjaIconSize {
  /// Ícone pequeno.
  small,

  /// Ícone médio.
  medium,

  /// Ícone grande (navegação).
  large,

  /// Ícone extragrande (destaques).
  xLarge,

  /// Junto ao texto corrido; acompanha a escala de texto do sistema.
  inline,

  /// Dentro de botões e campos (padrão).
  control,
}

/// Cor de papel de um [GjaIcon].
///
/// Os tons são fixos para que todo ícone mantenha o contraste verificado
/// pelos fundamentos; não há cor livre.
enum GjaIconTone {
  /// Cor `text` do tema (padrão).
  standard,

  /// Cor `label` do tema, para ícones secundários.
  muted,

  /// Cor `brand` do tema, para ícones de destaque.
  brand,

  /// Cor do estado de valor `success`.
  success,

  /// Cor do estado de valor `warning`.
  warning,

  /// Cor do estado de valor `error`.
  error,

  /// Cor do estado de valor `information`.
  information,
}

/// Exibe um ícone da fonte do GJA, como o `sap.ui.core.Icon` do SAPUI5.
///
/// O tamanho vem de `icons.<size>` e a cor, do [tone], ambos do tema ativo.
/// Sem [semanticLabel], o ícone é decorativo e fica fora da árvore de
/// semântica; com ele, é anunciado como imagem. Os ícones direcionais do
/// catálogo (`GjaIcons`) são espelhados em RTL.
///
/// ```dart
/// const GjaIcon(GjaIcons.search)
/// const GjaIcon(
///   GjaIcons.warning,
///   tone: GjaIconTone.warning,
///   semanticLabel: 'Aviso',
/// )
/// ```
///
/// Para um ícone clicável, use o `GjaButton` só com ícone.
class GjaIcon extends StatelessWidget {
  /// Cria o ícone [icon].
  const GjaIcon(
    this.icon, {
    this.size = GjaIconSize.control,
    this.tone = GjaIconTone.standard,
    this.semanticLabel,
    super.key,
  });

  /// Ícone exibido, do catálogo `GjaIcons` ou da aplicação.
  final IconData icon;

  /// Papel de tamanho.
  final GjaIconSize size;

  /// Cor de papel.
  final GjaIconTone tone;

  /// Rótulo para leitores de tela; nulo torna o ícone decorativo.
  final String? semanticLabel;

  static double _size(GjaIconTokens t, GjaIconSize size) => switch (size) {
    GjaIconSize.small => t.small,
    GjaIconSize.medium => t.medium,
    GjaIconSize.large => t.large,
    GjaIconSize.xLarge => t.xLarge,
    GjaIconSize.inline => t.inline,
    GjaIconSize.control => t.control,
  };

  static Color _color(GjaColorTokens c, GjaIconTone tone) => switch (tone) {
    GjaIconTone.standard => c.text,
    GjaIconTone.muted => c.label,
    GjaIconTone.brand => c.brand,
    GjaIconTone.success => c.stateColors(GjaValueState.success).foreground,
    GjaIconTone.warning => c.stateColors(GjaValueState.warning).foreground,
    GjaIconTone.error => c.stateColors(GjaValueState.error).foreground,
    GjaIconTone.information =>
      c.stateColors(GjaValueState.information).foreground,
  };

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final glyph = Icon(
      icon,
      size: _size(theme.icons, size),
      color: _color(theme.colors, tone),
      applyTextScaling: size == GjaIconSize.inline,
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: glyph);
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: glyph,
    );
  }
}
