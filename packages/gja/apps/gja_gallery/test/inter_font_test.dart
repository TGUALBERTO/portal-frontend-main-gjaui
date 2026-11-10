import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/inter_font.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Fonte empacotada e licenciada — Fonte disponível na aplicação consumidora',
    () async {
      for (final asset in interAssets) {
        final data = await rootBundle.load(asset);
        // Assinatura TrueType (0x00010000) e tamanho plausível.
        expect(data.getUint32(0), 0x00010000, reason: asset);
        expect(data.lengthInBytes, greaterThan(100000), reason: asset);
      }
      await loadInterFont();
    },
  );
}
