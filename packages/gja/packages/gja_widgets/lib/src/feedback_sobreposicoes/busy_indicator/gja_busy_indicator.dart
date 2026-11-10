import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Indicador de operação em andamento, como o `sap.m.BusyIndicator` e o
/// estado `busy` dos controles do SAPUI5.
///
/// Sem [child], mostra três pontos que pulsam em sequência e, abaixo deles,
/// o [text] opcional. Com [child], mostra o conteúdo e, enquanto [busy],
/// esmaece o conteúdo, bloqueia os toques, o foco e a semântica dele e põe
/// os pontos no centro. Com movimento reduzido, os pontos ficam parados.
///
/// É anunciado como região viva, com [text] ou o texto `loading` de
/// `GjaLocalizations`. Para progresso medível, use
/// `GjaProgressIndicator`.
///
/// ```dart
/// GjaBusyIndicator(
///   busy: carregando,
///   child: ListaDePedidos(),
/// )
/// ```
class GjaBusyIndicator extends StatelessWidget {
  /// Cria o indicador, sozinho ou sobre [child].
  const GjaBusyIndicator({
    this.text,
    this.busy = true,
    this.child,
    super.key,
  });

  /// Texto abaixo dos pontos, também anunciado pelo leitor de tela.
  final String? text;

  /// Se o indicador aparece; sobre [child], se o conteúdo fica bloqueado.
  final bool busy;

  /// Conteúdo coberto pelo indicador enquanto [busy].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final text = this.text;
    final indicator = Semantics(
      liveRegion: true,
      label: text ?? GjaLocalizations.of(context).loading,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.spacing.s,
          children: [
            const _Dots(),
            if (text != null)
              Text(
                text,
                textAlign: TextAlign.center,
                style: theme.typography.base.copyWith(color: theme.colors.text),
              ),
          ],
        ),
      ),
    );
    final child = this.child;
    if (child == null) return busy ? indicator : const SizedBox.shrink();
    if (!busy) return child;
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: ExcludeFocus(
            child: IgnorePointer(
              child: Opacity(
                opacity: theme.interaction.disabledOpacity,
                child: child,
              ),
            ),
          ),
        ),
        indicator,
      ],
    );
  }
}

/// Os três pontos, que pulsam em sequência.
class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cycle = GjaThemeData.of(context).motion.long * 4;
    if (cycle == Duration.zero) {
      _controller.stop();
      _controller.value = 0;
    } else if (_controller.duration != cycle || !_controller.isAnimating) {
      _controller.duration = cycle;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final animated = theme.motion.long != Duration.zero;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.spacing.xs,
        children: [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (context) {
                // Onda de 0 a 1 deslocada em um terço do ciclo por ponto.
                final phase = (_controller.value - i / 3) % 1;
                final wave = animated
                    ? (math.sin(phase * 2 * math.pi) + 1) / 2
                    : 1.0;
                return Opacity(
                  opacity: 0.4 + 0.6 * wave,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * wave,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: theme.spacing.s),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
