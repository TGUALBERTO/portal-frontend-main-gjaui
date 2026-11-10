import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../spacing/gja_spacing.dart';
import 'gja_flex_enums.dart';

// Montagem comum de `GjaHBox` e `GjaVBox`. Não exportado: a API pública
// são os dois widgets e os enums do FlexBox.

MainAxisAlignment _main(GjaFlexJustifyContent value) => switch (value) {
  GjaFlexJustifyContent.start => MainAxisAlignment.start,
  GjaFlexJustifyContent.center => MainAxisAlignment.center,
  GjaFlexJustifyContent.end => MainAxisAlignment.end,
  GjaFlexJustifyContent.spaceBetween => MainAxisAlignment.spaceBetween,
  GjaFlexJustifyContent.spaceAround => MainAxisAlignment.spaceAround,
};

/// `Flex` com o espaço [gap] do tema só entre os itens.
Widget buildGjaFlex(
  BuildContext context, {
  required Axis axis,
  required List<Widget> items,
  required GjaSpace gap,
  required GjaFlexJustifyContent justifyContent,
  required GjaFlexAlignItems alignItems,
  required bool displayInline,
}) {
  final spacing = GjaThemeData.of(context).spacing;
  // Numa coluna, `baseline` cai em `start`, como `align-items: baseline` no
  // CSS de uma coluna.
  final baseline =
      axis == Axis.horizontal && alignItems == GjaFlexAlignItems.baseline;
  return Flex(
    direction: axis,
    spacing: GjaSpacing.resolve(spacing, gap),
    mainAxisAlignment: _main(justifyContent),
    crossAxisAlignment: switch (alignItems) {
      GjaFlexAlignItems.start => CrossAxisAlignment.start,
      GjaFlexAlignItems.center => CrossAxisAlignment.center,
      GjaFlexAlignItems.end => CrossAxisAlignment.end,
      GjaFlexAlignItems.baseline =>
        baseline ? CrossAxisAlignment.baseline : CrossAxisAlignment.start,
      GjaFlexAlignItems.stretch => CrossAxisAlignment.stretch,
    },
    textBaseline: baseline ? TextBaseline.alphabetic : null,
    mainAxisSize: displayInline ? MainAxisSize.min : MainAxisSize.max,
    children: items,
  );
}

/// `Wrap` com o espaço [gap] do tema entre os itens e entre as linhas.
Widget buildGjaWrap(
  BuildContext context, {
  required List<Widget> items,
  required GjaSpace gap,
  required GjaFlexJustifyContent justifyContent,
  required GjaFlexAlignItems alignItems,
}) {
  assert(
    items.every((c) => c is! Flexible),
    'GjaHBox com wrap não aceita itens Expanded ou Flexible',
  );
  assert(
    alignItems != GjaFlexAlignItems.stretch &&
        alignItems != GjaFlexAlignItems.baseline,
    'GjaHBox com wrap: alignItems stretch e baseline não se aplicam à '
    'quebra',
  );
  final value = GjaSpacing.resolve(GjaThemeData.of(context).spacing, gap);
  return Wrap(
    spacing: value,
    runSpacing: value,
    alignment: switch (justifyContent) {
      GjaFlexJustifyContent.start => WrapAlignment.start,
      GjaFlexJustifyContent.center => WrapAlignment.center,
      GjaFlexJustifyContent.end => WrapAlignment.end,
      GjaFlexJustifyContent.spaceBetween => WrapAlignment.spaceBetween,
      GjaFlexJustifyContent.spaceAround => WrapAlignment.spaceAround,
    },
    crossAxisAlignment: switch (alignItems) {
      GjaFlexAlignItems.center => WrapCrossAlignment.center,
      GjaFlexAlignItems.end => WrapCrossAlignment.end,
      _ => WrapCrossAlignment.start,
    },
    children: items,
  );
}
