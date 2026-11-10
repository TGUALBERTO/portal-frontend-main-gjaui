import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';
import 'gallery_comparison.dart';

/// Página "Sombras": uma superfície por sombra e por papel, nos dois modos.
///
/// As sombras vêm de `GjaShadowTokens.boxShadows` com a cor `shadow` de
/// cada modo. As dimensões do cartão são literais da galeria.
class ShadowsPage extends StatelessWidget {
  /// Cria a página.
  const ShadowsPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Sombras';

  /// Rota nomeada.
  static const route = '/shadows';

  /// Chave do cartão da sombra ou papel [shadow] no modo [mode].
  static Key cardKey(String mode, String shadow) =>
      ValueKey('shadows-$mode-$shadow');

  @override
  Widget build(BuildContext context) {
    final light = GjaThemeData.of(context).colors;
    final spacing = GjaThemeData.of(context).spacing;
    final typography = GjaThemeData.of(context).typography;

    return ColoredBox(
      color: light.base,
      child: DefaultTextStyle(
        style: typography.base.copyWith(color: light.text),
        child: ListView(
          padding: EdgeInsets.all(spacing.pageMargin),
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Semantics(button: true, child: const Text('← Voltar')),
            ),
            SizedBox(height: spacing.stackGap),
            Text(title, style: typography.header2),
            SizedBox(height: spacing.sectionGap),
            const GalleryComparison(
              child: _ModeStrip(
                mode: 'claro',
                colors: GjaColorTokens.light(),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            const GalleryComparison(
              child: _ModeStrip(
                mode: 'escuro',
                colors: GjaColorTokens.dark(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeStrip extends StatelessWidget {
  const _ModeStrip({required this.mode, required this.colors});

  final String mode;
  final GjaColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final shadows = GjaThemeData.of(context).shadows;
    final radius = GjaThemeData.of(context).radius;
    final spacing = GjaThemeData.of(context).spacing;
    final typography = GjaThemeData.of(context).typography;

    return Container(
      padding: EdgeInsets.all(spacing.xl),
      color: colors.background,
      child: DefaultTextStyle(
        style: typography.base.copyWith(color: colors.text),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mode, style: typography.header3),
            SizedBox(height: spacing.l),
            Wrap(
              spacing: spacing.xl,
              runSpacing: spacing.xl,
              children: [
                for (final MapEntry(key: name, value: shadow)
                    in shadows.values.entries)
                  Container(
                    key: ShadowsPage.cardKey(mode, name),
                    width: 120,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.base,
                      borderRadius: BorderRadius.circular(radius.tile),
                      boxShadow: shadows.boxShadows(shadow, colors.shadow),
                    ),
                    child: Text(name, style: typography.base),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
