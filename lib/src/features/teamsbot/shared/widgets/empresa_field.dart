import 'package:gjamobile/src/imports/imports.dart';

import 'package:gjamobile/src/features/teamsbot/shared/empresas.dart';

/// Campo de empresa: dropdown com as empresas do grupo + "Outros" (libera a
/// digitação livre do nome).
///
/// O valor efetivo é sincronizado no [controller] (`controller.text`), então
/// quem já lia o campo de texto continua funcionando sem mudanças: selecionar
/// uma empresa grava o label; "Outros" grava o que for digitado; a opção vazia
/// ([emptyLabel]) limpa o controller.
class EmpresaField extends StatefulWidget {
  const EmpresaField({
    super.key,
    required this.controller,
    this.label = 'Empresa',
    this.emptyLabel = 'Não informada',
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;

  /// Rótulo da opção "sem empresa" (ex.: `'Todas'` em filtros).
  final String emptyLabel;

  /// Notifica quando o valor efetivo muda por seleção no dropdown (empresa
  /// escolhida ou limpeza). NÃO dispara ao selecionar "Outros" nem durante a
  /// digitação — evita aplicar filtro com nome pela metade.
  final VoidCallback? onChanged;

  @override
  State<EmpresaField> createState() => _EmpresaFieldState();
}

class _EmpresaFieldState extends State<EmpresaField> {
  EmpresaOption? _selecao;
  final _outrosFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selecao = _selecaoPeloTexto(widget.controller.text);
    widget.controller.addListener(_syncComController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncComController);
    _outrosFocus.dispose();
    super.dispose();
  }

  EmpresaOption? _selecaoPeloTexto(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return null;
    return EmpresaOption.fromLabel(t) ?? EmpresaOption.outros;
  }

  /// Mantém o dropdown coerente quando o controller muda por fora (ex.: botão
  /// "Limpar" da tela). Não interfere enquanto o usuário digita em "Outros".
  void _syncComController() {
    if (_outrosFocus.hasFocus) return;
    final nova = _selecaoPeloTexto(widget.controller.text);
    if (nova != _selecao && !(_selecao?.isOutros ?? false)) {
      setState(() => _selecao = nova);
    } else if (nova == null && (_selecao?.isOutros ?? false)) {
      setState(() => _selecao = null);
    }
  }

  void _onSelect(EmpresaOption? opcao) {
    setState(() => _selecao = opcao);
    if (opcao == null) {
      widget.controller.clear();
      widget.onChanged?.call();
    } else if (opcao.isOutros) {
      // Limpa labels conhecidos para o usuário digitar o nome livremente.
      if (EmpresaOption.fromLabel(widget.controller.text) != null) {
        widget.controller.clear();
      }
      _outrosFocus.requestFocus();
    } else {
      widget.controller.text = opcao.label;
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mostraOutros = _selecao?.isOutros ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<EmpresaOption?>(
          initialValue: _selecao,
          isExpanded: true,
          decoration: InputDecoration(isDense: true, labelText: widget.label),
          items: [
            DropdownMenuItem<EmpresaOption?>(
              value: null,
              child: Text(widget.emptyLabel),
            ),
            for (final e in EmpresaOption.values)
              DropdownMenuItem<EmpresaOption?>(value: e, child: Text(e.label)),
          ],
          onChanged: _onSelect,
        ),
        if (mostraOutros) ...[
          SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Nome da empresa',
            controller: widget.controller,
            focusNode: _outrosFocus,
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }
}
