import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/lucide_font.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Fonte de ícones empacotada e licenciada — Fonte disponível na aplicação consumidora',
    () async {
      final data = await rootBundle.load(lucideAsset);
      // Assinatura TrueType (0x00010000) e tamanho plausível.
      expect(data.getUint32(0), 0x00010000);
      expect(data.lengthInBytes, greaterThan(500000));
      await loadLucideFont();
    },
  );
}
