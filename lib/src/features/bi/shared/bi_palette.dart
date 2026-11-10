import 'package:flutter/material.dart';
import 'package:gjamobile/src/extensions/context_extension.dart';
import 'package:gjamobile/src/theme/color_schemes.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Paleta determinística das séries/fatias dos gráficos do BI (ordem estável
/// para legenda e cores baterem sempre) e mapeamento dos tons semânticos
/// (`tom`/`severidade` que o backend envia) para cores do tema.
abstract final class BiPalette {
  BiPalette._();

  /// Cores das séries por índice (Incidentes/Requisições/Melhorias/Projetos/...).
  static const List<Color> _series = [
    FioriColors.blue6,
    Color(0xFF13B4A6), // teal
    Color(0xFF7A5AF8), // roxo
    FioriColors.mango6, // laranja
    FioriColors.mango5, // amarelo
    FioriColors.grey5,
    FioriColors.green6,
    FioriColors.red6,
  ];

  static Color serie(int i) => _series[i % _series.length];

  static List<Color> series(int n) =>
      List.generate(n, serie, growable: false);

  /// Rampa semáforo para faixas ordenadas do melhor (verde) ao pior (vermelho) —
  /// ex.: funil de aging (0–7 dias → >60 dias). [i] é a posição (0-based) e [n] o
  /// total de faixas; a rampa é reescalada para caber em qualquer [n].
  static const List<Color> _aging = [
    FioriColors.green6,
    Color(0xFF13B4A6), // teal
    FioriColors.blue6,
    FioriColors.mango5,
    FioriColors.mango6,
    FioriColors.red5,
  ];

  static Color aging(int i, int n) {
    if (n <= 1) return _aging.first;
    final idx = ((i * (_aging.length - 1)) / (n - 1)).round();
    return _aging[idx.clamp(0, _aging.length - 1)];
  }

  /// Cor do tom semântico de um KPI (neutral/success/warning/error/info).
  static Color tom(BuildContext context, String tom) => switch (tom) {
        'success' => context.appColors.success,
        'warning' => context.appColors.warning,
        'error' || 'critical' => context.colors.error,
        'info' => context.appColors.info,
        _ => context.colors.primary,
      };

  /// Cor de uma severidade de insight (info/warning/critical).
  static Color severidade(BuildContext context, String severidade) =>
      switch (severidade) {
        'critical' => context.colors.error,
        'warning' => context.appColors.warning,
        _ => context.appColors.info,
      };

  /// Ícone de uma severidade de insight.
  static IconData severidadeIcon(String severidade) => switch (severidade) {
        'critical' => GjaIcons.error,
        'warning' => GjaIcons.warning,
        _ => GjaIcons.lightbulb,
      };
}
