import 'package:flutter/services.dart';

/// Arquivos da Inter empacotada em `gja_foundation`, como os testes os veem.
const _interAssets = [
  'packages/gja_foundation/fonts/inter/Inter-Regular.ttf',
  'packages/gja_foundation/fonts/inter/Inter-Medium.ttf',
  'packages/gja_foundation/fonts/inter/Inter-SemiBold.ttf',
  'packages/gja_foundation/fonts/inter/Inter-Bold.ttf',
];

/// Fonte de ícones Lucide empacotada em `gja_foundation`.
const _lucideAsset = 'packages/gja_foundation/fonts/lucide/lucide.ttf';

bool _loaded = false;

/// Registra a Inter e a Lucide no motor de testes, que por padrão só usa a
/// fonte Ahem.
///
/// Necessário para goldens e para medidas reais de texto. Os nomes de família
/// são os mesmos que a tipografia e os ícones do GJA usam.
Future<void> loadGjaFonts() async {
  if (_loaded) return;
  final loader = FontLoader('packages/gja_foundation/Inter');
  for (final asset in _interAssets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
  final icons = FontLoader('packages/gja_foundation/Lucide')
    ..addFont(rootBundle.load(_lucideAsset));
  await icons.load();
  _loaded = true;
}
