import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

import 'initial_focus.dart';

/// Posição da sobreposição ancorada em relação à âncora, como o `placement`
/// do Popover do SAPUI5 (`Bottom`, `Top`, `Start`, `End`).
///
/// A posição pedida é a preferida: sem espaço nela e com espaço na oposta, a
/// sobreposição vai para a oposta (como `PreferredBottomOrFlip` etc.).
enum GjaPlacement {
  /// Abaixo da âncora.
  bottom,

  /// Acima da âncora.
  top,

  /// No lado inicial da âncora (esquerda em LTR, direita em RTL).
  start,

  /// No lado final da âncora (direita em LTR, esquerda em RTL).
  end,
}

/// Alinhamento da sobreposição ao longo da âncora.
enum GjaOverlayAlignment {
  /// Alinhada ao início da âncora (borda inicial ou topo).
  start,

  /// Centralizada na âncora.
  center,

  /// Alinhada ao fim da âncora (borda final ou base).
  end,
}

/// Controla a abertura de uma [GjaAnchoredOverlay] e avisa as mudanças.
///
/// É um `OverlayPortalController` que notifica seus ouvintes em [show] e
/// [hide], para que a sobreposição guarde e devolva o foco.
class GjaAnchoredOverlayController extends OverlayPortalController
    with ChangeNotifier {
  /// Cria o controlador, fechado.
  GjaAnchoredOverlayController({super.debugLabel});

  @override
  void show() {
    if (isShowing) return;
    super.show();
    notifyListeners();
  }

  @override
  void hide() {
    if (!isShowing) return;
    super.hide();
    notifyListeners();
  }
}

/// Mostra um conteúdo junto de uma âncora, como o `Popover` do SAPUI5.
///
/// O conteúdo de [overlayBuilder] aparece na posição [placement] da âncora
/// [child], alinhado por [alignment] e afastado [gap]. Sem espaço na posição
/// preferida e com espaço na oposta, vai para a oposta; e fica sempre a pelo
/// menos [margin] das bordas da área da sobreposição. Acompanha a âncora
/// quando ela rola, se move ou muda de tamanho. O conteúdo lê a posição
/// efetiva com [placementOf].
///
/// Com [autoClose], fecha com um toque fora do conteúdo e da âncora, e com
/// Esc, chamando [onDismiss]. Com [focusOnShow], o foco vai para o conteúdo
/// ao abrir e volta para quem o tinha ao fechar.
///
/// [gap] e [margin] usam os espaçamentos `xs` e `s` do tema ativo
/// (`GjaThemeData.of`) quando omitidos.
class GjaAnchoredOverlay extends StatefulWidget {
  /// Cria a sobreposição ancorada.
  const GjaAnchoredOverlay({
    required this.controller,
    required this.overlayBuilder,
    required this.child,
    this.placement = GjaPlacement.bottom,
    this.alignment = GjaOverlayAlignment.start,
    this.gap,
    this.margin,
    this.autoClose = true,
    this.focusOnShow = true,
    this.onDismiss,
    super.key,
  });

  /// Abre e fecha a sobreposição.
  final GjaAnchoredOverlayController controller;

  /// Constrói o conteúdo da sobreposição.
  final WidgetBuilder overlayBuilder;

  /// A âncora.
  final Widget child;

  /// Posição preferida.
  final GjaPlacement placement;

  /// Alinhamento ao longo da âncora.
  final GjaOverlayAlignment alignment;

  /// Distância entre a âncora e o conteúdo.
  final double? gap;

  /// Distância mínima entre o conteúdo e as bordas da área da sobreposição.
  final double? margin;

  /// Se um toque fora e Esc fecham a sobreposição.
  final bool autoClose;

  /// Se o foco vai para o conteúdo ao abrir e volta ao fechar.
  final bool focusOnShow;

  /// Chamado quando a sobreposição é fechada por toque fora ou Esc.
  final VoidCallback? onDismiss;

  /// Posição efetiva da sobreposição ancorada que contém [context], depois
  /// da inversão, ou nulo fora de uma. Usada pelo conteúdo para, por exemplo,
  /// desenhar a seta do lado da âncora.
  static GjaPlacement? placementOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PlacementScope>()?.placement;

  @override
  State<GjaAnchoredOverlay> createState() => _GjaAnchoredOverlayState();
}

/// Publica a posição efetiva para o conteúdo da sobreposição.
class _PlacementScope extends InheritedWidget {
  const _PlacementScope({required this.placement, required super.child});

  final GjaPlacement placement;

  @override
  bool updateShouldNotify(_PlacementScope old) => old.placement != placement;
}

class _GjaAnchoredOverlayState extends State<GjaAnchoredOverlay> {
  final _anchorKey = GlobalKey();
  final List<ScrollPosition> _positions = [];
  FocusNode? _focusBeforeShow;
  bool _wasShowing = false;

  /// Retângulo da âncora usado no último build do conteúdo.
  Rect? _lastAnchorRect;

  /// Se há um pós-quadro registrado para conferir a âncora.
  bool _tracking = false;

  /// Posição efetiva calculada no último layout do conteúdo.
  GjaPlacement? _effective;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(GjaAnchoredOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToScrolling();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    for (final position in _positions) {
      position.removeListener(_handleScroll);
    }
    super.dispose();
  }

  /// Ouve as rolagens de todos os `Scrollable` acima da âncora.
  void _listenToScrolling() {
    for (final position in _positions) {
      position.removeListener(_handleScroll);
    }
    _positions.clear();
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      _positions.add(scrollable.position..addListener(_handleScroll));
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
  }

  // A posição da âncora só é atualizada no layout que segue a rolagem; o
  // conteúdo é reposicionado logo depois dele.
  void _handleScroll() {
    if (!widget.controller.isShowing) return;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted && widget.controller.isShowing) setState(() {});
      })
      ..ensureVisualUpdate();
  }

  /// Confere, depois de cada quadro com a sobreposição aberta, se a âncora
  /// mudou de posição ou de tamanho, e reposiciona o conteúdo. Não agenda
  /// quadros: só roda depois dos que já aconteceriam.
  void _trackAnchor() {
    if (_tracking) return;
    _tracking = true;
    SchedulerBinding.instance.addPostFrameCallback(_checkAnchor);
  }

  void _checkAnchor(Duration _) {
    _tracking = false;
    if (!mounted || !widget.controller.isShowing) return;
    final rect = _anchorRect(context);
    if (rect != null && rect != _lastAnchorRect) {
      setState(() {});
    }
    _trackAnchor();
  }

  /// Guarda a posição efetiva do layout e reconstrói o conteúdo quando ela
  /// muda, para que [GjaAnchoredOverlay.placementOf] a informe.
  void _handleResolvedPlacement(GjaPlacement placement) {
    if (placement == _effective) return;
    _effective = placement;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.isShowing) setState(() {});
    });
  }

  void _handleControllerChange() {
    final showing = widget.controller.isShowing;
    if (showing == _wasShowing) return;
    _wasShowing = showing;
    if (showing) {
      _trackAnchor();
    } else {
      _effective = null;
    }
    if (!widget.focusOnShow) return;
    if (showing) {
      _focusBeforeShow = FocusManager.instance.primaryFocus;
    } else {
      final previous = _focusBeforeShow;
      _focusBeforeShow = null;
      if (previous != null && previous.context != null) {
        previous.requestFocus();
      }
    }
  }

  void _dismiss() {
    widget.controller.hide();
    widget.onDismiss?.call();
  }

  /// Retângulo da âncora nas coordenadas do `Overlay`, ou nulo antes do
  /// primeiro layout.
  Rect? _anchorRect(BuildContext overlayContext) {
    final anchor = _anchorKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(context).context.findRenderObject();
    if (anchor is! RenderBox || overlay is! RenderBox || !anchor.hasSize) {
      return null;
    }
    final origin = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    return origin & anchor.size;
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final anchorRect = _anchorRect(overlayContext);
    _lastAnchorRect = anchorRect;
    if (anchorRect == null) return const SizedBox.shrink();
    Widget content = _PlacementScope(
      placement: _effective ?? widget.placement,
      child: Builder(builder: widget.overlayBuilder),
    );
    if (widget.focusOnShow) {
      content = FocusScope(child: GjaInitialFocus(child: content));
    }
    content = Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            if (widget.autoClose) _dismiss();
            return null;
          },
        ),
      },
      child: TapRegion(
        groupId: this,
        onTapOutside: widget.autoClose ? (_) => _dismiss() : null,
        child: content,
      ),
    );
    final spacing = GjaThemeData.of(context).spacing;
    return CustomSingleChildLayout(
      delegate: _AnchoredLayoutDelegate(
        anchor: anchorRect,
        placement: widget.placement,
        onResolved: _handleResolvedPlacement,
        alignment: widget.alignment,
        gap: widget.gap ?? spacing.xs,
        margin: widget.margin ?? spacing.s,
        textDirection: Directionality.of(context),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: widget.controller,
      overlayChildBuilder: _buildOverlay,
      child: TapRegion(
        groupId: this,
        child: KeyedSubtree(key: _anchorKey, child: widget.child),
      ),
    );
  }
}

/// Posiciona o conteúdo junto da âncora, com inversão e limite de bordas.
class _AnchoredLayoutDelegate extends SingleChildLayoutDelegate {
  _AnchoredLayoutDelegate({
    required this.anchor,
    required this.placement,
    required this.onResolved,
    required this.alignment,
    required this.gap,
    required this.margin,
    required this.textDirection,
  });

  final Rect anchor;
  final GjaPlacement placement;

  /// Recebe a posição efetiva, depois da inversão.
  final ValueChanged<GjaPlacement> onResolved;
  final GjaOverlayAlignment alignment;
  final double gap;
  final double margin;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(
      Size(
        math.max(0, constraints.maxWidth - 2 * margin),
        math.max(0, constraints.maxHeight - 2 * margin),
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final rtl = textDirection == TextDirection.rtl;
    final w = childSize.width;
    final h = childSize.height;

    // Posição ao longo da âncora, pelo alinhamento resolvido na direção.
    double along(
      double start,
      double end,
      double extent, {
      required bool horizontal,
    }) {
      final flip = horizontal && rtl;
      return switch (alignment) {
        GjaOverlayAlignment.center => (start + end - extent) / 2,
        GjaOverlayAlignment.start => flip ? end - extent : start,
        GjaOverlayAlignment.end => flip ? start : end - extent,
      };
    }

    final double x;
    final double y;
    final GjaPlacement resolved;
    switch (placement) {
      case GjaPlacement.bottom:
      case GjaPlacement.top:
        final belowY = anchor.bottom + gap;
        final aboveY = anchor.top - gap - h;
        final fitsBelow = belowY + h <= size.height - margin;
        final fitsAbove = aboveY >= margin;
        final wantsBelow = placement == GjaPlacement.bottom;
        final goBelow = wantsBelow
            ? (fitsBelow || !fitsAbove)
            : !(fitsAbove || !fitsBelow);
        y = goBelow ? belowY : aboveY;
        resolved = goBelow ? GjaPlacement.bottom : GjaPlacement.top;
        x = along(anchor.left, anchor.right, w, horizontal: true);
      case GjaPlacement.start:
      case GjaPlacement.end:
        final rightX = anchor.right + gap;
        final leftX = anchor.left - gap - w;
        final fitsRight = rightX + w <= size.width - margin;
        final fitsLeft = leftX >= margin;
        final wantsRight = (placement == GjaPlacement.end) != rtl;
        final goRight = wantsRight
            ? (fitsRight || !fitsLeft)
            : !(fitsLeft || !fitsRight);
        x = goRight ? rightX : leftX;
        resolved = goRight != rtl ? GjaPlacement.end : GjaPlacement.start;
        y = along(anchor.top, anchor.bottom, h, horizontal: false);
    }
    onResolved(resolved);
    return Offset(
      _clamp(x, margin, size.width - margin - w),
      _clamp(y, margin, size.height - margin - h),
    );
  }

  static double _clamp(double value, double min, double max) =>
      max < min ? min : value.clamp(min, max);

  @override
  bool shouldRelayout(_AnchoredLayoutDelegate old) =>
      old.anchor != anchor ||
      old.placement != placement ||
      old.alignment != alignment ||
      old.gap != gap ||
      old.margin != margin ||
      old.textDirection != textDirection;
}
