import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/entities/checkin_motorista.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/enums/checkin_checkout_veiculo_mode.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/presentation/controllers/checkin_checkout_veiculo_controller.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/presentation/widgets/checkin_sucesso_panel.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/leitura_checkin_view.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/empresa_sap_field.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/wrappers/base_state_wrapper.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela da portaria: o segurança informa o número do check-in (coletor,
/// digitação ou QR Code), o app consulta o check-in no SAP da empresa do
/// usuário e — se o [CheckinCheckoutVeiculoScreen.mode] tiver ação e o status
/// permitir — libera a entrada ou a saída do caminhão.
///
/// As três rotas de `inbound_routes.dart` apontam para cá; o modo diferencia.
/// Em [CheckinCheckoutVeiculoMode.consulta] a tela para no card de dados.
///
/// O bloco de leitura do número é a [LeituraCheckinView] compartilhada pelos
/// submódulos do inbound — aqui só ficam a busca e o que vem depois dela.
class CheckinCheckoutVeiculoScreen extends StatefulWidget {
  const CheckinCheckoutVeiculoScreen({super.key, required this.mode});

  final CheckinCheckoutVeiculoMode mode;

  @override
  State<CheckinCheckoutVeiculoScreen> createState() =>
      _CheckinCheckoutVeiculoScreenState();
}

class _CheckinCheckoutVeiculoScreenState extends BaseState<
    CheckinCheckoutVeiculoScreen, CheckinCheckoutVeiculoController> {
  /// Âncora do bloco de resultado — a tela rola até ele quando a busca volta.
  final GlobalKey _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Em initState, não em onReady(): o BaseState dispara onReady num
    // post-frame callback, ou seja, depois do primeiro build.
    controller.init(widget.mode);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onScan() async {
    final scanned = await showQrScannerScreen(
      context,
      title: 'Ler QR Code do check-in',
    );
    if (scanned == null || !mounted) return;
    controller.aplicarCodigoLido(scanned);
    await _buscar();
  }

  /// Busca o check-in e, com o resultado na tela, rola até o card de dados.
  ///
  /// O campo do número ocupa o topo e no coletor o resultado nasce abaixo da
  /// dobra — sem isso o segurança teria que rolar à mão depois de cada leitura.
  Future<void> _buscar() async {
    await controller.buscarCheckin(context: context);
    if (!mounted) return;
    if (controller.lookupStatusSignal.value != AppStatus.success) return;

    // Depois do frame: o card só entra na árvore no rebuild que a escrita do
    // signal agendou, e antes disso não há posição para calcular.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultContext = _resultKey.currentContext;
      if (!mounted || resultContext == null) return;
      Scrollable.ensureVisible(
        resultContext,
        // Topo do card no topo da viewport; quando o conteúdo é curto a própria
        // rolagem satura no fim, que é o efeito desejado.
        alignment: 0,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: AppDurations.normal,
        curve: AppCurves.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      formWidth: true,
      centerVertically: true,
      appBar: AppTopBar(title: widget.mode.tituloTela),
      body: SignalBuilder(builder: (context) {
        final configError = controller.configErrorSignal.value;
        if (configError != null) {
          return AppErrorWidget(
            title: 'Configuração indisponível',
            message: configError,
            icon: GjaIcons.building,
          );
        }

        // Liberação concluída: o painel de sucesso toma a tela inteira, para o
        // segurança confirmar de longe o que foi liberado. Nunca acontece em
        // `consulta`, que não submete nada.
        if (controller.submitStatusSignal.value == AppStatus.success) {
          return _buildSucesso(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LeituraCheckinView(
              empresaField: controller.podeSelecionarEmpresa
                  ? EmpresaSapField(
                      empresa: controller.empresaSelecionada,
                      onChanged: controller.operacaoEmAndamento
                          ? null
                          : controller.selecionarEmpresa,
                    )
                  : null,
              titulo: widget.mode.tituloTela,
              kicker: 'Inbound · Portaria',
              labelConfirmar: 'Buscar',
              controller: controller.checkinController,
              focusNode: controller.checkinFocus,
              carregando:
                  controller.lookupStatusSignal.value == AppStatus.loading,
              onScan: _onScan,
              onConfirmar: _buscar,
            ),
            SizedBox(height: AppSpacing.lg),
            _buildResultSection(context),
          ],
        );
      }),
    );
  }

  /// Painel de confirmação. Só a contagem reassina o signal do tempo, então o
  /// tick de 1s reconstrói apenas este trecho.
  Widget _buildSucesso(BuildContext context) {
    return SignalBuilder(builder: (context) {
      return CheckinSucessoPanel(
        mode: widget.mode,
        checkin: controller.checkinSignal.value,
        segundosRestantes: controller.countdownSignal.value,
        totalSegundos: CheckinCheckoutVeiculoController.segundosParaHome,
        onIrParaHome: controller.irParaHome,
        onNovaOperacao: controller.novaOperacao,
      );
    });
  }

  Widget _buildResultSection(BuildContext context) {
    return SignalBuilder(
        key: _resultKey,
        builder: (context) {
          final status = controller.lookupStatusSignal.value;
          return switch (status) {
            AppStatus.initial => const SizedBox.shrink(),
            // Sem loader próprio: o spinner do botão "Buscar" já sinaliza a
            // consulta e dois indicadores ao mesmo tempo poluíam a tela.
            AppStatus.loading => const SizedBox.shrink(),
            AppStatus.failure => AppErrorWidget(
                message: controller.lookupErrorSignal.value?.message,
                onRetry: () => _buscar(),
              ),
            AppStatus.success => _buildCheckinCard(context),
          };
        });
  }

  Widget _buildCheckinCard(BuildContext context) {
    final checkin = controller.checkinSignal.value;
    if (checkin == null) return const SizedBox.shrink();

    return AppCard(
      showShadow: true,
      title: 'Dados do check-in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileInfoTile(
            icon: GjaIcons.incident,
            label: 'Número do check-in',
            value: checkin.checkin
                .replaceFirst(RegExp(r'^0+'), ''), //tirar zeros a esquerda
          ),
          ProfileInfoTile(
            icon: GjaIcons.personPlaceholder,
            label: 'Motorista',
            value: checkin.motorista.isEmpty ? '—' : checkin.motorista,
          ),
          ProfileInfoTile(
            icon: GjaIcons.shippingStatus,
            label: 'Placa',
            value: checkin.placa.isEmpty ? '—' : checkin.placa,
          ),
          ProfileInfoTile(
            icon: GjaIcons.badge,
            label: 'CPF',
            value: checkin.cpfFormatado,
          ),
          ProfileInfoTile(
            icon: GjaIcons.pending,
            label: 'Data/hora do check-in',
            value: checkin.dataHoraFormatada,
          ),
          ProfileInfoTile(
            icon: GjaIcons.flag,
            label: 'Status',
            value: checkin.status.label,
          ),
          // A consulta termina aqui: sem botão de liberar e sem o aviso de "não
          // autorizado", que só faria sentido diante de uma ação que não existe.
          if (widget.mode.temAcao) ...[
            SizedBox(height: AppSpacing.md),
            _buildAcao(context, checkin),
          ],
        ],
      ),
    );
  }

  /// Botão de liberação ou aviso de não autorizado — nunca os dois.
  Widget _buildAcao(BuildContext context, CheckinMotorista checkin) {
    if (!checkin.status.permitePara(widget.mode)) {
      return _buildNaoAutorizado(context, checkin);
    }

    return SignalBuilder(builder: (context) {
      final submitting =
          controller.submitStatusSignal.value == AppStatus.loading;
      return AppButton(
        label: widget.mode.acaoLabel,
        isFullWidth: true,
        isLoading: submitting,
        onPressed:
            submitting ? null : () => controller.liberar(context: context),
      );
    });
  }

  Widget _buildNaoAutorizado(BuildContext context, CheckinMotorista checkin) {
    final cs = context.colors;
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: AppBorders.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(GjaIcons.cancel, size: 20, color: cs.onErrorContainer),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Não é possível liberar a ${widget.mode.movimentoCurto}. '
              '${checkin.status.situacao}',
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
