import 'package:flutter/services.dart';

/// Arquivos da Inter empacotada em `gja_foundation`, como a aplicação os vê.
const interAssets = [
  'packages/gja_foundation/fonts/inter/Inter-Regular.ttf',
  'packages/gja_foundation/fonts/inter/Inter-Medium.ttf',
  'packages/gja_foundation/fonts/inter/Inter-SemiBold.ttf',
  'packages/gja_foundation/fonts/inter/Inter-Bold.ttf',
];

/// Registra a Inter no motor de testes, que por padrão só usa a fonte Ahem.
Future<void> loadInterFont() async {
  final loader = FontLoader('packages/gja_foundation/Inter');
  for (final asset in interAssets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
