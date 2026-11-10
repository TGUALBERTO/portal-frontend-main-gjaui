import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/theme/theme.dart';

void main() {
  // O rótulo do Chip usa o labelStyle do tema como está: sem cor explícita
  // sai preto, ilegível no dark mode (grupos do perfil, rotas do RH Processo).
  test('rótulo do chip usa onSurface nos dois modos', () {
    for (final tema in [
      buildLightTheme(primaryColorHex: '#de3438'),
      buildDarkTheme(primaryColorHex: '#de3438'),
    ]) {
      expect(tema.chipTheme.labelStyle?.color, tema.colorScheme.onSurface);
    }
  });
}
