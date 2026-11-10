import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_primitives.dart';
import 'package:gja_ui/gja_ui.dart';
import 'gallery_comparison.dart';

/// Página "Tema": brilho, densidade e marca de exemplo, com uma prévia
/// montada só a partir do `GjaThemeData` escolhido.
class ThemePage extends StatefulWidget {
  /// Cria a página.
  const ThemePage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Tema';

  /// Rota nomeada.
  static const route = '/theme';

  /// Chave da superfície da prévia.
  static const previewKey = Key('theme-preview-surface');

  /// Chave do texto com os problemas de acessibilidade.
  static const issuesKey = Key('theme-accessibility-issues');

  /// Tema da escolha atual.
  static GjaThemeData themeFor({
    required bool dark,
    required bool compact,
    required bool brand,
  }) {
    final density = compact ? GjaDensity.compact : GjaDensity.cozy;
    var theme = dark
        ? GjaThemeData.dark(density: density)
        : GjaThemeData.light(density: density);
    if (brand) {
      theme = theme.copyWith(
        colors: dark
            ? theme.colors.copyWith(
                brand: GjaColorPrimitives.cyan300,
                brandHover: GjaColorPrimitives.cyan200,
                highlight: GjaColorPrimitives.cyan100,
                contrastText: GjaColorPrimitives.cyan900,
                link: GjaColorPrimitives.cyan300,
                focus: GjaColorPrimitives.cyan300,
                selectionBackground: GjaColorPrimitives.cyan800,
                selectionHoverBackground: GjaColorPrimitives.cyan900,
              )
            : theme.colors.copyWith(
                brand: GjaColorPrimitives.cyan700,
                brandHover: GjaColorPrimitives.cyan800,
                highlight: GjaColorPrimitives.cyan900,
                contrastText: GjaColorPrimitives.white,
                link: GjaColorPrimitives.cyan700,
                focus: GjaColorPrimitives.cyan700,
                selectionBackground: GjaColorPrimitives.cyan50,
                selectionHoverBackground: GjaColorPrimitives.cyan100,
              ),
      );
    }
    return theme;
  }

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  bool _dark = false;
  bool _compact = false;
  bool _brand = false;

  @override
  Widget build(BuildContext context) {
    final theme = ThemePage.themeFor(
      dark: _dark,
      compact: _compact,
      brand: _brand,
    );
    final page = GjaThemeData.of(context);
    final issues = theme.accessibilityIssues();

    Widget toggle(String label, bool value, ValueChanged<bool> onChanged) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => onChanged(!value)),
        child: Semantics(
          button: true,
          toggled: value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: page.spacing.m,
              vertical: page.spacing.s,
            ),
            decoration: BoxDecoration(
              color: value
                  ? page.colors.selectionBackground
                  : page.colors.headerBackground,
              borderRadius: BorderRadius.circular(page.radius.button),
            ),
            child: Text(label),
          ),
        ),
      );
    }

    return ColoredBox(
      color: page.colors.base,
      child: DefaultTextStyle(
        style: page.typography.base.copyWith(color: page.colors.text),
        child: ListView(
          padding: EdgeInsets.all(page.spacing.pageMargin),
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Semantics(button: true, child: const Text('← Voltar')),
            ),
            SizedBox(height: page.spacing.stackGap),
            Text(ThemePage.title, style: page.typography.header2),
            SizedBox(height: page.spacing.stackGap),
            Wrap(
              spacing: page.spacing.s,
              runSpacing: page.spacing.s,
              children: [
                toggle(_dark ? 'Escuro' : 'Claro', _dark, (v) => _dark = v),
                toggle(
                  _compact ? 'Compacto' : 'Confortável',
                  _compact,
                  (v) => _compact = v,
                ),
                toggle(_brand ? 'Marca' : 'Padrão', _brand, (v) => _brand = v),
              ],
            ),
            SizedBox(height: page.spacing.sectionGap),
            GalleryComparison(child: _Preview(theme: theme)),
            SizedBox(height: page.spacing.stackGap),
            Text(
              issues.isEmpty
                  ? 'Problemas de acessibilidade: nenhum'
                  : 'Problemas de acessibilidade: ${issues.join('; ')}',
              key: ThemePage.issuesKey,
              style: page.typography.small.copyWith(color: page.colors.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prévia montada somente com [theme].
class _Preview extends StatelessWidget {
  const _Preview({required this.theme});

  final GjaThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: EdgeInsets.all(t.spacing.l),
      color: t.colors.background,
      child: Container(
        key: ThemePage.previewKey,
        padding: EdgeInsets.all(t.spacing.l),
        decoration: BoxDecoration(
          color: t.colors.base,
          borderRadius: BorderRadius.circular(t.radius.tile),
          boxShadow: t.shadows.boxShadows(t.shadows.card, t.colors.shadow),
        ),
        child: DefaultTextStyle(
          style: t.typography.base.copyWith(color: t.colors.text),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pedido de material', style: t.typography.header3),
              SizedBox(height: t.spacing.xs),
              Text(
                'Prévia montada só com o tema escolhido.',
                style: t.typography.base.copyWith(color: t.colors.label),
              ),
              SizedBox(height: t.spacing.stackGap),
              Container(
                height: t.density.controlHeight,
                padding: EdgeInsets.symmetric(horizontal: t.spacing.m),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: t.colors.base,
                  border: Border.all(color: t.colors.fieldBorder),
                  borderRadius: BorderRadius.circular(t.radius.field),
                ),
                child: Text('Código do material', style: t.typography.base),
              ),
              SizedBox(height: t.spacing.stackGap),
              Container(
                height: t.density.controlHeight,
                padding: EdgeInsets.symmetric(horizontal: t.spacing.l),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.colors.brand,
                  borderRadius: BorderRadius.circular(t.radius.button),
                ),
                child: Text(
                  'Enviar',
                  style: t.typography.base.copyWith(
                    color: t.colors.contrastText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
