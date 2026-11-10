import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';
import 'gallery_comparison.dart';

/// Página "Cores": papéis e estados de valor nos modos claro e escuro, com a
/// razão de contraste de cada par de texto.
///
/// Espaçamentos e tamanhos são literais provisórios até existirem os
/// fundamentos de espaçamento e tipografia; a galeria é aplicação, fora da
/// verificação de tokens.
class ColorPage extends StatelessWidget {
  /// Cria a página.
  const ColorPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Cores';

  /// Rota nomeada.
  static const route = '/colors';

  @override
  Widget build(BuildContext context) {
    final light = GjaThemeData.of(context).colors;
    return ColoredBox(
      color: light.base,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Semantics(button: true, child: const Text('← Voltar')),
            ),
            const SizedBox(height: 16),
            const Text(title, style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                GalleryComparison(
                  child: _ModePanel(
                    label: 'Claro',
                    tokens: GjaColorTokens.light(),
                  ),
                ),
                GalleryComparison(
                  child: _ModePanel(
                    label: 'Escuro',
                    tokens: GjaColorTokens.dark(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({required this.label, required this.tokens});

  final String label;
  final GjaColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    const containers = ['background', 'base', 'headerBackground'];
    const hoverAndSelection = [
      'hoverBackground',
      'selectionBackground',
      'selectionHoverBackground',
    ];
    (String, Color, String, Color) role(String fg, String bg) =>
        (fg, t.roles[fg]!, bg, t.roles[bg]!);
    final textPairs = <(String, Color, String, Color)>[
      for (final bg in [...containers, ...hoverAndSelection]) role('text', bg),
      for (final bg in containers) ...[role('label', bg), role('link', bg)],
      for (final bg in ['background', 'base', ...hoverAndSelection])
        role('brand', bg),
      for (final bg in ['brand', 'brandHover', 'highlight'])
        role('contrastText', bg),
      for (final state in GjaValueState.values) ...[
        (
          '${state.name}.foreground',
          t.stateColors(state).foreground,
          'base',
          t.base,
        ),
        (
          '${state.name}.foreground',
          t.stateColors(state).foreground,
          '${state.name}.background',
          t.stateColors(state).background,
        ),
      ],
    ];
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      color: t.background,
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 14, color: t.text),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            for (final MapEntry(key: role, value: color) in t.roles.entries)
              _Swatch(
                name: '$label · $role',
                color: color,
                border: t.separator,
              ),
            const SizedBox(height: 12),
            for (final (fgName, fg, bgName, bg) in textPairs)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: bg,
                child: Text(
                  '$fgName / $bgName — '
                  '${gjaContrastRatioOver(fg, bg).toStringAsFixed(2)}:1',
                  style: TextStyle(color: fg),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.color,
    required this.border,
  });

  final String name;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: border),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
        ],
      ),
    );
  }
}
