import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaCard": cartões numa grade, com `GjaCardHeader`: um
/// acionável, um com ícone, status e data, um com o cabeçalho embaixo, um com
/// barra de ferramentas e um com uma lista sem margem.
class GjaCardPage extends StatefulWidget {
  /// Cria a página.
  const GjaCardPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaCard';

  /// Rota nomeada.
  static const route = '/gja-card';

  /// Título do cartão com cabeçalho acionável.
  static const pendingTitle = 'Pedidos pendentes';

  /// Mensagem mostrada ao acionar o cabeçalho.
  static const opened = 'Abrindo pedidos pendentes';

  /// Chave do cabeçalho com ícone, status e data.
  static const fullHeaderKey = Key('card-header-full');

  /// Chave do cartão com o cabeçalho embaixo.
  static const bottomCardKey = Key('card-bottom');

  /// Chave do cabeçalho com barra de ferramentas.
  static const toolbarHeaderKey = Key('card-header-toolbar');

  @override
  State<GjaCardPage> createState() => _GjaCardPageState();
}

class _GjaCardPageState extends State<GjaCardPage> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    Widget padded(Widget child) =>
        GjaSpacing.padding(all: GjaSpace.l, child: child);
    return GjaPage(
      title: GjaCardPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Cartões no modelo do sap.f.Card'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            if (_opened) const GjaText(GjaCardPage.opened),
            GjaGrid(
              content: [
                GjaCard(
                  header: GjaCardHeader(
                    title: GjaCardPage.pendingTitle,
                    subtitle: 'Compras',
                    statusText: '3 de 5',
                    onPress: () => setState(() => _opened = true),
                  ),
                  content: padded(
                    const GjaVBox(
                      gap: GjaSpace.s,
                      items: [
                        GjaObjectStatus(
                          icon: GjaIcons.warning,
                          text: '2 atrasados',
                          state: GjaValueState.warning,
                        ),
                        GjaText('Toque no cabeçalho para ver os pedidos.'),
                      ],
                    ),
                  ),
                ),
                GjaCard(
                  header: const GjaCardHeader(
                    key: GjaCardPage.fullHeaderKey,
                    iconInitials: 'MB',
                    iconAlt: 'Maria Barros',
                    title: 'Maria Barros',
                    subtitle: 'Fornecedor',
                    statusText: 'Ativo',
                    dataTimestamp: 'Há 5 min',
                  ),
                  content: padded(
                    const GjaText('Entrega média em 4 dias úteis.'),
                  ),
                ),
                GjaCard(
                  key: GjaCardPage.bottomCardKey,
                  headerPosition: GjaCardHeaderPosition.bottom,
                  header: const GjaCardHeader(
                    icon: GjaIcons.calendar,
                    title: 'Entregas de hoje',
                    subtitle: 'Depósito central',
                  ),
                  content: padded(
                    const GjaText('2 entregas previstas até as 18h.'),
                  ),
                ),
                GjaCard(
                  header: GjaCardHeader(
                    key: GjaCardPage.toolbarHeaderKey,
                    title: 'Últimas notas',
                    toolbar: GjaButton(
                      icon: GjaIcons.overflow,
                      tooltip: 'Mais',
                      onPress: () {},
                      type: GjaButtonType.transparent,
                    ),
                  ),
                  content: GjaVBox(
                    gap: GjaSpace.none,
                    items: [
                      for (final (i, nota) in const [
                        'NF 1021 — R\$ 1.250,00',
                        'NF 1022 — R\$ 980,00',
                        'NF 1023 — R\$ 3.400,00',
                      ].indexed) ...[
                        if (i > 0) const GjaSeparator(),
                        GjaSpacing.padding(
                          all: GjaSpace.m,
                          child: GjaText(nota),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
