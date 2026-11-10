import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Aviso breve que some sozinho, como o `sap.m.MessageToast` do SAPUI5.
///
/// [show] mostra a mensagem numa caixa escura, centralizada perto da borda
/// de baixo da tela, por [defaultDuration] (ou a duração dada). O aviso não
/// recebe foco nem toques e é anunciado pelo leitor de tela; um novo aviso
/// substitui o visível.
///
/// ```dart
/// GjaMessageToast.show(context, 'Pedido 4711 salvo');
/// ```
abstract final class GjaMessageToast {
  /// Duração padrão do aviso, a do `MessageToast` do UI5 (3000 ms).
  static const defaultDuration = Duration(seconds: 3);

  static OverlayEntry? _current;

  /// Mostra [message] por [duration], substituindo o aviso visível.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
  }) {
    assert(message != '', 'message não pode ser vazio');
    final overlay = Overlay.of(context, rootOverlay: true);
    final previous = _current;
    if (previous != null && previous.mounted) previous.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _Toast(
        message: message,
        duration: duration,
        onDone: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  bool _visible = false;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Esmaece de entrada no quadro seguinte.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _timer = Timer(widget.duration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onFadeEnd() {
    if (!_visible && !_done && _timer?.isActive == false) {
      _done = true;
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = math.min(
      theme.spacing.xxxl * 5,
      math.max(width - 2 * theme.spacing.l, theme.spacing.none),
    );
    final fade = theme.motion.medium;
    if (fade == Duration.zero && !_visible && _timer?.isActive == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onFadeEnd());
    }
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.text,
        borderRadius: BorderRadius.circular(theme.radius.element),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.l),
        child: Text(
          widget.message,
          textAlign: TextAlign.center,
          style: theme.typography.base.copyWith(
            color: theme.colors.contrastText,
          ),
        ),
      ),
    );
    // Toques e foco passam pelo aviso; só o texto anunciado fica na
    // semântica.
    return ExcludeFocus(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: theme.spacing.xxxl),
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: fade,
            curve: theme.motion.standard,
            onEnd: _onFadeEnd,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Semantics(
                container: true,
                liveRegion: true,
                label: widget.message,
                child: IgnorePointer(child: ExcludeSemantics(child: box)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
