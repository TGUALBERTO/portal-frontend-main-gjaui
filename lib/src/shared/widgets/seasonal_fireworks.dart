import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';

/// Envolve [child] com fogos de artifício de virada de ano, ativo de 28 de
/// dezembro a 3 de janeiro. Fora dessa janela, retorna [child] sem overlay.
class SeasonalFireworks extends StatefulWidget {
  const SeasonalFireworks({super.key, required this.child});

  final Widget child;

  static bool get _isNewYearWindow {
    final now = DateTime.now();
    return (now.month == 12 && now.day >= 28) ||
        (now.month == 1 && now.day <= 3);
  }

  @override
  State<SeasonalFireworks> createState() => _SeasonalFireworksState();
}

class _SeasonalFireworksState extends State<SeasonalFireworks> {
  FireworksController? _controller;
  Timer? _launchTimer;

  @override
  void initState() {
    super.initState();
    if (SeasonalFireworks._isNewYearWindow) {
      _controller = FireworksController();
      // O FireworksGame só fica pronto após o 1º frame (FireworksDisplay
      // atribui o controller.flameGame no initState dele, que roda no mesmo
      // frame); dispara o 1º estouro só depois disso.
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchBurst());
      _launchTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => _launchBurst(),
      );
    }
  }

  void _launchBurst() {
    _controller?.fireMultipleRockets(minRockets: 2, maxRockets: 4);
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: FireworksDisplay(controller: controller),
        ),
      ],
    );
  }
}
