import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';
import 'gallery_comparison.dart';

/// Página "GjaTheme": troca animada entre claro e escuro, e uma subárvore
/// compacta ao lado de uma cozy.
///
/// Tudo abaixo do seletor fica num `GjaTheme` local; a prévia e os
/// elementos leem o tema ativo, sem receber valores visuais. As dimensões da
/// prévia são literais da galeria.
class GjaThemePage extends StatefulWidget {
  /// Cria a página.
  const GjaThemePage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'GjaTheme';

  /// Rota nomeada.
  static const route = '/gja-theme';

  /// Chave da prévia, cuja cor é a `base` do tema ativo.
  static const previewKey = Key('gja-theme-preview');

  /// Chave do elemento interativo da coluna cozy.
  static const cozyKey = Key('gja-theme-cozy');

  /// Chave do elemento interativo da coluna compacta.
  static const compactKey = Key('gja-theme-compact');

  @override
  State<GjaThemePage> createState() => _GjaThemePageState();
}

class _GjaThemePageState extends State<GjaThemePage> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    final page = GjaTheme.of(context);
    final spacing = page.spacing;
    return ColoredBox(
      color: page.colors.base,
      child: ListView(
        padding: EdgeInsets.all(spacing.pageMargin),
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Semantics(button: true, child: const Text('← Voltar')),
          ),
          SizedBox(height: spacing.stackGap),
          Text(GjaThemePage.title, style: page.typography.header2),
          SizedBox(height: spacing.stackGap),
          Align(
            alignment: Alignment.centerLeft,
            child: _Button(
              label: _dark ? 'Tema: escuro' : 'Tema: claro',
              onPressed: () => setState(() => _dark = !_dark),
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          // A prévia alterna o tema de propósito, independente da galeria.
          GalleryComparison(
            child: GjaTheme(
              data: _dark ? GjaThemeData.dark() : GjaThemeData.light(),
              child: const _Preview(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prévia que lê apenas o tema ativo.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final t = GjaTheme.of(context);
    return Container(
      key: GjaThemePage.previewKey,
      padding: EdgeInsets.all(t.spacing.l),
      decoration: BoxDecoration(
        color: t.colors.base,
        border: Border.all(color: t.colors.separator),
        borderRadius: BorderRadius.circular(t.radius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Texto e ícone padrão vêm do tema ativo.'),
          SizedBox(height: t.spacing.l),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DensityColumn(
                  label: 'Confortável',
                  targetKey: GjaThemePage.cozyKey,
                ),
              ),
              Expanded(
                child: GjaTheme.density(
                  density: GjaDensity.compact,
                  child: _DensityColumn(
                    label: 'Compacta',
                    targetKey: GjaThemePage.compactKey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Coluna com um elemento interativo que mostra o alvo da densidade ativa.
class _DensityColumn extends StatelessWidget {
  const _DensityColumn({required this.label, required this.targetKey});

  final String label;
  final Key targetKey;

  @override
  Widget build(BuildContext context) {
    final t = GjaTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.typography.header3),
        SizedBox(height: t.spacing.s),
        Text('Alvo mínimo: ${t.density.minTargetSize.round()}'),
        SizedBox(height: t.spacing.s),
        _Button(key: targetKey, label: 'Ação', onPressed: () {}),
      ],
    );
  }
}

/// Botão provisório da galeria, com as cores da família `standard`.
class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = GjaTheme.of(context);
    return GjaInteractable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, states) {
        final c = GjaControlColors.of(
          GjaControlFamily.standard,
          t.colors,
        ).resolve(states);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.m,
            vertical: t.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: c.background,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(t.radius.button),
          ),
          child: Text(label, style: t.typography.base.copyWith(color: c.text)),
        );
      },
    );
  }
}
