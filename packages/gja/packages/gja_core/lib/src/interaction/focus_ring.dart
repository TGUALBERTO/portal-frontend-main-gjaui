import 'package:flutter/widgets.dart';

/// Anel de foco desenhado em volta de [child], sem alterar o layout.
///
/// O anel é pintado fora dos limites do filho, afastado [offset] da borda e
/// com espessura [width]. Use a espessura, o afastamento e a cor `focus` dos
/// tokens (`GjaInteractionStateTokens` e `GjaColorTokens`).
class GjaFocusRing extends StatelessWidget {
  /// Cria o anel em volta de [child].
  const GjaFocusRing({
    required this.visible,
    required this.width,
    required this.offset,
    required this.color,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  /// Se o anel é desenhado.
  final bool visible;

  /// Espessura do traço, em pixels lógicos.
  final double width;

  /// Afastamento entre a borda do filho e o anel.
  final double offset;

  /// Cor do anel (normalmente o papel `focus`).
  final Color color;

  /// Raio dos cantos do filho; o anel acompanha a curva, somando [offset].
  final BorderRadius borderRadius;

  /// Conteúdo envolvido.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    return CustomPaint(
      foregroundPainter: GjaFocusRingPainter(
        width: width,
        offset: offset,
        color: color,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

/// Pintor do anel de foco, exposto para testes e widgets que precisem
/// desenhar o anel em outra camada.
class GjaFocusRingPainter extends CustomPainter {
  /// Cria o pintor.
  const GjaFocusRingPainter({
    required this.width,
    required this.offset,
    required this.color,
    required this.borderRadius,
  });

  /// Espessura do traço.
  final double width;

  /// Afastamento em relação à borda do filho.
  final double offset;

  /// Cor do traço.
  final Color color;

  /// Raio dos cantos do filho.
  final BorderRadius borderRadius;

  /// Retângulo do traço (centro da linha) para um filho de tamanho [size].
  RRect ringRect(Size size) {
    final grow = offset + width / 2;
    return borderRadius.toRRect(Offset.zero & size).inflate(grow);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    canvas.drawRRect(ringRect(size), paint);
  }

  @override
  bool shouldRepaint(GjaFocusRingPainter oldDelegate) =>
      oldDelegate.width != width ||
      oldDelegate.offset != offset ||
      oldDelegate.color != color ||
      oldDelegate.borderRadius != borderRadius;
}
