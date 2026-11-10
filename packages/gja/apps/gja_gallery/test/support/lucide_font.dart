import 'package:flutter/services.dart';

/// Fonte de ícones Lucide empacotada em `gja_foundation`, como a aplicação a vê.
const lucideAsset = 'packages/gja_foundation/fonts/lucide/lucide.ttf';

/// Registra a Lucide no motor de testes.
Future<void> loadLucideFont() async {
  final loader = FontLoader('packages/gja_foundation/Lucide')
    ..addFont(rootBundle.load(lucideAsset));
  await loader.load();
}
