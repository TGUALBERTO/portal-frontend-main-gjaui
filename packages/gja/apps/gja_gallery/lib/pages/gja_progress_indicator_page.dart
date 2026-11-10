import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaProgressIndicator": barras por estado de valor e uma barra
/// que avança.
class GjaProgressIndicatorPage extends StatefulWidget {
  /// Cria a página.
  const GjaProgressIndicatorPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaProgressIndicator';

  /// Rota nomeada.
  static const route = '/gja-progress-indicator';

  /// Chave da barra que avança.
  static const advancingKey = ValueKey('advancing');

  @override
  State<GjaProgressIndicatorPage> createState() =>
      _GjaProgressIndicatorPageState();
}

class _GjaProgressIndicatorPageState
    extends State<GjaProgressIndicatorPage> {
  double _sent = 30;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaProgressIndicatorPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText(
          'Barra no modelo do sap.m.ProgressIndicator. Para operações sem '
          'andamento medível, use GjaBusyIndicator.',
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          alignItems: GjaFlexAlignItems.stretch,
          items: [
            const GjaTitle(
              'Barras por estado',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            for (final (i, state) in GjaValueState.values.indexed)
              GjaVBox(
                gap: GjaSpace.xs,
                alignItems: GjaFlexAlignItems.stretch,
                items: [
                  GjaText('${state.name} — ${(i + 1) * 15}%'),
                  GjaProgressIndicator(
                    percentValue: (i + 1) * 15,
                    state: state,
                  ),
                ],
              ),
            const GjaTitle(
              'Envio de arquivos',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaProgressIndicator(
              key: GjaProgressIndicatorPage.advancingKey,
              percentValue: _sent,
              semanticLabel: 'Envio de arquivos',
            ),
            GjaHBox(
              gap: GjaSpace.s,
              items: [
                GjaButton(
                  text: 'Avançar',
                  enabled: _sent < 100,
                  onPress: () =>
                      setState(() => _sent = (_sent + 10).clamp(0, 100)),
                ),
                GjaButton(
                  text: 'Reiniciar',
                  type: GjaButtonType.transparent,
                  onPress: () => setState(() => _sent = 0),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
