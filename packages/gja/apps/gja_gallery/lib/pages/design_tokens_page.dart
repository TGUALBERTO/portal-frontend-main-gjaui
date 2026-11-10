import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "Design tokens": papéis de movimento e interpolação entre conjuntos.
///
/// Usa literais visuais provisórios (cores, espaçamentos) até existirem os
/// fundamentos de cor e espaçamento; a galeria é aplicação, fora da
/// verificação de tokens.
class DesignTokensPage extends StatefulWidget {
  /// Cria a página.
  const DesignTokensPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Design tokens';

  /// Rota nomeada.
  static const route = '/design-tokens';

  @override
  State<DesignTokensPage> createState() => _DesignTokensPageState();
}

class _DesignTokensPageState extends State<DesignTokensPage>
    with SingleTickerProviderStateMixin {
  static const _fallback = GjaMotionTokens.fallback();

  /// Conjunto "lento": o dobro das durações do `fallback()`.
  static final _slow = _fallback.copyWith(
    short: _fallback.short * 2,
    medium: _fallback.medium * 2,
    long: _fallback.long * 2,
  );

  /// Curvas CSS usadas pelo SAPUI5, para nomear as curvas dos papéis.
  static const _css = <Curve, String>{
    Cubic(0.42, 0, 0.58, 1): 'ease-in-out',
    Cubic(0, 0, 0.58, 1): 'ease-out',
    Cubic(0.42, 0, 1, 1): 'ease-in',
  };

  static String _cssName(Curve curve) => _css[curve] ?? curve.toString();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _fallback.long,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.status == AnimationStatus.completed ||
        _controller.status == AnimationStatus.forward) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = GjaThemeData.of(context);
    return ColoredBox(
      color: page.colors.base,
      child: DefaultTextStyle(
        style: page.typography.base.copyWith(color: page.colors.text),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final motion = _fallback.lerp(_slow, t);
            final roles = <String, Duration>{
              'instant': motion.instant,
              'short': motion.short,
              'medium': motion.medium,
              'long': motion.long,
            };
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Semantics(button: true, child: const Text('← Voltar')),
                ),
                const SizedBox(height: 16),
                const Text(
                  DesignTokensPage.title,
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Movimento — fallback → lento (t = ${t.toStringAsFixed(2)})',
                ),
                const SizedBox(height: 16),
                for (final MapEntry(key: role, value: duration)
                    in roles.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: 96, child: Text(role)),
                        SizedBox(
                          width: 72,
                          child: Text('${duration.inMilliseconds} ms'),
                        ),
                        Container(
                          height: 12,
                          width: duration.inMilliseconds / 2,
                          color: page.colors.brand,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Curvas'),
                const SizedBox(height: 8),
                for (final (role, curve) in [
                  ('standard', motion.standard),
                  ('enter', motion.enter),
                  ('exit', motion.exit),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('$role: ${_cssName(curve)}'),
                  ),
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: Semantics(
                    button: true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: page.colors.selectionBackground,
                      child: const Text('Alternar conjunto (interpolação)'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
