import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/utils/avisar_falha.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/leitura_checkin_view.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/empresa_sap_field.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/wrappers/base_state_wrapper.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Porta de entrada da contagem cega: o conferente lê o QR Code gerado na
/// portaria (ou digita o número) e o app abre as notas daquele check-in.
///
/// O corpo é a [LeituraCheckinView] compartilhada pelos submódulos do inbound —
/// aqui só ficam as regras da contagem: validar, carregar e navegar.
class ScanCheckinScreen extends StatefulWidget {
  const ScanCheckinScreen({super.key});

  @override
  State<ScanCheckinScreen> createState() => _ScanCheckinScreenState();
}

class _ScanCheckinScreenState
    extends BaseState<ScanCheckinScreen, ContagemCegaController> {
  Future<void> _onScan() async {
    final lido = await showQrScannerScreen(
      context,
      title: 'Ler QR Code do check-in',
    );
    if (lido == null || !mounted) return;
    controller.aplicarCodigoLido(lido);
    await _confirmar();
  }

  Future<void> _confirmar() async {
    final numero = controller.checkinController.text;
    if (numero.replaceAll(RegExp(r'\D'), '').isEmpty) {
      showToast(
        context,
        message: 'Informe ou escaneie o número do check-in',
        status: 'warning',
      );
      return;
    }

    final carregou = await controller.carregarCheckin(numero);
    if (!mounted) return;
    if (!carregou) {
      _avisarFalha();
      return;
    }
    context.go(AppRoutes.gjaautoInboundContagemCegaNotas);
  }

  void _avisarFalha() => avisarFalhaContagem(
        context,
        controller.erroSignal.value,
        controller.configErrorSignal.value,
      );

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      formWidth: true,
      // Centraliza o bloco: a tela é curta e, num coletor alto, encostada no
      // topo ela deixa um terço da tela vazio embaixo. O scaffold continua
      // rolando quando o teclado sobe ou o erro aparece.
      centerVertically: true,
      appBar: const AppTopBar(title: 'Contagem cega'),
      body: SignalBuilder(builder: (context) {
        return LeituraCheckinView(
          empresaField: controller.podeSelecionarEmpresa
              ? EmpresaSapField(
                  empresa: controller.empresaSelecionada,
                  onChanged: controller.operacaoEmAndamento
                      ? null
                      : controller.selecionarEmpresa,
                )
              : null,
          titulo: 'Contagem cega',
          controller: controller.checkinController,
          focusNode: controller.checkinFocus,
          carregando: controller.statusSignal.value == AppStatus.loading,
          onScan: _onScan,
          onConfirmar: _confirmar,
          erro: _buildErro(context),
        );
      }),
    );
  }

  /// Configuração indisponível bloqueia mais do que uma busca falha, então é
  /// checada primeiro. `null` some o bloco inteiro.
  Widget? _buildErro(BuildContext context) {
    final config = controller.configErrorSignal.value;
    if (config != null) {
      return AppErrorWidget(
        title: 'Configuração indisponível',
        message: config,
        icon: GjaIcons.building,
      );
    }

    final falha = controller.erroSignal.value;
    if (controller.statusSignal.value != AppStatus.failure || falha == null) {
      return null;
    }
    return AppErrorWidget(
      title: 'Não foi possível abrir o check-in',
      message: falha.message,
    );
  }
}
