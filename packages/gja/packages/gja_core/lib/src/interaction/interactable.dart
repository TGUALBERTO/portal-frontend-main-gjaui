import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

import 'focus_ring.dart';

/// Constrói o conteúdo de um [GjaInteractable] a partir dos estados ativos.
typedef GjaInteractableBuilder =
    Widget Function(BuildContext context, Set<GjaInteractionState> states);

/// Elemento interativo base do GJA.
///
/// Detecta hover, pressionado e foco; ativa por toque e por Enter, Enter
/// numérico ou Espaço (atalhos nativos do `WidgetsApp`); desabilita-se quando
/// [onPressed] é nulo; ocupa pelo menos [minTargetSize] em cada dimensão;
/// expõe semântica de botão; e desenha o anel de foco somente quando o foco
/// vem do teclado. O widget que o usa pinta a própria aparência no
/// [builder], normalmente com `GjaControlColors.resolve` da família do
/// controle e `GjaInteractionStateTokens.opacity`.
///
/// Os valores visuais omitidos vêm do tema ativo (`GjaThemeData.of`):
/// alvo da densidade, tokens de interação, cor `focus` e raio `button`. Um
/// valor passado tem precedência sobre o do tema.
class GjaInteractable extends StatefulWidget {
  /// Cria o elemento.
  const GjaInteractable({
    required this.builder,
    this.onPressed,
    this.selected = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.minTargetSize,
    this.interactionTokens,
    this.focusColor,
    this.focusRingBorderRadius,
    this.link = false,
    this.checked,
    this.mixed = false,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    super.key,
  });

  /// Constrói o conteúdo a partir dos estados ativos.
  final GjaInteractableBuilder builder;

  /// Ação do elemento; nula deixa o elemento desabilitado.
  final VoidCallback? onPressed;

  /// Se o elemento está selecionado (informado pelo widget que o usa).
  final bool selected;

  /// Rótulo lido pelo leitor de tela.
  final String? semanticLabel;

  /// Nó de foco externo; um interno é criado quando nulo.
  final FocusNode? focusNode;

  /// Se o elemento pede foco ao ser inserido.
  final bool autofocus;

  /// Lado mínimo da área de interação, em pixels lógicos; nulo usa o alvo
  /// da densidade do tema ativo.
  final double? minTargetSize;

  /// Regras e valores dos estados de interação; nulo usa os do tema ativo.
  final GjaInteractionStateTokens? interactionTokens;

  /// Cor do anel de foco; nula usa o papel `focus` do tema ativo.
  final Color? focusColor;

  /// Cantos do conteúdo, para o anel de foco acompanhar a curva; nulo usa o
  /// raio `button` do tema ativo.
  final BorderRadius? focusRingBorderRadius;

  /// Se o elemento é exposto ao leitor de tela como link, em vez de botão
  /// (ex.: `GjaLink`).
  final bool link;

  /// Estado de marcação exposto ao leitor de tela (ex.: `GjaCheckBox`);
  /// nulo quando o elemento não é marcável. Com ele, o elemento deixa de ser
  /// exposto como botão.
  final bool? checked;

  /// Se a marcação é mista (caixa parcialmente marcada).
  final bool mixed;

  /// Estado de alternância exposto ao leitor de tela (ex.: `GjaSwitch`);
  /// nulo quando o elemento não alterna.
  final bool? toggled;

  /// Se o elemento marcável pertence a um grupo de escolha única (ex.: opção
  /// de rádio).
  final bool inMutuallyExclusiveGroup;

  @override
  State<GjaInteractable> createState() => _GjaInteractableState();
}

class _GjaInteractableState extends State<GjaInteractable> {
  FocusNode? _internalFocusNode;
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  bool _focusHighlight = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool get _enabled => widget.onPressed != null;

  Set<GjaInteractionState> get _states => {
    if (!_enabled) GjaInteractionState.disabled,
    if (_enabled && _hovered) GjaInteractionState.hovered,
    if (_enabled && _pressed) GjaInteractionState.pressed,
    if (_enabled && _focused) GjaInteractionState.focused,
    if (widget.selected) GjaInteractionState.selected,
  };

  @override
  void didUpdateWidget(GjaInteractable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _hovered = false;
      _pressed = false;
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _activate() => widget.onPressed?.call();

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final states = _states;
    final theme = GjaThemeData.of(context);
    final tokens = widget.interactionTokens ?? theme.interaction;
    final minTargetSize = widget.minTargetSize ?? theme.density.minTargetSize;
    final showRing = _focusHighlight && tokens.showsFocusRing(states);

    return Semantics(
      container: true,
      button:
          !widget.link &&
          widget.checked == null &&
          widget.toggled == null &&
          !widget.mixed,
      checked: widget.mixed ? null : widget.checked,
      mixed: widget.mixed ? true : null,
      toggled: widget.toggled,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      link: widget.link,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: _enabled ? _activate : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
        },
        onShowFocusHighlight: (value) =>
            setState(() => _focusHighlight = value),
        onFocusChange: (value) => setState(() => _focused = value),
        // Hover é o fato de o ponteiro estar sobre o elemento; o destaque de
        // hover do FocusableActionDetector depende do modo de destaque.
        child: MouseRegion(
          onEnter: _enabled ? (_) => setState(() => _hovered = true) : null,
          onExit: (_) {
            if (_hovered) setState(() => _hovered = false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled
                ? (_) {
                    _focusNode.requestFocus();
                    _setPressed(true);
                  }
                : null,
            onTapUp: _enabled ? (_) => _setPressed(false) : null,
            onTapCancel: _enabled ? () => _setPressed(false) : null,
            onTap: _enabled ? _activate : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minTargetSize,
                minHeight: minTargetSize,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: GjaFocusRing(
                  visible: showRing,
                  width: tokens.focusWidth,
                  offset: tokens.focusOffset,
                  color: widget.focusColor ?? theme.colors.focus,
                  borderRadius:
                      widget.focusRingBorderRadius ??
                      BorderRadius.circular(theme.radius.button),
                  child: widget.builder(context, states),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
