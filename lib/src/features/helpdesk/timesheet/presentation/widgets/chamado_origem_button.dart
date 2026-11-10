import 'package:gjamobile/src/features/helpdesk/timesheet/utils/chamado_link.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Abre o chamado [origemId] no Verdana Desk, em uma nova aba (na web) ou no
/// navegador do sistema.
///
/// Fica onde o portal mostra o número do chamado — o detalhe e o formulário de
/// apontamento trazem só o resumo, e conferir o que foi pedido (acompanhamentos,
/// anexos) exige a página do ticket.
class ChamadoOrigemButton extends StatelessWidget {
  const ChamadoOrigemButton({super.key, required this.origemId});

  /// Número do chamado na origem — o mesmo `#4242` exibido no portal.
  final int origemId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Abrir o chamado no Verdana Desk',
      icon: const Icon(GjaIcons.popupWindow, size: 20),
      // Compacto (40 dp em vez de 48): o botão divide linha com um rótulo de
      // uma linha e com o campo travado, e no tamanho cheio ele é que mandaria
      // na altura da linha.
      visualDensity: VisualDensity.compact,
      onPressed: () => _abrir(context),
    );
  }

  Future<void> _abrir(BuildContext context) async {
    final aberto = await launchUrl(
      chamadoNoVerdanaDesk(origemId),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (aberto || !context.mounted) return;
    showToast(
      context,
      message: 'Não foi possível abrir o chamado',
      status: 'error',
    );
  }
}
