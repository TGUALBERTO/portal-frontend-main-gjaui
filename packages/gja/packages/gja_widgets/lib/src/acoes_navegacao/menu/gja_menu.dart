import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';

import '../../feedback_sobreposicoes/dropdown/gja_option_list.dart';
import '../../feedback_sobreposicoes/popover/gja_popover.dart';

/// Item de um [GjaMenu], como o `sap.m.MenuItem` do SAPUI5.
class GjaMenuItem {
  /// Cria o item [text], que chama [onPress] ao ser acionado.
  const GjaMenuItem({
    required this.text,
    this.enabled = true,
    this.onPress,
    this.icon,
    this.shortcutText,
    this.startsSection = false,
  });

  /// Rótulo do item, em uma linha.
  final String text;

  /// Se o item pode ser acionado.
  final bool enabled;

  /// Ação do item, como o evento `press` do `sap.m.MenuItem`.
  final VoidCallback? onPress;

  /// Ícone antes do rótulo, do catálogo `GjaIcons` ou da aplicação.
  final IconData? icon;

  /// Atalho exibido no fim do item, no tom `muted` (ex.: "Ctrl+E"), como o
  /// `shortcutText` do UI5. Só exibe; o atalho não é registrado.
  final String? shortcutText;

  /// Se um separador vem antes do item, abrindo uma seção.
  final bool startsSection;
}

/// Menu de ações num popover ancorado, como o `sap.m.Menu` do SAPUI5.
///
/// O [controller] abre o menu junto de [child], na largura da âncora (no
/// mínimo 6 passos `spacing.xxxl`). Acionar um item, por toque, Enter ou
/// Espaço, fecha o menu e chama o `onPress` dele; toque fora e Esc fecham
/// chamando [onDismiss]. O menu não tem item selecionado.
///
/// O foco abre no primeiro item habilitado; as setas, Home, End e a primeira
/// letra navegam entre os itens. A lista é anunciada com o papel `menu` e os
/// itens com o papel `menuItem`, dentro de uma rota com o nome
/// [semanticLabel].
///
/// ```dart
/// GjaMenu(
///   controller: acoes,
///   semanticLabel: 'Ações',
///   items: [
///     GjaMenuItem(text: 'Editar', icon: GjaIcons.edit, onPress: editar),
///     GjaMenuItem(text: 'Copiar', icon: GjaIcons.copy, onPress: copiar),
///     GjaMenuItem(
///       text: 'Excluir',
///       icon: GjaIcons.delete,
///       startsSection: true,
///       onPress: excluir,
///     ),
///   ],
///   child: GjaButton(text: 'Ações', onPress: acoes.toggle),
/// )
/// ```
class GjaMenu extends StatelessWidget {
  /// Cria o menu de [items], ancorado em [child].
  GjaMenu({
    required this.controller,
    required this.items,
    required this.semanticLabel,
    required this.child,
    this.placement = GjaPlacement.bottom,
    this.onDismiss,
    super.key,
  }) : assert(items.isNotEmpty, 'items não pode ser vazia'),
       assert(
         items.every((item) => item.text != ''),
         'os rótulos não podem ser vazios',
       ),
       assert(semanticLabel != '', 'semanticLabel não pode ser vazio');

  /// Abre e fecha o menu.
  final GjaPopoverController controller;

  /// Itens, na ordem do menu.
  final List<GjaMenuItem> items;

  /// Nome do menu para leitores de tela.
  final String semanticLabel;

  /// A âncora.
  final Widget child;

  /// Posição preferida em relação à âncora.
  final GjaPlacement placement;

  /// Chamado quando o menu fecha por toque fora ou Esc.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return GjaOptionList(
      controller: controller,
      semanticLabel: semanticLabel,
      placement: placement,
      onDismiss: onDismiss,
      listRole: SemanticsRole.menu,
      itemRole: SemanticsRole.menuItem,
      options: [
        for (final item in items)
          GjaOption(
            label: item.text,
            icon: item.icon,
            trailing: item.shortcutText,
            startsSection: item.startsSection,
            onChosen: item.enabled ? (item.onPress ?? () {}) : null,
          ),
      ],
      child: child,
    );
  }
}
