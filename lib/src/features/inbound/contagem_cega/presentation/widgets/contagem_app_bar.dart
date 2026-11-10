import 'package:gjamobile/src/imports/imports.dart';

/// Cabeçalho das telas da contagem cega: volta, contexto (check-in / NF-e /
/// fornecedor), título e um selo opcional à direita.
///
/// Envolve o [AppTopBar] para manter o comportamento de voltar do portal (pop,
/// ou Home quando não há para onde voltar) sem repetir o bloco de dois níveis
/// de texto em cada tela.
class ContagemAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ContagemAppBar({
    super.key,
    required this.kicker,
    required this.titulo,
    this.trailing,
    this.onVoltar,
    this.showBackButton = true,
  });

  /// Linha de contexto acima do título.
  final String kicker;

  final String titulo;

  /// Selo à direita — contagem de NFs, "Devolver", "Tentativa 2/3".
  final Widget? trailing;

  /// Sobrescreve o destino do botão voltar (o padrão é `pop`).
  final VoidCallback? onVoltar;

  final bool showBackButton;

  /// Mesmo teto que o Material aplica ao título da AppBar
  /// (`_kMaxTitleTextScaleFactor`).
  static const double _maxEscalaTexto = 1.34;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppTopBar(
      title: titulo,
      centerTitle: false,
      showBackButton: showBackButton,
      onPressed: onVoltar,
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            kicker,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
      actions: trailing == null
          ? null
          : [
              Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                // O Flutter limita a escala de texto do título da AppBar em
                // 1,34× mas não a das actions — sem o mesmo teto o selo
                // estoura a barra (altura fixa) em acessibilidade 2×.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: _maxEscalaTexto,
                  // `widthFactor: 1` para o selo não esticar dentro da barra.
                  child: Center(widthFactor: 1, child: trailing),
                ),
              ),
            ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
