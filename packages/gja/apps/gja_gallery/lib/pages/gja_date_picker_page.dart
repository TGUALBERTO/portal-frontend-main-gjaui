import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaDatePicker": data de entrega a partir de hoje.
class GjaDatePickerPage extends StatefulWidget {
  /// Cria a página.
  const GjaDatePickerPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaDatePicker';

  /// Rota nomeada.
  static const route = '/gja-date-picker';

  @override
  State<GjaDatePickerPage> createState() => _GjaDatePickerPageState();
}

class _GjaDatePickerPageState extends State<GjaDatePickerPage> {
  DateTime? _delivery;

  @override
  Widget build(BuildContext context) {
    final l10n = GjaLocalizations.of(context);
    final now = DateTime.now();
    final delivery = _delivery;
    return GjaPage(
      title: GjaDatePickerPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText(
          'Seletor no modelo do sap.m.DatePicker: digite a data ou abra o '
          'calendário pelo ícone, F4 ou Alt+seta para baixo.',
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaForm(
          editable: true,
          formContainers: [
            GjaFormContainer(
              formElements: [
                GjaFormElement(
                  label: 'Entrega',
                  required: true,
                  fields: [
                    GjaDatePicker(
                      semanticLabel: 'Data de entrega',
                      dateValue: delivery,
                      minDate: DateTime(now.year, now.month, now.day),
                      showCurrentDateButton: true,
                      onChange: (date) => setState(() => _delivery = date),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaText(
          delivery == null
              ? 'Entrega: não definida'
              : 'Entrega: ${l10n.formatDate(delivery)}',
        ),
      ],
    );
  }
}
