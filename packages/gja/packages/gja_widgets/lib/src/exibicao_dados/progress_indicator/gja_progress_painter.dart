import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Pintura do `GjaProgressIndicator`, interna ao pacote (não exportada).
///
/// Desenha a trilha e o preenchimento da barra ou do círculo. Com [value], o
/// preenchimento é determinado; sem ele, [phase] (0 a 1) posiciona o segmento
/// ou o arco do ciclo indeterminado, e [phase] nulo dá o desenho estático do
/// movimento reduzido.
class GjaProgressPainter extends CustomPainter {
  /// Cria a pintura.
  const GjaProgressPainter({
    required this.circular,
    required this.value,
    required this.phase,
    required this.fill,
    required this.track,
    required this.thickness,
    required this.textDirection,
  });

  /// Se desenha o círculo; senão, a barra.
  final bool circular;

  /// Valor exibido (0 a 1), ou nulo no modo indeterminado.
  final double? value;

  /// Posição no ciclo indeterminado (0 a 1), ou nula quando parado.
  final double? phase;

  /// Cor do preenchimento.
  final Color fill;

  /// Cor da trilha.
  final Color track;

  /// Traço do círculo; a barra usa a própria altura.
  final double thickness;

  /// Direção do texto: a barra se preenche a partir do início.
  final TextDirection textDirection;

  /// Fração da barra (início e fim, de 0 a 1, na direção do texto) coberta
  /// pelo preenchimento.
  (double, double) get linearSegment {
    final value = this.value;
    if (value != null) return (0, value);
    final phase = this.phase;
    if (phase == null) return (1 / 3, 2 / 3);
    // Segmento de um terço que entra antes do início e sai depois do fim.
    final start = -1 / 3 + phase * 4 / 3;
    return (start.clamp(0, 1), (start + 1 / 3).clamp(0, 1));
  }

  /// Ângulos inicial e de varredura do arco do círculo, em radianos.
  (double, double) get circularArc {
    const top = -math.pi / 2;
    final value = this.value;
    if (value != null) return (top, value * 2 * math.pi);
    final phase = this.phase;
    if (phase == null) return (top, math.pi / 2);
    return (top + phase * 2 * math.pi, math.pi / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (circular) {
      _paintCircle(canvas, size);
    } else {
      _paintBar(canvas, size);
    }
  }

  void _paintBar(Canvas canvas, Size size) {
    final corner = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, corner),
      Paint()..color = track,
    );
    final (start, end) = linearSegment;
    if (end <= start) return;
    final rtl = textDirection == TextDirection.rtl;
    final left = (rtl ? 1 - end : start) * size.width;
    final right = (rtl ? 1 - start : end) * size.width;
    canvas.drawRRect(
      RRect.fromLTRBR(left, 0, right, size.height, corner),
      Paint()..color = fill,
    );
  }

  void _paintCircle(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(thickness / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawOval(rect, stroke..color = track);
    final (start, sweep) = circularArc;
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      stroke
        ..color = fill
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(GjaProgressPainter oldDelegate) =>
      circular != oldDelegate.circular ||
      value != oldDelegate.value ||
      phase != oldDelegate.phase ||
      fill != oldDelegate.fill ||
      track != oldDelegate.track ||
      thickness != oldDelegate.thickness ||
      textDirection != oldDelegate.textDirection;
}
