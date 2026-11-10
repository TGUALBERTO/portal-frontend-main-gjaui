import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "GjaInput": um campo com saudação, campos de cada tipo, um com
/// limite, um com ícone de limpar, um com validação e campos somente leitura
/// e desabilitado.
class GjaInputPage extends StatefulWidget {
  /// Cria a página.
  const GjaInputPage({super.key});

  /// Título no índice e na página.
  static const title = 'GjaInput';

  /// Rota nomeada.
  static const route = '/gja-input';

  /// Rótulo do campo de nome.
  static const nameLabel = 'Nome';

  @override
  State<GjaInputPage> createState() => _GjaInputPageState();
}

class _GjaInputPageState extends State<GjaInputPage> {
  String _name = '';
  String _search = 'Pedidos de outubro';
  String _code = '';
  String _email = '';

  @override
  Widget build(BuildContext context) {
    final emailState = _email.isEmpty || _email.contains('@')
        ? GjaValueState.none
        : GjaValueState.error;
    Widget field(String label, Widget input) => GjaVBox(
      gap: GjaSpace.xxs,
      alignItems: GjaFlexAlignItems.stretch,
      items: [GjaLabel(label), input],
    );

    return GjaPage(
      title: GjaInputPage.title,
      showNavButton: true,
      onNavButtonPress: () => Navigator.of(context).maybePop(),
      contentPadding: GjaContentPadding.responsive,
      content: [
        const GjaText('Campos de texto no modelo do sap.m.Input'),
        const GjaSpacing.vertical(GjaSpace.l),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GjaVBox(
              gap: GjaSpace.m,
              alignItems: GjaFlexAlignItems.stretch,
              items: [
                field(
                  GjaInputPage.nameLabel,
                  GjaInput(
                    semanticLabel: GjaInputPage.nameLabel,
                    placeholder: 'Nome completo',
                    value: _name,
                    onLiveChange: (value) => setState(() => _name = value),
                  ),
                ),
                if (_name.isNotEmpty) GjaText('Olá, $_name'),
                field(
                  'E-mail',
                  GjaInput(
                    semanticLabel: 'E-mail',
                    type: GjaInputType.email,
                    value: _email,
                    valueState: emailState,
                    valueStateText: 'Informe um e-mail válido',
                    onLiveChange: (value) => setState(() => _email = value),
                  ),
                ),
                field(
                  'Senha',
                  const GjaInput(
                    semanticLabel: 'Senha',
                    type: GjaInputType.password,
                    value: 'segredo',
                  ),
                ),
                field(
                  'Código (até 6 caracteres)',
                  GjaInput(
                    semanticLabel: 'Código',
                    maxLength: 6,
                    value: _code,
                    onLiveChange: (value) => setState(() => _code = value),
                  ),
                ),
                field(
                  'Pesquisa',
                  GjaInput(
                    semanticLabel: 'Pesquisa',
                    showClearIcon: true,
                    value: _search,
                    onLiveChange: (value) => setState(() => _search = value),
                  ),
                ),
                field(
                  'Telefone',
                  const GjaInput(
                    semanticLabel: 'Telefone',
                    type: GjaInputType.tel,
                    placeholder: '(00) 00000-0000',
                  ),
                ),
                field(
                  'Pedido',
                  const GjaInput(
                    semanticLabel: 'Pedido',
                    value: '4711',
                    editable: false,
                  ),
                ),
                field(
                  'Desabilitado',
                  const GjaInput(
                    semanticLabel: 'Desabilitado',
                    value: 'Indisponível',
                    enabled: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
