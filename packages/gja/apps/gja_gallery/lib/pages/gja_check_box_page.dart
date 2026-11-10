import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaCheckBox": caixas interativas, uma parcial que reflete o
/// grupo, os estados de valor, somente leitura e desabilitada.
class GjaCheckBoxPage extends StatefulWidget {
  /// Cria a página.
  const GjaCheckBoxPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaCheckBox';

  /// Rota nomeada.
  static const route = '/gja-check-box';

  /// Texto da caixa de exemplo.
  static const terms = 'Aceito os termos';

  @override
  State<GjaCheckBoxPage> createState() => _GjaCheckBoxPageState();
}

class _GjaCheckBoxPageState extends State<GjaCheckBoxPage> {
  bool _terms = false;
  final _channels = <String, bool>{'E-mail': true, 'SMS': false, 'Push': false};

  @override
  Widget build(BuildContext context) {
    final marked = _channels.values.where((v) => v).length;
    return GjaPage(
      title: GjaCheckBoxPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Caixas de seleção no modelo do sap.m.CheckBox'),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            GjaCheckBox(
              text: GjaCheckBoxPage.terms,
              selected: _terms,
              onSelect: (value) => setState(() => _terms = value),
            ),
            const GjaTitle(
              'Grupo com caixa parcial',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaVBox(
              gap: GjaSpace.none,
              items: [
                GjaCheckBox(
                  text: 'Todos os canais',
                  selected: marked == _channels.length,
                  partiallySelected: marked > 0 && marked < _channels.length,
                  onSelect: (value) =>
                      setState(() => _channels.updateAll((_, _) => value)),
                ),
                for (final entry in _channels.entries)
                  GjaCheckBox(
                    text: entry.key,
                    selected: entry.value,
                    onSelect: (value) =>
                        setState(() => _channels[entry.key] = value),
                  ),
              ],
            ),
            const GjaTitle(
              'Estados de valor, somente leitura e desabilitada',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaHBox(
              wrap: GjaFlexWrap.wrap,
              alignItems: GjaFlexAlignItems.start,
              items: [
                for (final state in GjaValueState.values)
                  GjaCheckBox(
                    text: state.name,
                    valueState: state,
                    selected: true,
                    onSelect: (_) {},
                  ),
                const GjaCheckBox(
                  text: 'Somente leitura',
                  selected: true,
                  editable: false,
                ),
                const GjaCheckBox(text: 'Desabilitada', enabled: false),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
