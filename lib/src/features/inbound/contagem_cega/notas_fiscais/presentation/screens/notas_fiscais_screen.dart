import 'package:gjamobile/src/features/inbound/contagem_cega/notas_fiscais/presentation/widgets/nota_fiscal_card.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/utils/avisar_falha.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_app_bar.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_footer.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_tag.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/wrappers/base_state_wrapper.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Notas fiscais do check-in lido. Ponto de retorno do fluxo: toda contagem
/// conferida ou devolvida volta para cá.
class NotasFiscaisScreen extends StatefulWidget {
  const NotasFiscaisScreen({super.key});

  @override
  State<NotasFiscaisScreen> createState() => _NotasFiscaisScreenState();
}

class _NotasFiscaisScreenState
    extends BaseState<NotasFiscaisScreen, ContagemCegaController> {
  /// Abrir a nota é o que cria o cabeçalho da contagem no SAP e traz o que já
  /// foi contado. Bloqueia até terminar: entrar sem cabeçalho deixaria o log
  /// órfão, e entrar sem o histórico faria o conferente recontar o que já
  /// estava conferido.
  Future<void> _abrirNota(int index) async {
    final abriu = await controller.abrirNota(index);
    if (!mounted) return;
    if (!abriu) {
      avisarFalhaContagem(
        context,
        controller.erroSapSignal.value,
        controller.configErrorSignal.value,
      );
      return;
    }
    context.go(AppRoutes.gjaautoInboundContagemCegaItensPath(index));
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final notas = controller.notasSignal.value;
      final checkin = controller.checkinSignal.value ?? '—';
      final abrindo = controller.abrindoNotaSignal.value;

      return Scaffold(
        appBar: ContagemAppBar(
          kicker: 'Check-in $checkin',
          titulo: 'Notas fiscais',
          trailing: ContagemTag(
            label: '${notas.length} NFs',
            variante: ContagemTagVariante.contorno,
          ),
          // Sair daqui é abandonar a conferência: volta para a leitura do
          // check-in, não para a tela anterior do histórico.
          onVoltar: () => context.go(AppRoutes.gjaautoInboundContagemCega),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              if (notas.isEmpty)
                const AppEmptyState(
                  icon: GjaIcons.receipt,
                  title: 'Nenhuma nota fiscal',
                  subtitle: 'Este check-in não tem notas para conferir.',
                )
              else
                ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.ms,
                  ),
                  itemCount: notas.length,
                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => NotaFiscalCard(
                    nota: notas[index],
                    // `null` some com o ripple e com o toque: enquanto o SAP
                    // responde, tocar outra nota trocaria a conferência por
                    // baixo da chamada em curso.
                    onTap: abrindo ? null : () => _abrirNota(index),
                  ),
                ),
              if (abrindo)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: AppLoading(),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: ContagemFooter(
          children: [
            AppButton(
              label: 'Resumo do Check-in',
              variant: ButtonVariant.outline,
              isFullWidth: true,
              // Sair no meio da abertura deixaria o cabeçalho criado e a nota
              // sem reidratar.
              onPressed: abrindo
                  ? null
                  : () => context.go(AppRoutes.gjaautoInboundContagemCegaResumo),
            ),
          ],
        ),
      );
    });
  }
}
