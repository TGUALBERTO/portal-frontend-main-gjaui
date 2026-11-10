import '../../imports/imports.dart';

/// Dropdown pesquisável de uma opção de filtro, com uma entrada "Todos"
/// ([todosValue]) que limpa o filtro.
///
/// O `key: ValueKey(valor)` não é decorativo: é ele que faz o menu reconstruir
/// quando a seleção muda **por fora** (um botão "Limpar filtros", por exemplo).
/// Sem essa key o `DropdownMenu` mantém o rótulo antigo mesmo com o filtro já
/// limpo — foi por isso que este widget virou compartilhado em vez de copiado.
class AppFilterDropdown<T> extends StatelessWidget {
  const AppFilterDropdown({
    super.key,
    required this.rotulo,
    required this.todosLabel,
    required this.todosValue,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
    this.largura,
  });

  final String rotulo;

  /// Rótulo da entrada que representa "sem filtro".
  final String todosLabel;

  /// Valor sentinela de "sem filtro" (ex.: `''` para String, `0` para int).
  final T todosValue;

  final T valor;
  final List<({T valor, String label})> opcoes;
  final ValueChanged<T> onChanged;

  /// Largura fixa do campo. Nula deixa o dropdown ocupar a largura que o pai
  /// oferecer — o que uma barra em coluna estreita quer, e uma barra horizontal
  /// (como a do BI) não, já que ali os filtros dividem a linha.
  final double? largura;

  @override
  Widget build(BuildContext context) {
    final largura = this.largura;
    if (largura == null) return _menu(context);
    return SizedBox(width: largura, child: _menu(context));
  }

  Widget _menu(BuildContext context) {
    return DropdownMenu<T>(
      key: ValueKey<T>(valor),
      initialSelection: valor,
      enableFilter: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 360,
      label: Text(rotulo),
      onSelected: (v) {
        if (v != null) onChanged(v);
      },
      dropdownMenuEntries: [
        DropdownMenuEntry<T>(value: todosValue, label: todosLabel),
        for (final o in opcoes)
          DropdownMenuEntry<T>(value: o.valor, label: o.label),
      ],
    );
  }
}
