import 'package:flutter/material.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';

/// Envolve [child] com um efeito de neve caindo, ativo de 1 a 27 de dezembro
/// (clima natalino; a partir do dia 28 entra [SeasonalFireworks], da virada
/// do ano). Fora dessa janela, retorna [child] sem nenhum overlay.
class SeasonalSnowfall extends StatelessWidget {
  const SeasonalSnowfall({super.key, required this.child});

  final Widget child;

  static bool get _isChristmasWindow {
    final now = DateTime.now();
    return now.month == 12 && now.day <= 27;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isChristmasWindow) return child;

    return Stack(
      children: [
        child,
        const Positioned.fill(
          child: IgnorePointer(
            child: SnowFallAnimation(
              config: SnowfallConfig(numberOfSnowflakes: 80, speed: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
