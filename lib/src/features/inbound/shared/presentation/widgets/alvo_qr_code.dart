import 'dart:math' as math;

import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Alvo de leitura: cartão com moldura tracejada e o ícone de QR Code no
/// centro.
///
/// É só um cartaz — quem abre a câmera é o botão. Existe para dar ao conferente
/// um ponto de referência do que a tela espera antes de ele apertar qualquer
/// coisa.
///
/// O lado sai da **largura disponível**, não de um número fixo: espaçamentos
/// (`.r`), altura de botão (`.h`) e fonte (`.sp`) já crescem com o `ScreenUtil`,
/// então um quadrado de tamanho fixo encolhe em relação ao resto num coletor de
/// densidade baixa (540 dp de largura, por exemplo) — era metade da coluna onde
/// o design pede ~2/3.
class AlvoQrCode extends StatelessWidget {
  const AlvoQrCode({super.key});

  /// 240 de 328 dp de coluna no design de 360 dp.
  static const double _fracaoDaLargura = 0.72;

  /// Piso para o coletor pequeno e teto para tablet/coluna larga — passando
  /// disso o alvo vira um cartaz maior que o conteúdo que ele anuncia.
  static const double _ladoMinimo = 140;
  static const double _ladoMaximo = 200;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura =
            constraints.maxWidth.isFinite ? constraints.maxWidth : _ladoMaximo;
        var lado =
            (largura * _fracaoDaLargura).clamp(_ladoMinimo, _ladoMaximo);
        // Em contexto de altura limitada (paisagem) o quadrado se rende à
        // altura, senão empurra campo e botões para fora da dobra.
        if (constraints.maxHeight.isFinite) {
          lado = math.min(lado, constraints.maxHeight);
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: lado),
            child: AspectRatio(
              aspectRatio: 1,
              child: Card(
                margin: EdgeInsets.zero,
                color: cs.primaryContainer,
                child: Padding(
                  // Proporcionais ao lado (20 e 72 de 240 no design) — com
                  // tokens fixos a moldura e o ícone desandam assim que o
                  // quadrado muda de tamanho.
                  padding: EdgeInsets.all(lado * 0.083),
                  child: MolduraTracejada(
                    color: cs.primary.withValues(alpha: 0.6),
                    child: Center(
                      child: Icon(
                        GjaIcons.qrCode,
                        size: lado * 0.30,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Moldura tracejada de 1 pt — o `border: 1px dashed` do design, que o Flutter
/// não tem nativamente.
class MolduraTracejada extends StatelessWidget {
  const MolduraTracejada({
    super.key,
    required this.child,
    required this.color,
    this.traco = 5,
    this.vao = 4,
    this.radius = 8,
  });

  final Widget child;
  final Color color;

  /// Comprimento do traço e do vão entre traços.
  final double traco;
  final double vao;

  /// Arredondamento dos cantos, para acompanhar o card que a envolve.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MolduraTracejadaPainter(
        color: color,
        traco: traco,
        vao: vao,
        radius: radius,
      ),
      child: child,
    );
  }
}

class _MolduraTracejadaPainter extends CustomPainter {
  const _MolduraTracejadaPainter({
    required this.color,
    required this.traco,
    required this.vao,
    required this.radius,
  });

  final Color color;
  final double traco;
  final double vao;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final contorno = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    // O tracejado é recortado do contorno com PathMetrics — assim os cantos
    // arredondados também ficam tracejados, e não só as retas.
    final passo = traco + vao;
    for (final metrica in contorno.computeMetrics()) {
      for (double d = 0; d < metrica.length; d += passo) {
        final ate = (d + traco).clamp(0.0, metrica.length);
        canvas.drawPath(metrica.extractPath(d, ate), pincel);
      }
    }
  }

  @override
  bool shouldRepaint(_MolduraTracejadaPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.traco != traco ||
      oldDelegate.vao != vao ||
      oldDelegate.radius != radius;
}
