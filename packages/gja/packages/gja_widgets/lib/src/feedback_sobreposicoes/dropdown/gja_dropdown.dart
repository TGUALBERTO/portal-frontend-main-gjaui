import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';

import '../popover/gja_popover.dart';
import 'gja_option_list.dart';

/// Item de um [GjaDropdown], como o `sap.ui.core.Item` do SAPUI5.
class GjaDropdownItem<T> {
  /// Cria o item [label] com o valor [value].
  const GjaDropdownItem({
    required this.key,
    required this.text,
    this.icon,
    this.additionalText,
    this.enabled = true,
  });

  /// Chave devolvida por `onSelectionChange` quando o item é escolhido.
  final T key;

  /// Texto do item, em uma linha.
  final String text;

  /// Ícone antes do texto, do catálogo `GjaIcons` ou da aplicação.
  final IconData? icon;

  /// Texto no fim do item, no tom `muted` (ex.: uma contagem).
  final String? additionalText;

  /// Se o item pode ser escolhido e receber o foco.
  final bool enabled;
}

/// Lista de itens selecionáveis num popover ancorado, como a lista do
/// `sap.m.Select` do SAPUI5.
///
/// O [controller] abre a lista junto de [child], na largura da âncora
/// (`GjaPopoverWidth.anchor`). O item cuja chave é [selectedKey] aparece
/// selecionado e recebe o foco ao abrir; sem ele, o foco vai ao primeiro item
/// habilitado. Escolher um item, por toque, Enter ou Espaço, fecha a lista e
/// chama [onSelectionChange]; toque fora e Esc fecham chamando [onDismiss].
///
/// Pelo teclado, as setas movem entre os itens habilitados, Home e End vão ao
/// primeiro e ao último, e uma letra leva ao próximo item que começa com ela.
/// A lista é anunciada como uma rota com o nome [semanticLabel], e cada item
/// como um botão com o estado de selecionado.
///
/// É a base de campos de seleção e menus; não é um campo.
///
/// ```dart
/// GjaDropdown<String>(
///   controller: status,
///   semanticLabel: 'Status',
///   selectedKey: atual,
///   items: const [
///     GjaDropdownItem(key: 'aberto', text: 'Em aberto'),
///     GjaDropdownItem(key: 'aprovado', text: 'Aprovado'),
///   ],
///   onSelectionChange: escolher,
///   child: GjaButton(text: 'Status', onPress: status.toggle),
/// )
/// ```
class GjaDropdown<T> extends StatelessWidget {
  /// Cria o dropdown de [items], ancorado em [child].
  GjaDropdown({
    required this.controller,
    required this.items,
    required this.onSelectionChange,
    required this.semanticLabel,
    required this.child,
    this.selectedKey,
    this.placement = GjaPlacement.bottom,
    this.onDismiss,
    super.key,
  }) : assert(items.isNotEmpty, 'items não pode ser vazia'),
       assert(
         items.map((item) => item.key).toSet().length == items.length,
         'os valores dos itens devem ser distintos',
       ),
       assert(
         items.every((item) => item.text != ''),
         'os rótulos não podem ser vazios',
       ),
       assert(semanticLabel != '', 'semanticLabel não pode ser vazio');

  /// Abre e fecha a lista.
  final GjaPopoverController controller;

  /// Itens, na ordem da lista.
  final List<GjaDropdownItem<T>> items;

  /// Chamado com o valor do item escolhido.
  final ValueChanged<T> onSelectionChange;

  /// Nome da lista para leitores de tela.
  final String semanticLabel;

  /// A âncora.
  final Widget child;

  /// Chave do item selecionado, ou nula.
  final T? selectedKey;

  /// Posição preferida em relação à âncora.
  final GjaPlacement placement;

  /// Chamado quando a lista fecha por toque fora ou Esc.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return GjaOptionList(
      controller: controller,
      semanticLabel: semanticLabel,
      placement: placement,
      onDismiss: onDismiss,
      options: [
        for (final item in items)
          GjaOption(
            label: item.text,
            icon: item.icon,
            trailing: item.additionalText,
            selected: item.key == selectedKey,
            onChosen: item.enabled ? () => onSelectionChange(item.key) : null,
          ),
      ],
      child: child,
    );
  }
}
