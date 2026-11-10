import 'package:gjamobile/src/features/kba/domain/entities/kba_question.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Card de uma pergunta do KBA com opções de múltipla escolha selecionáveis.
/// A numeração fica no título do passo do Stepper, não no enunciado.
class KbaQuestionCard extends StatelessWidget {
  const KbaQuestionCard({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
    this.enabled = true,
  });

  final KbaQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.prompt,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < question.options.length; i++) ...[
            _OptionTile(
              label: question.options[i],
              selected: selectedIndex == i,
              onTap: enabled ? () => onSelect(i) : null,
            ),
            if (i < question.options.length - 1)
              SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorders.card,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppBorders.card,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? cs.primary.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? GjaIcons.circleTask2 : GjaIcons.circleTask,
              size: 20,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
