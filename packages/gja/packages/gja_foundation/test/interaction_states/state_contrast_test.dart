import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';

void main() {
  test('Contraste de texto nos estados — Texto de todos os estados', () {
    for (final colors in const [
      GjaColorTokens.light(),
      GjaColorTokens.dark(),
    ]) {
      expect(gjaCheckStateContrast(colors), isEmpty);
    }
  });

  test('a verificação de estados detecta uma marca sem contraste', () {
    const light = GjaColorTokens.light();
    final broken = light.copyWith(contrastText: light.brand);
    final issues = gjaCheckStateContrast(broken);
    expect(issues.map((i) => i.foreground), contains('emphasized.normal.text'));
  });
}
