import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "Interação": um elemento interativo que mostra os estados ativos e
/// o número de ativações, ao lado de um elemento desabilitado.
class InteractionPage extends StatefulWidget {
  /// Cria a página.
  const InteractionPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Interação';

  /// Rota nomeada.
  static const route = '/interaction';

  /// Chave do elemento habilitado.
  static const enabledKey = Key('interaction-enabled');

  /// Chave do texto com os estados ativos.
  static const statesKey = Key('interaction-states');

  /// Texto exibido para [states].
  static String describe(Set<GjaInteractionState> states) => states.isEmpty
      ? 'estados: normal'
      : 'estados: ${(states.map((s) => s.name).toList()..sort()).join(', ')}';

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final theme = GjaTheme.of(context);
    final colors = theme.colors;
    final spacing = theme.spacing;
    final typography = theme.typography;

    Widget sample({
      required String label,
      VoidCallback? onPressed,
      Key? key,
      Key? statesKey,
    }) {
      return GjaInteractable(
        key: key,
        onPressed: onPressed,
        semanticLabel: label,
        builder: (context, states) {
          final c = GjaControlColors.of(
            GjaControlFamily.list,
            colors,
          ).resolve(states);
          final content = c.text;
          return Opacity(
            opacity: theme.interaction.opacity(states),
            child: Container(
              width: 220,
              padding: EdgeInsets.all(spacing.m),
              decoration: BoxDecoration(
                color: c.background,
                border: Border.all(color: colors.separator),
                borderRadius: BorderRadius.circular(theme.radius.button),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: typography.base.copyWith(color: content)),
                  Text(
                    InteractionPage.describe(states),
                    key: statesKey,
                    style: typography.small.copyWith(color: content),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return ColoredBox(
      color: colors.base,
      child: DefaultTextStyle(
        style: typography.base.copyWith(color: colors.text),
        child: ListView(
          padding: EdgeInsets.all(spacing.pageMargin),
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Semantics(button: true, child: const Text('← Voltar')),
            ),
            SizedBox(height: spacing.stackGap),
            Text(InteractionPage.title, style: typography.header2),
            SizedBox(height: spacing.sectionGap),
            Wrap(
              spacing: spacing.l,
              runSpacing: spacing.l,
              children: [
                sample(
                  label: 'Elemento habilitado',
                  onPressed: () => setState(() => _count++),
                  key: InteractionPage.enabledKey,
                  statesKey: InteractionPage.statesKey,
                ),
                sample(label: 'Elemento desabilitado'),
              ],
            ),
            SizedBox(height: spacing.stackGap),
            Text('Ativações: $_count'),
            Text(
              'Use Tab para ver o anel de foco; Enter ou Espaço ativam.',
              style: typography.small.copyWith(color: colors.label),
            ),
          ],
        ),
      ),
    );
  }
}
