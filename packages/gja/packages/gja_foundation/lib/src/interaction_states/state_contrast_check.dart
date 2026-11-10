import '../color/color_tokens.dart';
import '../color/contrast.dart';
import '../color/contrast_check.dart';
import 'control_colors.dart';

/// Verifica o contraste das famílias de controle derivadas de [colors].
///
/// Para cada família e estado (o desabilitado é isento), o texto precisa de
/// ≥ 4,5:1 sobre o fundo do estado; fundo transparente é avaliado sobre
/// `base` e `background`. A borda do normal de `standard` precisa de ≥ 3:1
/// sobre `base`. Retorna os pares abaixo do mínimo; lista vazia significa
/// conformidade.
List<GjaContrastIssue> gjaCheckStateContrast(GjaColorTokens colors) {
  final issues = <GjaContrastIssue>[];
  for (final family in GjaControlFamily.values) {
    final controls = GjaControlColors.of(family, colors);
    for (final MapEntry(key: state, value: c) in controls.states.entries) {
      final grounds = c.background.a == 0
          ? {'base': colors.base, 'background': colors.background}
          : {'$state.background': c.background};
      for (final MapEntry(key: groundName, value: ground) in grounds.entries) {
        final ratio = gjaContrastRatioOver(c.text, ground);
        if (ratio < gjaTextContrastMinimum) {
          issues.add((
            foreground: '${family.name}.$state.text',
            background: '${family.name}.$groundName',
            ratio: ratio,
            minimum: gjaTextContrastMinimum,
          ));
        }
      }
    }
  }
  final border = GjaControlColors.of(
    GjaControlFamily.standard,
    colors,
  ).normal.border;
  final borderRatio = gjaContrastRatioOver(border, colors.base);
  if (borderRatio < gjaNonTextContrastMinimum) {
    issues.add((
      foreground: 'standard.normal.border',
      background: 'base',
      ratio: borderRatio,
      minimum: gjaNonTextContrastMinimum,
    ));
  }
  return issues;
}
