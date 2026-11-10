import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "Espaçamentos": cada passo e papel de layout com seu valor.
///
/// Usa os próprios tokens de espaçamento nos paddings. Tamanhos de texto e a
/// escala da barra são literais provisórios até existir a tipografia; a
/// galeria é aplicação, fora da verificação de tokens.
class SpacingPage extends StatelessWidget {
  /// Cria a página.
  const SpacingPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Espaçamentos';

  /// Classes de tamanho exibidas na seção de margem de página, com o rótulo.
  static const marginClasses = <(String, GjaSizeClass)>[
    ('margem S', GjaSizeClass.small),
    ('margem M', GjaSizeClass.medium),
    ('margem L', GjaSizeClass.large),
    ('margem XL', GjaSizeClass.extraLarge),
  ];

  /// Rota nomeada.
  static const route = '/spacing';

  @override
  Widget build(BuildContext context) {
    final spacing = GjaThemeData.of(context).spacing;
    final colors = GjaThemeData.of(context).colors;
    final steps = <String, double>{
      'xxs': spacing.xxs,
      'xs': spacing.xs,
      's': spacing.s,
      'm': spacing.m,
      'l': spacing.l,
      'xl': spacing.xl,
      'xxl': spacing.xxl,
      'xxxl': spacing.xxxl,
    };
    final layout = <String, double>{
      'inlineGap': spacing.inlineGap,
      'stackGap': spacing.stackGap,
      'sectionGap': spacing.sectionGap,
      'pageMargin': spacing.pageMargin,
    };

    Widget row(String name, double value) => Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.xs),
      child: Row(
        children: [
          SizedBox(width: 112, child: Text(name)),
          SizedBox(width: 64, child: Text('${value.toStringAsFixed(0)} px')),
          Container(height: spacing.m, width: value * 4, color: colors.brand),
        ],
      ),
    );

    return ColoredBox(
      color: colors.base,
      child: ListView(
        padding: EdgeInsets.all(spacing.pageMargin),
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Semantics(button: true, child: const Text('← Voltar')),
          ),
          SizedBox(height: spacing.stackGap),
          const Text(title, style: TextStyle(fontSize: 24)),
          SizedBox(height: spacing.stackGap),
          const Text('Passos', style: TextStyle(fontSize: 20)),
          for (final MapEntry(key: name, value: value) in steps.entries)
            row(name, value),
          SizedBox(height: spacing.sectionGap),
          const Text('Papéis de layout', style: TextStyle(fontSize: 20)),
          for (final MapEntry(key: name, value: value) in layout.entries)
            row(name, value),
          SizedBox(height: spacing.sectionGap),
          const Text(
            'Margem de página por classe de tamanho',
            style: TextStyle(fontSize: 20),
          ),
          for (final (label, sizeClass) in marginClasses)
            row(label, spacing.pageMarginFor(sizeClass)),
        ],
      ),
    );
  }
}
