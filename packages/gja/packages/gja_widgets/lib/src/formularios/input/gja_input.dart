import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../exibicao_dados/tooltip/gja_tooltip.dart';

/// Tipo de um [GjaInput], como o `sap.m.InputType`: define o teclado e,
/// em [password], esconde os caracteres.
enum GjaInputType {
  /// Texto livre.
  text,

  /// Endereço de e-mail.
  email,

  /// Número.
  number,

  /// Senha, com os caracteres escondidos.
  password,

  /// Telefone.
  tel,

  /// Endereço web.
  url,
}

/// Campo de texto de uma linha, como o `sap.m.Input` do SAPUI5.
///
/// É controlado: mostra [value] e avisa cada edição por [onLiveChange]; o
/// pai devolve o novo valor. [onSubmit] é chamado com Enter, e [onChange]
/// com Enter ou ao perder o foco, quando o texto mudou desde o último aviso,
/// como os eventos `submit` e `change` do UI5.
///
/// Com [valueState] e [valueStateText], mostra a mensagem do estado abaixo do
/// campo enquanto ele tem o foco. Com [showClearIcon], mostra um botão que
/// esvazia o texto; com [showValueHelp], um ícone que chama
/// [onValueHelpRequest] (também com F4 ou Alt+seta para baixo). Com [enabled] `false`, não recebe foco nem edição; com
/// [editable] `false`, recebe o foco e permite selecionar, sem editar.
///
/// Sem rótulo visível, [semanticLabel] (ou, sem ele, [placeholder]) é o nome
/// lido pelo leitor de tela.
///
/// ```dart
/// GjaInput(
///   semanticLabel: 'Nome',
///   placeholder: 'Nome completo',
///   value: nome,
///   onLiveChange: (value) => setState(() => nome = value),
/// )
/// ```
class GjaInput extends StatefulWidget {
  /// Cria o campo.
  const GjaInput({
    this.value = '',
    this.onLiveChange,
    this.onChange,
    this.onSubmit,
    this.placeholder,
    this.semanticLabel,
    this.type = GjaInputType.text,
    this.enabled = true,
    this.editable = true,
    this.valueState = GjaValueState.none,
    this.valueStateText,
    this.maxLength = 0,
    this.showClearIcon = false,
    this.showValueHelp = false,
    this.valueHelpIconSrc = GjaIcons.popupWindow,
    this.onValueHelpRequest,
    this.focusNode,
    super.key,
  }) : assert(
         (semanticLabel != null && semanticLabel != '') ||
             (placeholder != null && placeholder != ''),
         'GjaInput precisa de semanticLabel ou placeholder não vazio',
       ),
       assert(maxLength >= 0, 'maxLength não pode ser negativo');

  /// Texto do campo.
  final String value;

  /// Chamado a cada edição, como o evento `liveChange` do UI5.
  final ValueChanged<String>? onLiveChange;

  /// Chamado com Enter ou ao perder o foco, quando o texto mudou, como o
  /// evento `change` do UI5.
  final ValueChanged<String>? onChange;

  /// Chamado com Enter, como o evento `submit` do UI5.
  final ValueChanged<String>? onSubmit;

  /// Texto mostrado enquanto o campo está vazio.
  final String? placeholder;

  /// Nome anunciado pelo leitor de tela; sem ele, vale [placeholder].
  final String? semanticLabel;

  /// Tipo, que define o teclado.
  final GjaInputType type;

  /// Se o campo pode receber foco e edição.
  final bool enabled;

  /// Se o texto pode ser editado; `false` deixa o campo somente leitura.
  final bool editable;

  /// Estado de valor, que colore a borda e o fundo.
  final GjaValueState valueState;

  /// Mensagem do estado de valor, mostrada abaixo do campo com o foco.
  final String? valueStateText;

  /// Número máximo de caracteres; `0` não limita.
  final int maxLength;

  /// Se mostra o botão de limpar quando há texto.
  final bool showClearIcon;

  /// Se mostra, no fim, o ícone de ajuda de valor [valueHelpIconSrc].
  final bool showValueHelp;

  /// Ícone da ajuda de valor.
  final IconData valueHelpIconSrc;

  /// Chamado ao tocar o ícone da ajuda de valor, ou com F4 ou Alt+seta para
  /// baixo no campo, como o evento `valueHelpRequest` do UI5.
  final VoidCallback? onValueHelpRequest;

  /// Nó de foco do campo; um interno é criado quando nulo.
  final FocusNode? focusNode;

  @override
  State<GjaInput> createState() => _GjaInputState();
}

class _GjaInputState extends State<GjaInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  FocusNode? _internalNode;
  late String _lastChange;
  bool _hovered = false;

  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _lastChange = widget.value;
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(GjaInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalNode)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _internalNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_node.hasFocus) _notifyChange();
    setState(() {});
  }

  void _notifyChange() {
    final text = _controller.text;
    if (text != _lastChange) {
      _lastChange = text;
      widget.onChange?.call(text);
    }
  }

  void _help() => widget.onValueHelpRequest?.call();

  void _clear() {
    _controller.clear();
    widget.onLiveChange?.call('');
    _notifyChange();
    setState(() {});
  }

  TextInputType get _keyboard => switch (widget.type) {
    GjaInputType.text || GjaInputType.password => TextInputType.text,
    GjaInputType.email => TextInputType.emailAddress,
    GjaInputType.number => TextInputType.number,
    GjaInputType.tel => TextInputType.phone,
    GjaInputType.url => TextInputType.url,
  };

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    final focused = _node.hasFocus;
    final state = colors.stateColors(widget.valueState);
    final hasState = widget.valueState != GjaValueState.none;
    final active = widget.enabled && (focused || _hovered);
    final background = !widget.editable
        ? colors.headerBackground
        : (hasState ? state.background : colors.base);
    final border = active
        ? colors.brand
        : (hasState ? state.border : colors.fieldBorder);
    final style = theme.typography.base.copyWith(color: colors.text);
    final corners = BorderRadius.circular(theme.radius.field);
    final message = widget.valueStateText;
    final showMessage = hasState && message != null && message != '' && focused;
    final showClear =
        widget.showClearIcon &&
        widget.enabled &&
        widget.editable &&
        _controller.text.isNotEmpty;
    final showHelp = widget.showValueHelp && widget.enabled && widget.editable;

    final field = EditableText(
      controller: _controller,
      focusNode: _node,
      style: style,
      cursorColor: colors.brand,
      backgroundCursorColor: colors.label,
      selectionColor: colors.selectionBackground,
      readOnly: !widget.editable,
      obscureText: widget.type == GjaInputType.password,
      keyboardType: _keyboard,
      maxLines: 1,
      inputFormatters: [
        if (widget.maxLength > 0)
          LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      onChanged: (text) {
        widget.onLiveChange?.call(text);
        setState(() {});
      },
      onSubmitted: (text) {
        widget.onSubmit?.call(text);
        _notifyChange();
      },
    );

    final placeholder = widget.placeholder;
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: corners,
        border: Border.all(color: border, width: const BorderSide().width),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.density.controlHeight),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: theme.spacing.s,
            end: showClear || showHelp ? theme.spacing.none : theme.spacing.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    if (placeholder != null && _controller.text.isEmpty)
                      ExcludeSemantics(
                        child: Text(
                          placeholder,
                          style: theme.typography.base.copyWith(
                            color: colors.label,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (showHelp)
                      CallbackShortcuts(
                        bindings: {
                          const SingleActivator(LogicalKeyboardKey.f4): _help,
                          const SingleActivator(
                            LogicalKeyboardKey.arrowDown,
                            alt: true,
                          ): _help,
                        },
                        child: field,
                      )
                    else
                      field,
                  ],
                ),
              ),
              // Como no UI5, o ícone de limpar não é parada de Tab nem nó
              // próprio do leitor de tela.
              if (showClear)
                ExcludeSemantics(
                  child: GjaTooltip(
                    message: GjaLocalizations.of(context).clear,
                    excludeFromSemantics: true,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        key: const ValueKey('gja-input-clear'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _clear,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: theme.spacing.s,
                          ),
                          child: Icon(
                            GjaIcons.decline,
                            size: theme.icons.control,
                            color: colors.brand,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Como o de limpar, o ícone da ajuda de valor não é parada de
              // Tab; F4 e Alt+seta para baixo fazem o mesmo pelo teclado.
              if (showHelp)
                ExcludeSemantics(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      key: const ValueKey('gja-input-value-help'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _help,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.spacing.s,
                        ),
                        child: Icon(
                          widget.valueHelpIconSrc,
                          size: theme.icons.control,
                          color: colors.brand,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    box = GjaFocusRing(
      visible: focused && widget.enabled,
      width: theme.interaction.focusWidth,
      offset: theme.interaction.focusOffset,
      color: colors.focus,
      borderRadius: corners,
      child: box,
    );
    box = MouseRegion(
      cursor: widget.enabled && widget.editable
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _node.requestFocus : null,
        child: box,
      ),
    );
    // Um só nó, com o alvo mínimo da densidade em volta da moldura.
    box = MergeSemantics(
      child: Semantics(
        textField: true,
        label: widget.semanticLabel ?? widget.placeholder,
        hint: hasState ? message : null,
        readOnly: !widget.editable,
        enabled: widget.enabled,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: theme.density.minTargetSize),
          child: Center(heightFactor: 1, child: box),
        ),
      ),
    );
    if (!widget.enabled) {
      box = ExcludeFocus(
        child: IgnorePointer(
          child: Opacity(
            opacity: theme.interaction.opacity({
              GjaInteractionState.disabled,
            }),
            child: box,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        box,
        if (showMessage)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: theme.spacing.xxs,
              start: theme.spacing.s,
            ),
            child: ExcludeSemantics(
              child: Text(
                message,
                style: theme.typography.small.copyWith(color: state.foreground),
              ),
            ),
          ),
      ],
    );
  }
}
