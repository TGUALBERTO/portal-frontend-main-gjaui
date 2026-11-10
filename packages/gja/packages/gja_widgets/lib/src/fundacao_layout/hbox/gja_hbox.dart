import 'package:flutter/widgets.dart';

import '../flex/gja_flex_enums.dart';
import '../flex/gja_flex_layout.dart';
import '../spacing/gja_spacing.dart';

/// Organiza itens lado a lado, como o `sap.m.HBox` do SAPUI5.
///
/// O espaço [gap] do tema entra só entre os itens, nunca nas pontas. O início
/// segue a direção do texto. `Expanded` e `Flexible` ocupam o espaço livre.
/// Com [wrap] `wrap`, os itens que não cabem vão para a linha seguinte.
///
/// Diferente do UI5, [gap] tem o padrão `inlineGap`, e não nenhum, porque no
/// GJA o espaço vem do tema; e [alignItems] tem o padrão `center`, e não
/// `stretch`, porque esticar num eixo sem limite falha no Flutter.
///
/// ```dart
/// const GjaHBox(
///   items: [GjaIcon(GjaIcons.information), GjaText('Detalhes')],
/// )
/// ```
class GjaHBox extends StatelessWidget {
  /// Cria a caixa horizontal.
  const GjaHBox({
    required this.items,
    this.gap = GjaSpace.inlineGap,
    this.justifyContent = GjaFlexJustifyContent.start,
    this.alignItems = GjaFlexAlignItems.center,
    this.wrap = GjaFlexWrap.noWrap,
    this.displayInline = false,
    super.key,
  });

  /// Itens, na ordem visual.
  final List<Widget> items;

  /// Espaço entre itens consecutivos (e entre linhas, com [wrap]).
  final GjaSpace gap;

  /// Alinhamento horizontal (em cada linha, com [wrap]).
  final GjaFlexJustifyContent justifyContent;

  /// Alinhamento vertical. Com [wrap], só `start`, `center` e `end`.
  final GjaFlexAlignItems alignItems;

  /// Se os itens que não cabem vão para a linha seguinte. Com quebra, não
  /// aceita itens `Expanded` ou `Flexible`.
  final GjaFlexWrap wrap;

  /// Se ocupa só a largura necessária, em vez de toda a disponível; não se
  /// aplica com [wrap].
  final bool displayInline;

  @override
  Widget build(BuildContext context) {
    if (wrap == GjaFlexWrap.wrap) {
      return buildGjaWrap(
        context,
        items: items,
        gap: gap,
        justifyContent: justifyContent,
        alignItems: alignItems,
      );
    }
    return buildGjaFlex(
      context,
      axis: Axis.horizontal,
      items: items,
      gap: gap,
      justifyContent: justifyContent,
      alignItems: alignItems,
      displayInline: displayInline,
    );
  }
}
