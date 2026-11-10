import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaSwitch": chaves interativas ao lado de rótulos e chaves
/// desabilitadas.
class GjaSwitchPage extends StatefulWidget {
  /// Cria a página.
  const GjaSwitchPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaSwitch';

  /// Rota nomeada.
  static const route = '/gja-switch';

  /// Rótulo da chave de exemplo.
  static const notifications = 'Notificações';

  @override
  State<GjaSwitchPage> createState() => _GjaSwitchPageState();
}

class _GjaSwitchPageState extends State<GjaSwitchPage> {
  final _settings = <String, bool>{
    GjaSwitchPage.notifications: false,
    'Modo escuro automático': true,
  };

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaSwitchPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Chaves no modelo do sap.m.Switch'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.s,
          items: [
            for (final entry in _settings.entries)
              GjaHBox(
                items: [
                  GjaSwitch(
                    semanticLabel: entry.key,
                    state: entry.value,
                    onChange: (value) =>
                        setState(() => _settings[entry.key] = value),
                  ),
                  GjaLabel(entry.key),
                ],
              ),
            const GjaHBox(
              items: [
                GjaSwitch(semanticLabel: 'Desabilitada', enabled: false),
                GjaSwitch(
                  semanticLabel: 'Desabilitada ligada',
                  state: true,
                  enabled: false,
                ),
                GjaLabel('Desabilitadas'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
