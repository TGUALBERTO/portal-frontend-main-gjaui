import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaPopover": um popover de filtros aberto por um botão, com
/// ações no rodapé, e um popover só com conteúdo aberto por um ícone.
class GjaPopoverPage extends StatefulWidget {
  /// Cria a página.
  const GjaPopoverPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaPopover';

  /// Rota nomeada.
  static const route = '/gja-popover';

  /// Rótulo do botão que abre o popover de filtros.
  static const filter = 'Filtrar';

  /// Rótulo da ação que aplica os filtros.
  static const apply = 'Aplicar';

  /// Mensagem mostrada depois de aplicar os filtros.
  static const applied = 'Filtros aplicados';

  @override
  State<GjaPopoverPage> createState() => _GjaPopoverPageState();
}

class _GjaPopoverPageState extends State<GjaPopoverPage> {
  final _filters = GjaPopoverController();
  final _details = GjaPopoverController();
  bool _applied = false;

  @override
  void dispose() {
    _filters.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaPopoverPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Painéis ancorados no modelo do sap.m.Popover'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaText(
              'O popover fecha com um toque fora ou com Esc, e o foco volta à '
              'âncora.',
            ),
            GjaHBox(
              gap: GjaSpace.m,
              items: [
                GjaPopover(
                  controller: _filters,
                  title: 'Filtros',
                  content: const GjaVBox(
                    gap: GjaSpace.s,
                    items: [
                      GjaText('Status: em aberto'),
                      GjaText('Período: últimos 30 dias'),
                      GjaText('Centro: 1000 — São Paulo'),
                    ],
                  ),
                  actions: [
                    GjaButton(
                      text: GjaPopoverPage.apply,
                      type: GjaButtonType.emphasized,
                      onPress: () {
                        _filters.close();
                        setState(() => _applied = true);
                      },
                    ),
                    GjaButton(
                      text: 'Cancelar',
                      type: GjaButtonType.transparent,
                      onPress: _filters.close,
                    ),
                  ],
                  child: GjaButton(
                    text: GjaPopoverPage.filter,
                    icon: GjaIcons.filter,
                    onPress: _filters.toggle,
                  ),
                ),
                GjaPopover(
                  controller: _details,
                  semanticLabel: 'Detalhes do pedido',
                  content: const GjaText(
                    'Pedido 4711, criado em 12/10 por Maria Barros.',
                  ),
                  child: GjaButton(
                    icon: GjaIcons.information,
                    tooltip: 'Detalhes do pedido',
                    onPress: _details.toggle,
                    type: GjaButtonType.transparent,
                  ),
                ),
              ],
            ),
            if (_applied) const GjaText(GjaPopoverPage.applied),
          ],
        ),
      ],
    );
  }
}
