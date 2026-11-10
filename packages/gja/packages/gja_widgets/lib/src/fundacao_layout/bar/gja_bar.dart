import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Desenho de uma [GjaBar], como o `sap.m.BarDesign` do SAPUI5.
enum GjaBarDesign {
  /// O desenho da área de `GjaPage` em que a barra está; fora de uma
  /// página, [header].
  auto,

  /// Cabeçalho: com a sombra de cabeçalho.
  header,

  /// Subcabeçalho: só o fundo.
  subHeader,

  /// Rodapé: com uma borda no topo.
  footer,

  /// Rodapé flutuante: com borda em volta e cantos arredondados.
  floatingFooter,
}

/// Alinhamento do conteúdo central de uma [GjaBar] e do título de
/// `GjaPage`, como o `sap.m.TitleAlignment` do SAPUI5.
enum GjaTitleAlignment {
  /// Centrado na barra quando couber, como o padrão da `sap.m.Bar`.
  none,

  /// Logo depois do conteúdo do início.
  start,

  /// Centrado na barra quando couber.
  center,

  /// O do tema: no Horizon, [start].
  auto,
}

/// Barra horizontal de três áreas, como o `sap.m.Bar` do SAPUI5.
///
/// [contentLeft] fica no início, [contentRight] no fim e [contentMiddle]
/// entre eles, centrado ou logo depois do início conforme [titleAlignment].
/// Os conteúdos das pontas mantêm o tamanho; o central recebe o espaço que
/// sobra. O [design] define a borda e a sombra; com `auto`, vale o da área de
/// `GjaPage` em que a barra está. A altura é `density.barHeight`.
///
/// ```dart
/// GjaBar(
///   contentMiddle: const [GjaTitle('Pedido 4711')],
///   contentRight: [GjaButton(text: 'Salvar', onPress: save)],
/// )
/// ```
class GjaBar extends StatelessWidget {
  /// Cria a barra.
  const GjaBar({
    this.contentLeft = const [],
    this.contentMiddle = const [],
    this.contentRight = const [],
    this.design = GjaBarDesign.auto,
    this.titleAlignment = GjaTitleAlignment.none,
    super.key,
  });

  /// Conteúdo do início.
  final List<Widget> contentLeft;

  /// Conteúdo central.
  final List<Widget> contentMiddle;

  /// Conteúdo do fim.
  final List<Widget> contentRight;

  /// Desenho da barra.
  final GjaBarDesign design;

  /// Alinhamento do conteúdo central.
  final GjaTitleAlignment titleAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final resolved = design == GjaBarDesign.auto
        ? GjaBarScope.designOf(context)
        : design;
    final colors = theme.colors;
    final decoration = switch (resolved) {
      GjaBarDesign.header || GjaBarDesign.auto => BoxDecoration(
        color: colors.base,
        boxShadow: theme.shadows.boxShadows(
          theme.shadows.header,
          colors.shadow,
        ),
      ),
      GjaBarDesign.subHeader => BoxDecoration(color: colors.base),
      GjaBarDesign.footer => BoxDecoration(
        color: colors.base,
        border: Border(top: BorderSide(color: colors.separator)),
      ),
      GjaBarDesign.floatingFooter => BoxDecoration(
        color: colors.base,
        border: Border.all(color: colors.separator),
        borderRadius: BorderRadius.circular(theme.radius.s),
      ),
    };
    final gap = theme.spacing.xs;
    Widget group(List<Widget> children, {bool flexible = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        for (final child in children) flexible ? Flexible(child: child) : child,
      ],
    );
    final center = switch (titleAlignment) {
      GjaTitleAlignment.none || GjaTitleAlignment.center => true,
      GjaTitleAlignment.start || GjaTitleAlignment.auto => false,
    };
    return DecoratedBox(
      decoration: decoration,
      child: SizedBox(
        height: theme.density.barHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.s),
          child: CustomMultiChildLayout(
            delegate: _BarLayout(
              gap: gap,
              center: center,
              direction: Directionality.of(context),
            ),
            children: [
              if (contentLeft.isNotEmpty)
                LayoutId(id: _Slot.left, child: group(contentLeft)),
              if (contentMiddle.isNotEmpty)
                LayoutId(
                  id: _Slot.middle,
                  child: group(contentMiddle, flexible: true),
                ),
              if (contentRight.isNotEmpty)
                LayoutId(id: _Slot.right, child: group(contentRight)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Área de `GjaPage` em que uma [GjaBar] com desenho `auto` está.
///
/// Uso interno do framework: a página o coloca em volta do cabeçalho, do
/// subcabeçalho e do rodapé.
class GjaBarScope extends InheritedWidget {
  /// Define [design] para as barras automáticas de [child].
  const GjaBarScope({required this.design, required super.child, super.key});

  /// Desenho das barras automáticas da subárvore.
  final GjaBarDesign design;

  /// Desenho das barras automáticas em [context]; fora de uma área, `header`.
  static GjaBarDesign designOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GjaBarScope>()?.design ??
      GjaBarDesign.header;

  @override
  bool updateShouldNotify(GjaBarScope oldWidget) =>
      design != oldWidget.design;
}

enum _Slot { left, middle, right }

/// Dispõe as pontas com a largura própria e o meio com o espaço que sobra,
/// centrado na barra quando couber ou logo depois do início.
class _BarLayout extends MultiChildLayoutDelegate {
  _BarLayout({
    required this.gap,
    required this.center,
    required this.direction,
  });

  final double gap;
  final bool center;
  final TextDirection direction;

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints(maxHeight: size.height);
    final left = hasChild(_Slot.left)
        ? layoutChild(_Slot.left, loose)
        : Size.zero;
    final right = hasChild(_Slot.right)
        ? layoutChild(_Slot.right, loose)
        : Size.zero;
    final leftEnd = left.width == 0 ? 0.0 : left.width + gap;
    final rightStart = size.width - (right.width == 0 ? 0 : right.width + gap);

    double x(double start, double width) =>
        direction == TextDirection.ltr ? start : size.width - start - width;
    double y(Size child) => (size.height - child.height) / 2;

    if (hasChild(_Slot.left)) {
      positionChild(_Slot.left, Offset(x(0, left.width), y(left)));
    }
    if (hasChild(_Slot.right)) {
      positionChild(
        _Slot.right,
        Offset(x(size.width - right.width, right.width), y(right)),
      );
    }
    if (hasChild(_Slot.middle)) {
      final available = (rightStart - leftEnd).clamp(0.0, size.width);
      final middle = layoutChild(
        _Slot.middle,
        BoxConstraints(maxWidth: available, maxHeight: size.height),
      );
      var start = leftEnd;
      if (center) {
        final centered = (size.width - middle.width) / 2;
        // Centrado na barra só se não invadir as pontas.
        if (centered >= leftEnd && centered + middle.width <= rightStart) {
          start = centered;
        }
      }
      positionChild(_Slot.middle, Offset(x(start, middle.width), y(middle)));
    }
  }

  @override
  bool shouldRelayout(_BarLayout oldDelegate) =>
      gap != oldDelegate.gap ||
      center != oldDelegate.center ||
      direction != oldDelegate.direction;
}
