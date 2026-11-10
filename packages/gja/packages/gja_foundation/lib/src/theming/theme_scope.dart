import 'package:flutter/widgets.dart';

import 'theme_data.dart';

/// Publica um [GjaThemeData] para a subárvore.
///
/// Nível: semântico.
///
/// Escopo de baixo nível, lido por [GjaThemeData.of]. Aplicações usam o
/// widget `GjaTheme` de `gja_widgets`, que também anima a troca de tema,
/// troca a densidade por subárvore e define o texto e o ícone padrão.
class GjaThemeScope extends InheritedWidget {
  /// Publica [data] para [child].
  const GjaThemeScope({required this.data, required super.child, super.key});

  /// Tema publicado.
  final GjaThemeData data;

  @override
  bool updateShouldNotify(GjaThemeScope oldWidget) => data != oldWidget.data;
}
