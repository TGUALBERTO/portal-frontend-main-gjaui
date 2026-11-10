import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaObjectStatus": status por estado, invertidos, com título e
/// um ativo que mostra uma mensagem.
class GjaObjectStatusPage extends StatefulWidget {
  /// Cria a página.
  const GjaObjectStatusPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaObjectStatus';

  /// Rota nomeada.
  static const route = '/gja-object-status';

  /// Texto do status ativo de exemplo.
  static const pending = '3 pendências';

  /// Mensagem mostrada ao acionar o status ativo.
  static const opened = 'Abrindo pendências';

  @override
  State<GjaObjectStatusPage> createState() => _GjaObjectStatusPageState();
}

class _GjaObjectStatusPageState extends State<GjaObjectStatusPage> {
  bool _opened = false;

  static const _examples = [
    (GjaValueState.success, GjaIcons.sysEnter2, 'Aprovado'),
    (GjaValueState.warning, GjaIcons.warning, 'Atrasado'),
    (GjaValueState.error, GjaIcons.error, 'Rejeitado'),
    (GjaValueState.information, GjaIcons.pending, 'Em análise'),
    (GjaValueState.none, GjaIcons.document, 'Rascunho'),
  ];

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaObjectStatusPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Situação de registros, no modelo do ObjectStatus'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            const GjaTitle(
              'Por estado',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            for (final (state, icon, text) in _examples)
              GjaHBox(
                gap: GjaSpace.l,
                items: [
                  GjaObjectStatus(icon: icon, text: text, state: state),
                  GjaObjectStatus(text: text, state: state, inverted: true),
                ],
              ),
            const GjaTitle(
              'Com título',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            const GjaObjectStatus(
              title: 'Situação',
              icon: GjaIcons.sysEnter2,
              text: 'Aprovado',
              state: GjaValueState.success,
            ),
            const GjaTitle(
              'Ativo',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaObjectStatus(
              icon: GjaIcons.warning,
              text: GjaObjectStatusPage.pending,
              state: GjaValueState.warning,
              onPress: () => setState(() => _opened = true),
            ),
            if (_opened) const GjaText(GjaObjectStatusPage.opened),
          ],
        ),
      ],
    );
  }
}
