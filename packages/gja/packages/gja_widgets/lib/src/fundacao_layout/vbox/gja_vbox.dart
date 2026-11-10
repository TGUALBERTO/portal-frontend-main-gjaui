import 'package:flutter/widgets.dart';

import '../flex/gja_flex_enums.dart';
import '../flex/gja_flex_layout.dart';
import '../spacing/gja_spacing.dart';

/// Empilha itens na vertical, como o `sap.m.VBox` do SAPUI5.
///
/// O espaço [gap] do tema entra só entre os itens, nunca nas pontas. O
/// alinhamento cruzado segue a direção do texto. `Expanded` e `Flexible`
/// ocupam o espaço livre.
///
/// Diferente do UI5, [gap] tem o padrão `stackGap`, e não nenhum, porque no
/// GJA o espaço vem do tema; e [alignItems] tem o padrão `start`, e não
/// `stretch`, porque esticar num eixo sem limite falha no Flutter.
///
/// ```dart
/// const GjaVBox(
///   items: [
///     GjaTitle('Pedido 4711', titleStyle: GjaTitleLevel.h3),
///     GjaLabel('Aguardando aprovação'),
///   ],
/// )
/// ```
class GjaVBox extends StatelessWidget {
  /// Cria a caixa vertical.
  const GjaVBox({
    required this.items,
    this.gap = GjaSpace.stackGap,
    this.justifyContent = GjaFlexJustifyContent.start,
    this.alignItems = GjaFlexAlignItems.start,
    this.displayInline = false,
    super.key,
  });

  /// Itens, de cima para baixo.
  final List<Widget> items;

  /// Espaço entre itens consecutivos.
  final GjaSpace gap;

  /// Alinhamento vertical.
  final GjaFlexJustifyContent justifyContent;

  /// Alinhamento horizontal; `baseline` vale como `start`.
  final GjaFlexAlignItems alignItems;

  /// Se ocupa só a altura necessária, em vez de toda a disponível.
  final bool displayInline;

  @override
  Widget build(BuildContext context) => buildGjaFlex(
    context,
    axis: Axis.vertical,
    items: items,
    gap: gap,
    justifyContent: justifyContent,
    alignItems: alignItems,
    displayInline: displayInline,
  );
}
