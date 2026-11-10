import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaPanel": painel fixo e acordeão de painéis expansíveis.
class GjaPanelPage extends StatefulWidget {
  /// Cria a página.
  const GjaPanelPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaPanel';

  /// Rota nomeada.
  static const route = '/gja-panel';

  @override
  State<GjaPanelPage> createState() => _GjaPanelPageState();
}

class _GjaPanelPageState extends State<GjaPanelPage> {
  /// Painel aberto do acordeão; só um por vez.
  String? _open = 'itens';

  GjaPanel _section(String key, String title, String text) => GjaPanel(
    headerText: title,
    expandable: true,
    expanded: _open == key,
    onExpand: (value) => setState(() => _open = value ? key : null),
    content: [GjaText(text)],
  );

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaPanelPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Painel no modelo do sap.m.Panel'),
        const GjaSpacing.vertical(GjaSpace.l),
        const GjaPanel(
          headerText: 'Endereço de entrega',
          content: [GjaText('Rua das Flores, 10 — Centro, Belo Horizonte')],
        ),
        const GjaSpacing.vertical(GjaSpace.xl),
        const GjaTitle('Acordeão: painéis expansíveis empilhados'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          alignItems: GjaFlexAlignItems.stretch,
          items: [
            _section('itens', 'Itens', '12 itens no pedido 4711.'),
            _section('pagamento', 'Pagamento', 'Boleto em 30 dias'),
            _section(
              'entrega',
              'Entrega',
              'Transportadora, em até 5 dias úteis.',
            ),
          ],
        ),
      ],
    );
  }
}
