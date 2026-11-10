import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Desenho de um [GjaToolbar], como o `sap.m.ToolbarDesign`.
enum GjaToolbarDesign {
  /// Sem fundo próprio.
  transparent,

  /// Fundo `colors.base` (`sapToolbar_Background`).
  solid,

  /// Barra de informação, com o fundo do estado `information`
  /// (`sapInfobar_Background`).
  info,
}

/// Estilo de um [GjaToolbar], como o `sap.m.ToolbarStyle`.
enum GjaToolbarStyle {
  /// Com borda inferior fina.
  standard,

  /// Sem borda.
  clear,
}

/// Barra de ferramentas, como o `sap.m.Toolbar` do SAPUI5.
///
/// Põe os itens de [content] lado a lado, centralizados na altura de barra
/// (`density.barHeight`), com `spacing.xs` entre eles. Um `Spacer` ocupa o
/// espaço livre, como o `ToolbarSpacer` do UI5, e `GjaSeparator.vertical`
/// separa grupos, como o `ToolbarSeparator`. Itens que não cabem são
/// cortados na borda final.
///
/// Com [onPress], a barra inteira é acionável, como o `active` do UI5 (por
/// exemplo, uma barra de informação de filtros); com [enabled] `false`, não
/// é acionada.
///
/// ```dart
/// GjaToolbar(
///   content: [
///     const GjaTitle('Pedidos (12)', titleStyle: GjaTitleLevel.h5),
///     const Spacer(),
///     GjaButton(icon: GjaIcons.add, tooltip: 'Novo', onPress: novo),
///   ],
/// )
/// ```
class GjaToolbar extends StatelessWidget {
  /// Cria a barra com [content].
  const GjaToolbar({
    required this.content,
    this.design = GjaToolbarDesign.transparent,
    this.style = GjaToolbarStyle.standard,
    this.onPress,
    this.enabled = true,
    this.semanticLabel,
    super.key,
  });

  /// Itens, na ordem visual.
  final List<Widget> content;

  /// Desenho, que define o fundo.
  final GjaToolbarDesign design;

  /// Estilo, que define a borda inferior.
  final GjaToolbarStyle style;

  /// Ação da barra inteira, como o evento `press` do UI5; nula deixa a barra
  /// não acionável.
  final VoidCallback? onPress;

  /// Se a barra acionável pode ser acionada.
  final bool enabled;

  /// Nome da barra para o leitor de tela.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    final base = switch (design) {
      GjaToolbarDesign.transparent => null,
      GjaToolbarDesign.solid => colors.base,
      GjaToolbarDesign.info =>
        colors.stateColors(GjaValueState.information).background,
    };
    final border = style == GjaToolbarStyle.standard
        ? Border(
            bottom: BorderSide(
              color: colors.separator,
              width: const BorderSide().width,
            ),
          )
        : null;

    Widget bar(Color? background) => DecoratedBox(
      decoration: BoxDecoration(color: background, border: border),
      child: SizedBox(
        height: theme.density.barHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
          child: _ToolbarRow(
            gap: theme.spacing.xs,
            textDirection: Directionality.of(context),
            children: [
              for (final item in content)
                if (item is Spacer)
                  _ToolbarFlex(flex: item.flex, child: const SizedBox.shrink())
                else
                  item,
            ],
          ),
        ),
      ),
    );

    final onPress = this.onPress;
    if (onPress == null) {
      return Semantics(container: true, label: semanticLabel, child: bar(base));
    }
    return MergeSemantics(
      child: GjaInteractable(
        semanticLabel: semanticLabel,
        onPressed: enabled ? onPress : null,
        focusRingBorderRadius: BorderRadius.zero,
        builder: (context, states) {
          final active =
              states.contains(GjaInteractionState.hovered) ||
              states.contains(GjaInteractionState.pressed);
          return Opacity(
            opacity: theme.interaction.opacity(states),
            child: bar(active ? colors.hoverBackground : base),
          );
        },
      ),
    );
  }
}

/// Item flexível da barra (um `Spacer`).
class _ToolbarFlex extends ParentDataWidget<_ToolbarParentData> {
  const _ToolbarFlex({required this.flex, required super.child});

  final int flex;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _ToolbarParentData;
    if (data.flex != flex) {
      data.flex = flex;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _ToolbarRow;
}

class _ToolbarParentData extends ContainerBoxParentData<RenderBox> {
  int flex = 0;
}

/// Linha da barra: os itens fixos no tamanho natural, os flexíveis com o
/// espaço livre, e o que não cabe cortado na borda final, sem estouro.
class _ToolbarRow extends MultiChildRenderObjectWidget {
  const _ToolbarRow({
    required this.gap,
    required this.textDirection,
    required super.children,
  });

  final double gap;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderToolbarRow(gap: gap, textDirection: textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderToolbarRow renderObject,
  ) {
    renderObject
      ..gap = gap
      ..textDirection = textDirection;
  }
}

class _RenderToolbarRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ToolbarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ToolbarParentData> {
  _RenderToolbarRow({required double gap, required TextDirection textDirection})
    : _gap = gap,
      _textDirection = textDirection;

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool _clipped = false;
  final _clip = LayerHandle<ClipRectLayer>();

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ToolbarParentData) {
      child.parentData = _ToolbarParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    var total = 0.0;
    var count = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      total += child.getMaxIntrinsicWidth(height);
      count++;
    }
    return total + _gap * math.max(count - 1, 0);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    var height = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      height = math.max(height, child.getMinIntrinsicHeight(double.infinity));
    }
    return height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final maxHeight = constraints.maxHeight;
    final childConstraints = BoxConstraints(
      maxHeight: maxHeight.isFinite ? maxHeight : double.infinity,
    );
    var fixed = 0.0;
    var flexTotal = 0;
    var count = 0;
    var tallest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      count++;
      final data = child.parentData! as _ToolbarParentData;
      if (data.flex > 0) {
        flexTotal += data.flex;
        continue;
      }
      child.layout(childConstraints, parentUsesSize: true);
      fixed += child.size.width;
      tallest = math.max(tallest, child.size.height);
    }
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : fixed + _gap * math.max(count - 1, 0);
    final free = width - fixed - _gap * math.max(count - 1, 0);
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final data = child.parentData! as _ToolbarParentData;
      if (data.flex == 0) continue;
      final share = free > 0 && flexTotal > 0
          ? free * data.flex / flexTotal
          : 0.0;
      child.layout(
        BoxConstraints.tightFor(width: share, height: 0),
        parentUsesSize: true,
      );
    }
    final height = maxHeight.isFinite
        ? maxHeight
        : constraints.constrainHeight(tallest);
    size = constraints.constrain(Size(width, height));

    var x = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final data = child.parentData! as _ToolbarParentData;
      final w = child.size.width;
      final left = _textDirection == TextDirection.ltr ? x : size.width - x - w;
      data.offset = Offset(left, (size.height - child.size.height) / 2);
      x += w + _gap;
    }
    _clipped = x - _gap > size.width;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_clipped) {
      _clip.layer = null;
      defaultPaint(context, offset);
      return;
    }
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      oldLayer: _clip.layer,
    );
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}
