import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_nf_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/itens_nota/presentation/widgets/item_nota_card.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_app_bar.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_banner.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_footer.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/widgets/contagem_tag.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/wrappers/base_state_wrapper.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Itens de uma NF-e. Cada linha pendente é uma contagem a fazer; as demais
/// ficam só como registro do que já foi conferido.
///
/// Quando a nota é condenada à devolução os itens que sobraram aparecem
/// **bloqueados**: contá-los não mudaria o desfecho, já que a carga volta
/// inteira ao fornecedor.
class ItensNotaScreen extends StatefulWidget {
  const ItensNotaScreen({super.key, required this.notaIndex});

  /// Índice da nota na sessão — vem do path, para a URL refletir onde o
  /// conferente está.
  final int notaIndex;

  @override
  State<ItensNotaScreen> createState() => _ItensNotaScreenState();
}

class _ItensNotaScreenState
    extends BaseState<ItensNotaScreen, ContagemCegaController> {
  @override
  void initState() {
    super.initState();
    // Deep-link/refresh: a nota da URL manda, senão a tela mostraria a nota que
    // ficou selecionada na sessão. Só o índice — `initState` roda durante o
    // build e escrever signal aqui quebra o app.
    controller.sincronizarRota(nota: widget.notaIndex);
  }

  void _abrirItem(int index) {
    controller.abrirItem(index);
    context.go(
      AppRoutes.gjaautoInboundContagemCegaContagemPath(
        widget.notaIndex,
        index,
      ),
    );
  }

  void _escanearProximo() {
    final proximo = controller.proximoItemPendente;
    if (proximo < 0) return;
    _abrirItem(proximo);
  }

  void _voltarParaNotas() =>
      context.go(AppRoutes.gjaautoInboundContagemCegaNotas);

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final nota = controller.notaAtual;
      final checkin = controller.checkinSignal.value ?? '—';
      final mensagem = controller.mensagemSignal.value;

      if (nota == null) {
        return Scaffold(
          appBar: ContagemAppBar(
            kicker: 'Check-in $checkin',
            titulo: 'Itens',
            onVoltar: _voltarParaNotas,
          ),
          body: AppEmptyState(
            icon: GjaIcons.inventory,
            title: 'Nota não encontrada',
            subtitle: 'Volte à lista e selecione uma nota fiscal.',
            actionLabel: 'Voltar às notas',
            onAction: _voltarParaNotas,
          ),
        );
      }

      final devolver = nota.status == ContagemNfStatus.devolver;
      final temPendente = !devolver && nota.primeiroItemPendente >= 0;

      return Scaffold(
        appBar: ContagemAppBar(
          kicker: 'Check-in $checkin · ${nota.fornecedor}',
          titulo: 'NF-e ${nota.numero}',
          trailing: devolver ? ContagemTag.nota(nota.status) : null,
          onVoltar: _voltarParaNotas,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mensagem != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.ms,
                    AppSpacing.ms,
                    AppSpacing.ms,
                    0,
                  ),
                  child: ContagemBanner(mensagem: mensagem),
                ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.ms,
                  ),
                  itemCount: nota.itens.length,
                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = nota.itens[index];
                    final pendente =
                        item.status == ContagemItemStatus.pendente;
                    final bloqueado = devolver && pendente;
                    return ItemNotaCard(
                      item: item,
                      bloqueado: bloqueado,
                      // Só item pendente de nota viva é contável.
                      onTap: pendente && !bloqueado
                          ? () => _abrirItem(index)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: ContagemFooter(
          children: [
            if (temPendente)
              AppButton(
                label: 'Escanear material',
                height: ButtonSize.large,
                isFullWidth: true,
                prefixIcon: const Icon(GjaIcons.barCode),
                onPressed: _escanearProximo,
              )
            else
              AppButton(
                label: 'Voltar às notas',
                variant: ButtonVariant.outline,
                isFullWidth: true,
                onPressed: _voltarParaNotas,
              ),
          ],
        ),
      );
    });
  }
}
