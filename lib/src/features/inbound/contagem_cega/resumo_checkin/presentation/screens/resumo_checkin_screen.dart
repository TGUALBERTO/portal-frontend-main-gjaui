import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/utils/avisar_falha.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_app_bar.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_footer.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/resumo_checkin/presentation/widgets/checkin_finalizado_panel.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/resumo_checkin/presentation/widgets/resumo_nota_card.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/wrappers/base_state_wrapper.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Fecho do check-in: o desfecho de cada NF-e e o botão de finalizar, liberado
/// só quando nenhuma nota está pendente.
class ResumoCheckinScreen extends StatefulWidget {
  const ResumoCheckinScreen({super.key});

  @override
  State<ResumoCheckinScreen> createState() => _ResumoCheckinScreenState();
}

class _ResumoCheckinScreenState
    extends BaseState<ResumoCheckinScreen, ContagemCegaController> {
  void _voltarParaNotas() =>
      context.go(AppRoutes.gjaautoInboundContagemCegaNotas);

  void _novoCheckin() {
    controller.reiniciar();
    context.go(AppRoutes.gjaautoInboundContagemCega);
  }

  /// Grava o fecho no SAP. Falhou, a tela **fica** — o toast diz o motivo e o
  /// próprio botão é o retry, do mesmo jeito que na tela de contagem.
  Future<void> _finalizar() async {
    final ok = await controller.finalizar();
    if (!mounted || ok) return;
    avisarFalhaContagem(
      context,
      controller.erroSapSignal.value,
      controller.configErrorSignal.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final checkin = controller.checkinSignal.value ?? '—';
      final finalizado = controller.finalizadoSignal.value;

      return Scaffold(
        appBar: ContagemAppBar(
          kicker: 'Check-in $checkin',
          titulo: 'Resumo',
          // Finalizado o check-in não há mais conferência para onde voltar — a
          // única saída é começar outro.
          showBackButton: !finalizado,
          onVoltar: _voltarParaNotas,
        ),
        body: SafeArea(
          child: finalizado
              ? CheckinFinalizadoPanel(
                  checkin: checkin,
                  resumo: controller.resumoFinalSignal.value,
                  onNovoCheckin: _novoCheckin,
                )
              : _buildConferencia(context),
        ),
        bottomNavigationBar:
            finalizado ? null : _buildRodape(context),
      );
    });
  }

  Widget _buildConferencia(BuildContext context) {
    final notas = controller.notasSignal.value;

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      // +1 pela nota de rodapé que explica a regra da devolução integral.
      itemCount: notas.length + 1,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == notas.length) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Notas com item divergente após '
              '${ContagemCegaController.maxTentativas} tentativas retornam '
              'integralmente ao fornecedor.',
              style: context.textTheme.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          );
        }
        return ResumoNotaCard(nota: notas[index]);
      },
    );
  }

  Widget _buildRodape(BuildContext context) {
    return SignalBuilder(builder: (context) {
      // Cabeçalho da contagem já em 'C'/'D': o SAP fechou este check-in — outro
      // coletor finalizou, ou esta sessão finalizou e o coletor caiu antes de a
      // tela trocar pelo painel. Finalizar de novo mandaria um segundo
      // `IN100FinalizaCC` para o mesmo caminhão.
      final jaFinalizado = controller.checkinJaFinalizadoSignal.value;
      final liberado = controller.todasResolvidasSignal.value && !jaFinalizado;
      final gravando = controller.gravandoSignal.value;

      return ContagemFooter(
        children: [
          if (jaFinalizado) ...[
            // Acima do botão, não no lugar dele: o botão desabilitado sozinho
            // não diz por quê, e na doca "não clica" vira chamado para o
            // suporte. O texto explica e a única saída é 'Novo Check-in'.
            _AvisoJaFinalizado(situacao: controller.situacaoContagem),
            SizedBox(height: AppSpacing.sm),
          ],
          AppButton(
            label: _rotuloBotao(
              liberado: liberado,
              jaFinalizado: jaFinalizado,
            ),
            height: ButtonSize.large,
            isFullWidth: true,
            variant: liberado ? ButtonVariant.primary : ButtonVariant.outline,
            isLoading: gravando,
            // Finalizar é escrita no SAP: enquanto o MERGE não volta, o botão
            // trava. Duplo toque aqui mandaria dois MERGE do mesmo status —
            // inofensivo no dado, mas o segundo poderia falhar e a tela diria
            // que não finalizou depois de ter finalizado.
            onPressed: liberado && !gravando ? _finalizar : null,
          ),
          if (jaFinalizado) ...[
            SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Novo Check-in',
              height: ButtonSize.large,
              isFullWidth: true,
              variant: ButtonVariant.outline,
              onPressed: _novoCheckin,
            ),
          ],
        ],
      );
    });
  }

  /// O rótulo diz o **motivo** da trava, e o de já-finalizado ganha do de itens
  /// pendentes: um check-in fechado no SAP com nota pendente aqui não se
  /// resolve contando o que falta.
  String _rotuloBotao({required bool liberado, required bool jaFinalizado}) {
    if (jaFinalizado) return 'Check-in já finalizado';
    if (liberado) return 'Finalizar Check-in';
    return 'Finalizar Check-in — itens pendentes';
  }
}

/// Faixa que explica por que o botão de finalizar está travado.
class _AvisoJaFinalizado extends StatelessWidget {
  const _AvisoJaFinalizado({required this.situacao});

  final String situacao;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.ms,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: AppBorders.sm,
        border: Border.all(color: cs.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(GjaIcons.locked, size: 18, color: cs.onErrorContainer),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              situacao.isEmpty
                  ? 'Este check-in já foi finalizado no SAP.'
                  : situacao,
              style: context.textTheme.bodySmall
                  ?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
