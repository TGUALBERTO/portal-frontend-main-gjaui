import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:gjamobile/src/features/auth/domain/entities/logos.dart';

/// Caminhão que atravessa a tela da esquerda para a direita em loop,
/// reaparecendo à esquerda assim que sai completamente pela direita.
class DrivingTruck extends StatefulWidget {
  const DrivingTruck({super.key});

  /// Altura da faixa que o caminhão percorre. Quem o posiciona reserva essa
  /// faixa, para o conteúdo não passar por baixo dele.
  static const double height = 110;

  @override
  State<DrivingTruck> createState() => _DrivingTruckState();
}

class _DrivingTruckState extends State<DrivingTruck>
    with SingleTickerProviderStateMixin {
  static const double _truckWidth = 220;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  late Logos _empresa =
      Logos.values[math.Random().nextInt(Logos.values.length)];

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener(_onStatusChanged)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Troca a empresa exatamente quando o caminhão termina de sair da tela,
  // antes de reiniciar a volta pela esquerda (troca fica invisível).
  void _onStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    setState(() => _empresa = _nextEmpresa());
    _controller.forward(from: 0);
  }

  Logos _nextEmpresa() {
    final candidates = Logos.values.where((l) => l != _empresa).toList();
    return candidates[math.Random().nextInt(candidates.length)];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final travelDistance = screenWidth + _truckWidth;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = -_truckWidth + _controller.value * travelDistance;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: SizedBox(
        width: _truckWidth,
        height: DrivingTruck.height,
        child: SpinningTruck(empresa: _empresa),
      ),
    );
  }
}

class SpinningTruck extends StatefulWidget {
  const SpinningTruck({super.key, required this.empresa});

  final Logos empresa;

  @override
  State<SpinningTruck> createState() => _SpinningTruckState();
}

class _SpinningTruckState extends State<SpinningTruck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  ui.Image? _logoImage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLogoImage(widget.empresa.path);
  }

  @override
  void didUpdateWidget(covariant SpinningTruck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.empresa != oldWidget.empresa) {
      _loadLogoImage(widget.empresa.path);
    }
  }

  Future<void> _loadLogoImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _logoImage = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: TruckPainter(
            empresa: widget.empresa,
            logoImage: _logoImage,
            wheelRotation: _controller.value * 2 * math.pi,
            bodyOffset: math.sin(_controller.value * 2 * math.pi) * 3,
            smokePhase: _controller.value,
          ),
        );
      },
    );
  }
}

class TruckPainter extends CustomPainter {
  TruckPainter({
    this.wheelRotation = 0,
    this.bodyOffset = 0,
    this.smokePhase = 0,
    required this.empresa,
    this.logoImage,
  });

  final double wheelRotation;
  final double bodyOffset;
  final double smokePhase;
  final Logos empresa;
  final ui.Image? logoImage;

  @override
  void paint(Canvas canvas, Size size) {
    final cargoPaint = Paint()..color = empresa.bg;
    final cabPaint = Paint()..color = Colors.red.shade700;
    final windowPaint = Paint()..color = Colors.lightBlue.shade100;
    final wheelPaint = Paint()..color = Colors.black87;
    final hubcapPaint = Paint()..color = Colors.grey.shade400;
    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final baseY = size.height * 0.78;
    final wheelRadius = size.height * 0.16;

    canvas.save();
    canvas.translate(0, bodyOffset);

    final cargoRect = Rect.fromLTWH(
      0,
      size.height * 0.15,
      size.width * 0.58,
      baseY - size.height * 0.15,
    );
    canvas.drawRect(cargoRect, cargoPaint);
    canvas.drawRect(cargoRect, outlinePaint);

    final logo = logoImage;
    if (logo != null) {
      final padding = cargoRect.shortestSide * 0.12;
      final destRect = Rect.fromLTWH(
        cargoRect.left + padding,
        cargoRect.top + padding,
        cargoRect.width - padding * 2,
        cargoRect.height - padding * 2,
      );
      final srcRect = Rect.fromLTWH(
        0,
        0,
        logo.width.toDouble(),
        logo.height.toDouble(),
      );
      final imageAspect = logo.width / logo.height;
      final destAspect = destRect.width / destRect.height;
      final fittedRect = imageAspect > destAspect
          ? Rect.fromLTWH(
              destRect.left,
              destRect.top + (destRect.height - destRect.width / imageAspect) / 2,
              destRect.width,
              destRect.width / imageAspect,
            )
          : Rect.fromLTWH(
              destRect.left + (destRect.width - destRect.height * imageAspect) / 2,
              destRect.top,
              destRect.height * imageAspect,
              destRect.height,
            );
      canvas.drawImageRect(logo, srcRect, fittedRect, Paint());
    }

    final cabLeft = size.width * 0.58;
    final cabWidth = size.width * 0.3;
    final cabPath = Path()
      ..moveTo(cabLeft, baseY)
      ..lineTo(cabLeft, size.height * 0.22)
      ..lineTo(cabLeft + cabWidth * 0.65, size.height * 0.22)
      ..lineTo(cabLeft + cabWidth, size.height * 0.45)
      ..lineTo(cabLeft + cabWidth, baseY)
      ..close();
    canvas.drawPath(cabPath, cabPaint);
    canvas.drawPath(cabPath, outlinePaint);

    final windowPath = Path()
      ..moveTo(cabLeft + cabWidth * 0.88, size.height * 0.45)
      ..lineTo(cabLeft + cabWidth * 0.6, size.height * 0.28)
      ..lineTo(cabLeft + cabWidth * 0.1, size.height * 0.28)
      ..lineTo(cabLeft + cabWidth * 0.1, size.height * 0.45)
      ..close();
    canvas.drawPath(windowPath, windowPaint);
    canvas.drawPath(windowPath, outlinePaint);

    final pipeHeight = size.height * 0.035;
    final pipeLength = size.width * 0.05;
    final pipeY = baseY - size.height * 0.055;
    final pipeRect = Rect.fromLTWH(
      -pipeLength * 0.6,
      pipeY,
      pipeLength,
      pipeHeight,
    );
    final pipePaint = Paint()..color = Colors.grey.shade800;
    canvas.drawRect(pipeRect, pipePaint);
    canvas.drawRect(pipeRect, outlinePaint);

    canvas.restore();

    final spokePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const spokeCount = 5;
    final hubcapRadius = wheelRadius * 0.45;

    final rearWheelX = size.width * 0.16;
    final frontWheelX = cabLeft + cabWidth * 0.40;
    for (final wheelX in [rearWheelX, frontWheelX]) {
      canvas.drawCircle(Offset(wheelX, baseY), wheelRadius, wheelPaint);

      canvas.save();
      canvas.translate(wheelX, baseY);
      canvas.rotate(wheelRotation);
      canvas.drawCircle(Offset.zero, hubcapRadius, hubcapPaint);
      for (var i = 0; i < spokeCount; i++) {
        final angle = i * (2 * math.pi / spokeCount);
        final spokeEnd = Offset(
          math.cos(angle) * hubcapRadius,
          math.sin(angle) * hubcapRadius,
        );
        canvas.drawLine(Offset.zero, spokeEnd, spokePaint);
      }
      canvas.restore();
    }

    const puffCount = 3;
    final pipeTipX = pipeRect.left;
    final pipeTipY = pipeRect.top + pipeRect.height / 2;
    final driftDistance = size.width * 0.22;
    final riseDistance = size.height * 0.12;
    for (var i = 0; i < puffCount; i++) {
      final phase = (smokePhase + i / puffCount) % 1.0;
      final puffRadius = size.width * (0.02 + phase * 0.05);
      final puffX = pipeTipX - phase * driftDistance;
      final puffY = pipeTipY -
          phase * riseDistance +
          math.sin(phase * math.pi * 2) * size.height * 0.02;
      final smokePaint = Paint()
        ..color = Colors.grey.withValues(alpha: (1 - phase) * 0.55);
      canvas.drawCircle(Offset(puffX, puffY), puffRadius, smokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TruckPainter oldDelegate) =>
      oldDelegate.wheelRotation != wheelRotation ||
      oldDelegate.bodyOffset != bodyOffset ||
      oldDelegate.smokePhase != smokePhase ||
      oldDelegate.logoImage != logoImage;
}
