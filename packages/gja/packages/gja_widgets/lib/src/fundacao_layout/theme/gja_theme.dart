import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Aplica um tema do GJA a uma subárvore.
///
/// Publica [data] para os widgets e para o núcleo (lido com
/// [GjaTheme.of]), anima a troca de tema e define o estilo de texto padrão
/// (`base` com a cor `text`) e o ícone padrão (cor `text`, tamanho `control`).
/// Não pinta nada e não é interativo.
///
/// Use [GjaTheme.density] para trocar só a densidade de uma subárvore, como
/// o `sapUiSizeCompact` do SAPUI5:
///
/// ```dart
/// GjaTheme(
///   data: GjaThemeData.light(),
///   child: Row(children: [
///     const Expanded(child: Formulario()),
///     const Expanded(
///       child: GjaTheme.density(density: GjaDensity.compact, child: Tabela()),
///     ),
///   ]),
/// )
/// ```
class GjaTheme extends StatelessWidget {
  /// Aplica [data] à subárvore [child].
  ///
  /// Uma troca de [data] é animada durante [duration] (por padrão, a duração
  /// `medium` do movimento de [data]), com a curva `standard`. Com movimento
  /// reduzido, pelo `animationMode` de [data] ou pelo sistema, a troca é
  /// imediata.
  const GjaTheme({
    required GjaThemeData this.data,
    required this.child,
    this.duration,
    super.key,
  }) : density = null;

  /// Aplica à subárvore [child] o tema do ancestral com a densidade
  /// [density], preservando os demais valores.
  const GjaTheme.density({
    required GjaDensity this.density,
    required this.child,
    super.key,
  }) : data = null,
       duration = null;

  /// Tema aplicado, ou nulo em [GjaTheme.density].
  final GjaThemeData? data;

  /// Densidade aplicada em [GjaTheme.density], ou nula.
  final GjaDensity? density;

  /// Duração da troca de tema, ou nula para a duração `medium` do tema.
  final Duration? duration;

  /// Subárvore que recebe o tema.
  final Widget child;

  /// Tema ativo de [context]; equivale a `GjaThemeData.of`.
  static GjaThemeData of(BuildContext context) => GjaThemeData.of(context);

  @override
  Widget build(BuildContext context) {
    final target = data ?? GjaThemeData.of(context).withDensity(density!);
    // Modo efetivo: o do tema novo ou, com o pedido do sistema, `none`.
    final reduce = target.animationMode
        .effective(
          disableAnimations:
              MediaQuery.maybeDisableAnimationsOf(context) ?? false,
        )
        .reducesMotion;
    return _AnimatedGjaTheme(
      data: target,
      duration: reduce ? Duration.zero : duration ?? target.motion.medium,
      curve: target.motion.standard,
      child: child,
    );
  }
}

class _AnimatedGjaTheme extends ImplicitlyAnimatedWidget {
  const _AnimatedGjaTheme({
    required this.data,
    required this.child,
    required super.duration,
    super.curve,
  });

  final GjaThemeData data;
  final Widget child;

  @override
  AnimatedWidgetBaseState<_AnimatedGjaTheme> createState() =>
      _AnimatedGjaThemeState();
}

class _AnimatedGjaThemeState
    extends AnimatedWidgetBaseState<_AnimatedGjaTheme> {
  _GjaThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data =
        visitor(
              _data,
              widget.data,
              (value) => _GjaThemeDataTween(begin: value as GjaThemeData),
            )
            as _GjaThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _data!.evaluate(animation);
    return GjaThemeScope(
      data: theme,
      child: DefaultTextStyle.merge(
        style: theme.typography.base.copyWith(color: theme.colors.text),
        child: IconTheme.merge(
          data: IconThemeData(
            color: theme.colors.text,
            size: theme.icons.control,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _GjaThemeDataTween extends Tween<GjaThemeData> {
  _GjaThemeDataTween({super.begin});

  @override
  GjaThemeData lerp(double t) => begin!.lerp(end, t);
}
