import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaBusyIndicator": um indicador sozinho, um com texto e um cartão
/// que fica ocupado ao tocar "Atualizar".
class GjaBusyIndicatorPage extends StatefulWidget {
  /// Cria a página.
  const GjaBusyIndicatorPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaBusyIndicator';

  /// Rota nomeada.
  static const route = '/gja-busy-indicator';

  /// Chave do indicador sobre o cartão.
  static const cardKey = Key('busy-card');

  @override
  State<GjaBusyIndicatorPage> createState() => _GjaBusyIndicatorPageState();
}

class _GjaBusyIndicatorPageState extends State<GjaBusyIndicatorPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaBusyIndicatorPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText(
          'Operações em andamento no modelo do sap.m.BusyIndicator',
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaBusyIndicator(),
            const GjaBusyIndicator(text: 'Carregando pedidos'),
            GjaHBox(
              items: [
                GjaButton(
                  text: _busy ? 'Concluir' : 'Atualizar',
                  onPress: () => setState(() => _busy = !_busy),
                ),
              ],
            ),
            SizedBox(
              width: 320,
              child: GjaBusyIndicator(
                key: GjaBusyIndicatorPage.cardKey,
                busy: _busy,
                child: const GjaCard(
                  header: GjaCardHeader(title: 'Pedidos pendentes'),
                  content: GjaSpacing.padding(
                    all: GjaSpace.l,
                    child: GjaText('3 pedidos aguardam aprovação.'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
