import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaForm": formulário de fornecedor com dois contêineres e um
/// resumo dos valores.
class GjaFormPage extends StatefulWidget {
  /// Cria a página.
  const GjaFormPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaForm';

  /// Rota nomeada.
  static const route = '/gja-form';

  @override
  State<GjaFormPage> createState() => _GjaFormPageState();
}

class _GjaFormPageState extends State<GjaFormPage> {
  String _name = '';
  String _city = '';
  String? _status = 'ativo';
  bool _preferred = false;

  @override
  Widget build(BuildContext context) {
    final summary = [
      if (_name.isNotEmpty) _name,
      if (_city.isNotEmpty) _city,
      if (_preferred) 'preferencial',
    ].join(', ');
    return GjaPage(
      title: GjaFormPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText(
          'Formulário no modelo do sap.ui.layout.form.Form com ColumnLayout: '
          'os rótulos sobem para cima dos campos em larguras pequenas.',
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaForm(
          editable: true,
          title: 'Fornecedor',
          formContainers: [
            GjaFormContainer(
              title: 'Dados',
              formElements: [
                GjaFormElement(
                  label: 'Nome',
                  required: true,
                  fields: [
                    GjaInput(
                      value: _name,
                      placeholder: 'Razão social',
                      onLiveChange: (value) => setState(() => _name = value),
                    ),
                  ],
                ),
                GjaFormElement(
                  label: 'Cidade',
                  fields: [
                    GjaInput(
                      value: _city,
                      placeholder: 'Cidade da sede',
                      onLiveChange: (value) => setState(() => _city = value),
                    ),
                  ],
                ),
                GjaFormElement(
                  label: 'Status',
                  fields: [
                    GjaSelect<String>(
                      semanticLabel: 'Status',
                      selectedKey: _status,
                      onChange: (value) => setState(() => _status = value),
                      items: const [
                        GjaDropdownItem(key: 'ativo', text: 'Ativo'),
                        GjaDropdownItem(key: 'inativo', text: 'Inativo'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            GjaFormContainer(
              title: 'Contato',
              formElements: [
                GjaFormElement(
                  label: 'E-mail',
                  fields: [
                    GjaInput(
                      placeholder: 'nome@empresa.com',
                      type: GjaInputType.email,
                      onLiveChange: (_) {},
                    ),
                  ],
                ),
                GjaFormElement(
                  label: 'Telefone',
                  fields: [
                    GjaInput(
                      placeholder: 'DDD',
                      type: GjaInputType.tel,
                      onLiveChange: (_) {},
                    ),
                    GjaInput(
                      placeholder: 'Número',
                      type: GjaInputType.tel,
                      onLiveChange: (_) {},
                    ),
                  ],
                ),
                GjaFormElement(
                  label: 'Preferencial',
                  fields: [
                    GjaCheckBox(
                      semanticLabel: 'Preferencial',
                      selected: _preferred,
                      onSelect: (value) => setState(() => _preferred = value),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const GjaSpacing.vertical(GjaSpace.l),
        GjaText('Resumo: $summary'),
        const GjaSpacing.vertical(GjaSpace.xl),
        GjaForm(
          title: 'Fornecedor (exibição)',
          formContainers: [
            GjaFormContainer(
              formElements: [
                GjaFormElement(
                  label: 'Nome',
                  fields: [GjaText(_name.isEmpty ? '—' : _name)],
                ),
                GjaFormElement(
                  label: 'Cidade',
                  fields: [GjaText(_city.isEmpty ? '—' : _city)],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
