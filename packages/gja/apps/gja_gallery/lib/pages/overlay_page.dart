import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "Sobreposições": modal dispensável, modal obrigatório e uma
/// sobreposição ancorada com escolha da posição preferida.
///
/// A aparência dos conteúdos é provisória da galeria; os widgets de diálogo e
/// popover terão specs próprias. As dimensões são literais da galeria.
class OverlayPage extends StatefulWidget {
  /// Cria a página.
  const OverlayPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Sobreposições';

  /// Rota nomeada.
  static const route = '/overlay';

  /// Chave do texto com o último resultado do modal.
  static const resultKey = Key('overlay-result');

  /// Chave do conteúdo da sobreposição ancorada.
  static const popoverKey = Key('overlay-popover');

  @override
  State<OverlayPage> createState() => _OverlayPageState();
}

class _OverlayPageState extends State<OverlayPage> {
  final _popover = GjaAnchoredOverlayController();
  GjaPlacement _placement = GjaPlacement.bottom;
  String _result = 'nenhum';

  GjaThemeData get _theme => GjaTheme.of(context);

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  Widget _button(
    String label,
    VoidCallback onPressed, {
    bool selected = false,
  }) {
    final t = _theme;
    return GjaInteractable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      builder: (context, states) {
        final c = GjaControlColors.of(
          GjaControlFamily.standard,
          t.colors,
        ).resolve(states);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.m,
            vertical: t.spacing.s,
          ),
          decoration: BoxDecoration(
            color: c.background,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(t.radius.button),
          ),
          child: Text(label, style: t.typography.base.copyWith(color: c.text)),
        );
      },
    );
  }

  Widget _panel(List<Widget> children) {
    final t = _theme;
    return Container(
      padding: EdgeInsets.all(t.spacing.l),
      decoration: BoxDecoration(
        color: t.colors.base,
        borderRadius: BorderRadius.circular(t.radius.element),
        boxShadow: t.shadows.boxShadows(t.shadows.dialog, t.colors.shadow),
      ),
      child: DefaultTextStyle(
        style: t.typography.base.copyWith(color: t.colors.text),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Future<void> _openModal() async {
    final result = await GjaModal.show<String>(
      context,
      builder: (context) => _panel([
        Text('Enviar pedido?', style: _theme.typography.header3),
        SizedBox(height: _theme.spacing.l),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button('Confirmar', () => Navigator.of(context).pop('confirmado')),
            SizedBox(width: _theme.spacing.s),
            _button('Cancelar', () => Navigator.of(context).pop()),
          ],
        ),
      ]),
    );
    if (mounted) setState(() => _result = result ?? 'dispensado');
  }

  Future<void> _openRequiredModal() async {
    await GjaModal.show<void>(
      context,
      dismissible: false,
      builder: (context) => _panel([
        Text('Leia antes de continuar', style: _theme.typography.header3),
        SizedBox(height: _theme.spacing.l),
        _button('Concluir', () => Navigator.of(context).pop()),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return ColoredBox(
      color: t.colors.base,
      child: DefaultTextStyle(
        style: t.typography.base.copyWith(color: t.colors.text),
        child: ListView(
          padding: EdgeInsets.all(t.spacing.pageMargin),
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Semantics(button: true, child: const Text('← Voltar')),
            ),
            SizedBox(height: t.spacing.stackGap),
            Text(OverlayPage.title, style: t.typography.header2),
            SizedBox(height: t.spacing.sectionGap),
            Wrap(
              spacing: t.spacing.s,
              runSpacing: t.spacing.s,
              children: [
                _button('Abrir modal', _openModal),
                _button('Abrir modal obrigatório', _openRequiredModal),
              ],
            ),
            SizedBox(height: t.spacing.s),
            Text('Resultado: $_result', key: OverlayPage.resultKey),
            SizedBox(height: t.spacing.sectionGap),
            Text('Posição preferida', style: t.typography.header3),
            SizedBox(height: t.spacing.s),
            Wrap(
              spacing: t.spacing.s,
              runSpacing: t.spacing.s,
              children: [
                for (final placement in GjaPlacement.values)
                  _button(
                    placement.name,
                    () => setState(() => _placement = placement),
                    selected: placement == _placement,
                  ),
              ],
            ),
            SizedBox(height: t.spacing.l),
            Center(
              child: GjaAnchoredOverlay(
                controller: _popover,
                placement: _placement,
                overlayBuilder: (context) => KeyedSubtree(
                  key: OverlayPage.popoverKey,
                  child: _panel([
                    _button('Primeiro item', _popover.hide),
                    SizedBox(height: t.spacing.xs),
                    _button('Segundo item', _popover.hide),
                  ]),
                ),
                child: _button(
                  'Abrir popover',
                  () => _popover.isShowing ? _popover.hide() : _popover.show(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
