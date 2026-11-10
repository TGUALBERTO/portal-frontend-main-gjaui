import 'package:gjamobile/src/imports/imports.dart';

import '../../data/models/colaborador_ref.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Seletor de colaborador do painel "Performance Individual". Dropdown pesquisável
/// (por nome). Sem seleção, mostra "Selecione um funcional".
class ColaboradorPicker extends StatelessWidget {
  const ColaboradorPicker({
    super.key,
    required this.colaboradores,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ColaboradorRef> colaboradores;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          // A key força o DropdownMenu a reaplicar `initialSelection` quando a
          // seleção muda por fora (ex.: pré-seleção do usuário logado após a
          // lista carregar).
          child: DropdownMenu<int>(
            key: ValueKey<int?>(selectedId),
            initialSelection: selectedId,
            enableFilter: true,
            requestFocusOnTap: true,
            expandedInsets: EdgeInsets.zero,
            menuHeight: 360,
            leadingIcon: const Icon(GjaIcons.employeeLookup),
            label: const Text('Colaborador'),
            hintText: 'Selecione um funcional',
            onSelected: (id) {
              if (id != null) onChanged(id);
            },
            dropdownMenuEntries: [
              for (final c in colaboradores)
                DropdownMenuEntry<int>(value: c.id, label: c.nome),
            ],
          ),
        ),
      ),
    );
  }
}
