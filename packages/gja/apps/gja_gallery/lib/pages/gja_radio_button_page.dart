import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaRadioButton": uma opção avulsa, um grupo de uma coluna e um
/// de duas.
class GjaRadioButtonPage extends StatefulWidget {
  /// Cria a página.
  const GjaRadioButtonPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaRadioButton';

  /// Rota nomeada.
  static const route = '/gja-radio-button';

  /// Texto da opção avulsa.
  static const single = 'Receber por e-mail';

  /// Opções do grupo de pagamento.
  static const payment = ['Boleto', 'Pix', 'Cartão'];

  @override
  State<GjaRadioButtonPage> createState() => _GjaRadioButtonPageState();
}

class _GjaRadioButtonPageState extends State<GjaRadioButtonPage> {
  bool _single = false;
  int _payment = 0;
  int _size = 1;

  @override
  Widget build(BuildContext context) {
    return GjaPage(
      title: GjaRadioButtonPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText(
          'Opções no modelo do sap.m.RadioButton e do RadioButtonGroup',
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaVBox(
          gap: GjaSpace.l,
          items: [
            GjaRadioButton(
              text: GjaRadioButtonPage.single,
              selected: _single,
              onSelect: (value) => setState(() => _single = value),
            ),
            const GjaTitle(
              'Pagamento',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            GjaRadioButtonGroup(
              selectedIndex: _payment,
              onSelect: (i) => setState(() => _payment = i),
              buttons: [
                for (final text in GjaRadioButtonPage.payment)
                  GjaRadioButton(text: text),
              ],
            ),
            const GjaTitle(
              'Tamanho, em duas colunas',
              level: GjaTitleLevel.h2,
              titleStyle: GjaTitleLevel.h3,
            ),
            SizedBox(
              width: 320,
              child: GjaRadioButtonGroup(
                columns: 2,
                selectedIndex: _size,
                onSelect: (i) => setState(() => _size = i),
                buttons: const [
                  GjaRadioButton(text: 'P'),
                  GjaRadioButton(text: 'M'),
                  GjaRadioButton(text: 'G'),
                  GjaRadioButton(text: 'GG', enabled: false),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
