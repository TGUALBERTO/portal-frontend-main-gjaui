import 'package:flutter/widgets.dart';

import '../card_header/gja_card_header.dart';
import '../container/gja_container.dart';
import '../separator/gja_separator.dart';
import '../title/gja_title.dart';

/// Posição do cabeçalho de um [GjaCard], como o
/// `sap.f.cards.HeaderPosition` do SAPUI5.
enum GjaCardHeaderPosition {
  /// Cabeçalho acima do conteúdo.
  top,

  /// Cabeçalho abaixo do conteúdo.
  bottom,
}

/// Cartão, como o `sap.f.Card` do SAPUI5.
///
/// Uma superfície `base` com borda, raio `tile` e sombra `card`, na largura
/// disponível. O [header], em geral um `GjaCardHeader`, fica acima do
/// [content] ou, com [headerPosition] `bottom`, abaixo dele, separado por uma
/// linha. O conteúdo não tem margem própria. O título do cabeçalho é
/// anunciado com o [headingLevel].
///
/// ```dart
/// GjaCard(
///   header: GjaCardHeader(
///     iconInitials: 'MB',
///     title: 'Pedidos pendentes',
///     subtitle: 'Compras',
///     statusText: '3 de 5',
///     onPress: abrirPedidos,
///   ),
///   content: const GjaSpacing.padding(
///     all: GjaSpace.l,
///     child: ListaDePedidos(),
///   ),
/// )
/// ```
class GjaCard extends StatelessWidget {
  /// Cria o cartão.
  const GjaCard({
    this.header,
    this.headerPosition = GjaCardHeaderPosition.top,
    this.content,
    this.headingLevel = GjaTitleLevel.h3,
    super.key,
  });

  /// Cabeçalho do cartão, em geral um `GjaCardHeader`.
  final Widget? header;

  /// Posição do cabeçalho.
  final GjaCardHeaderPosition headerPosition;

  /// Conteúdo do cartão, sem margem própria.
  final Widget? content;

  /// Nível do título do cabeçalho para leitores de tela.
  final GjaTitleLevel headingLevel;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final content = this.content;
    final scoped = header == null
        ? null
        : GjaCardHeadingScope(level: headingLevel, child: header);
    final line = scoped != null && content != null
        ? const GjaSeparator()
        : null;
    // A linha fica sempre entre o cabeçalho e o conteúdo.
    final children = [?scoped, ?line, ?content];
    return GjaContainer(
      surface: GjaSurface.base,
      border: true,
      radius: GjaRadius.tile,
      shadow: GjaShadow.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: headerPosition == GjaCardHeaderPosition.top
            ? children
            : children.reversed.toList(),
      ),
    );
  }
}
