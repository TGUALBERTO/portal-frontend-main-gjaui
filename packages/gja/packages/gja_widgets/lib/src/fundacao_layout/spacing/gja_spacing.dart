import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Passo ou papel de espaçamento, com os nomes de `GjaSpacingTokens`.
enum GjaSpace {
  /// Sem espaço.
  none,

  /// Menor passo.
  xxs,

  /// Passo muito pequeno.
  xs,

  /// Passo pequeno.
  s,

  /// Passo médio.
  m,

  /// Passo grande.
  l,

  /// Passo muito grande.
  xl,

  /// Passo extragrande.
  xxl,

  /// Maior passo.
  xxxl,

  /// Entre elementos lado a lado, como ícone e rótulo.
  inlineGap,

  /// Entre itens empilhados de um mesmo grupo.
  stackGap,

  /// Entre seções de uma página.
  sectionGap,

  /// Borda do conteúdo da página.
  pageMargin,
}

/// Espaço nomeado do GJA, como as classes de margem e padding do SAPUI5
/// (`sapUiSmallMargin` e afins).
///
/// O valor de cada [GjaSpace] vem do `spacing` do tema ativo e muda com a
/// densidade. Três formas:
///
/// ```dart
/// Row(children: [
///   const GjaIcon(GjaIcons.information),
///   const GjaSpacing.horizontal(GjaSpace.inlineGap),
///   const GjaText('Detalhes'),
/// ])
///
/// const GjaSpacing.vertical(GjaSpace.sectionGap)
///
/// const GjaSpacing.padding(
///   all: GjaSpace.m,
///   start: GjaSpace.xl,
///   child: GjaText('Conteúdo'),
/// )
/// ```
class GjaSpacing extends StatelessWidget {
  /// Espaço vazio com a largura de [space] e altura zero, para separar itens
  /// lado a lado.
  const GjaSpacing.horizontal(GjaSpace this.space, {super.key})
    : _axis = Axis.horizontal,
      child = null,
      all = null,
      horizontal = null,
      vertical = null,
      start = null,
      end = null,
      top = null,
      bottom = null;

  /// Espaço vazio com a altura de [space] e largura zero, para separar itens
  /// empilhados.
  const GjaSpacing.vertical(GjaSpace this.space, {super.key})
    : _axis = Axis.vertical,
      child = null,
      all = null,
      horizontal = null,
      vertical = null,
      start = null,
      end = null,
      top = null,
      bottom = null;

  /// Espaço em volta de [child].
  ///
  /// Cada lado usa o valor mais específico informado: [start], [end], [top]
  /// ou [bottom]; depois [horizontal] (início e fim) ou [vertical] (topo e
  /// base); por fim [all]. Sem valor, o lado fica sem espaço. [start] e [end]
  /// seguem a direção do texto.
  const GjaSpacing.padding({
    required Widget this.child,
    this.all,
    this.horizontal,
    this.vertical,
    this.start,
    this.end,
    this.top,
    this.bottom,
    super.key,
  }) : space = null,
       _axis = null;

  /// Espaço dos separadores; nulo em [GjaSpacing.padding].
  final GjaSpace? space;

  /// Filho envolvido por [GjaSpacing.padding]; nulo nos separadores.
  final Widget? child;

  /// Todos os lados.
  final GjaSpace? all;

  /// Início e fim.
  final GjaSpace? horizontal;

  /// Topo e base.
  final GjaSpace? vertical;

  /// Início, conforme a direção do texto.
  final GjaSpace? start;

  /// Fim, conforme a direção do texto.
  final GjaSpace? end;

  /// Topo.
  final GjaSpace? top;

  /// Base.
  final GjaSpace? bottom;

  final Axis? _axis;

  /// Valor de [space] em [spacing].
  static double resolve(GjaSpacingTokens spacing, GjaSpace space) =>
      switch (space) {
        GjaSpace.none => spacing.none,
        GjaSpace.xxs => spacing.xxs,
        GjaSpace.xs => spacing.xs,
        GjaSpace.s => spacing.s,
        GjaSpace.m => spacing.m,
        GjaSpace.l => spacing.l,
        GjaSpace.xl => spacing.xl,
        GjaSpace.xxl => spacing.xxl,
        GjaSpace.xxxl => spacing.xxxl,
        GjaSpace.inlineGap => spacing.inlineGap,
        GjaSpace.stackGap => spacing.stackGap,
        GjaSpace.sectionGap => spacing.sectionGap,
        GjaSpace.pageMargin => spacing.pageMargin,
      };

  @override
  Widget build(BuildContext context) {
    final spacing = GjaThemeData.of(context).spacing;
    double value(GjaSpace? side) =>
        side == null ? spacing.none : resolve(spacing, side);

    final axis = _axis;
    if (axis != null) {
      final v = value(space);
      return axis == Axis.horizontal ? SizedBox(width: v) : SizedBox(height: v);
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: value(start ?? horizontal ?? all),
        end: value(end ?? horizontal ?? all),
        top: value(top ?? vertical ?? all),
        bottom: value(bottom ?? vertical ?? all),
      ),
      child: child,
    );
  }
}
