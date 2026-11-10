import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Envolve [child] com confete de carnaval caindo, ativo apenas em fevereiro
/// (clima de carnaval). Fora de fevereiro, retorna [child] sem overlay.
class SeasonalConfetti extends StatefulWidget {
  const SeasonalConfetti({super.key, required this.child});

  final Widget child;

  static bool get _isFebruary => DateTime.now().month == 2;

  @override
  State<SeasonalConfetti> createState() => _SeasonalConfettiState();
}

class _SeasonalConfettiState extends State<SeasonalConfetti> {
  ConfettiController? _controller;

  @override
  void initState() {
    super.initState();
    if (SeasonalConfetti._isFebruary) {
      _controller = ConfettiController(duration: const Duration(seconds: 1))
        ..play();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: controller,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                numberOfParticles: 5,
                emissionFrequency: 0.04,
                gravity: 0.15,
                colors: const [
                  Colors.green,
                  Colors.amber,
                  Colors.purple,
                  Colors.blue,
                  Colors.pink,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: controller,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                numberOfParticles: 15,
                emissionFrequency: 0.04,
                gravity: 0.15,
                colors: const [
                  Colors.green,
                  Colors.amber,
                  Colors.purple,
                  Colors.blue,
                  Colors.pink,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: controller,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                numberOfParticles: 15,
                emissionFrequency: 0.04,
                gravity: 0.15,
                colors: const [
                  Colors.green,
                  Colors.amber,
                  Colors.purple,
                  Colors.blue,
                  Colors.pink,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
