import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado_resumo.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/meus_chamados_controller.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/chamado_detalhe_sheet.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/chamado_resumo_card.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/meus_chamados_filter_bar.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Painel lateral do Timesheet com os chamados do usuário logado.
///
/// Independente da navegação de semana/dia do Timesheet: o período aqui é o de
/// **abertura** do chamado, porque quem aponta horas normalmente o faz em
/// chamados abertos há semanas — amarrar à semana exibida esconderia justamente
/// esses.
///
/// Não define a própria largura: quem monta (coluna à direita no desktop,
/// gaveta no mobile) é que decide, e o painel se adapta.
class MeusChamadosPanel extends StatefulWidget {
  const MeusChamadosPanel({super.key, required this.onApontar});

  /// Abre o formulário de apontamento com este chamado já selecionado.
  final ValueChanged<ChamadoResumo> onApontar;

  @override
  State<MeusChamadosPanel> createState() => _MeusChamadosPanelState();
}

class _MeusChamadosPanelState extends State<MeusChamadosPanel> {
  final _controller = AppInjector.get<MeusChamadosController>();

  @override
  void initState() {
    super.initState();
    // Só na primeira montagem: reabrir a gaveta no mobile não deve descartar a
    // lista já carregada nem a posição de rolagem.
    if (_controller.statusSignal.peek().isInitial) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _controller.load());
    }
  }

  Future<void> _abrirDetalhe(ChamadoResumo chamado) async {
    final apontar = await showAppSheet<bool>(
      child: ChamadoDetalheSheet(chamado: chamado),
    );
    if (apontar ?? false) widget.onApontar(chamado);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Cabecalho(controller: _controller),
        SizedBox(height: AppSpacing.sm),
        MeusChamadosFilterBar(controller: _controller),
        SizedBox(height: AppSpacing.sm),
        Expanded(
          child: SignalBuilder(builder: (context) {
            final status = _controller.statusSignal.value;
            final itens = _controller.chamadosSignal.value;

            if (itens.isEmpty && (status.isInitial || status.isLoading)) {
              return const AppLoading();
            }
            if (itens.isEmpty && status.isFailure) {
              return _Falha(controller: _controller);
            }
            if (itens.isEmpty) {
              return const AppEmptyState(
                icon: GjaIcons.incident,
                title: 'Nenhum chamado',
                subtitle: 'Ajuste os filtros ou amplie o período para ver mais.',
              );
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                // Antecipa a próxima página antes de o usuário bater no fim; o
                // controller ignora chamadas concorrentes ou já esgotadas.
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
                  _controller.carregarMais();
                }
                return false;
              },
              child: ListView.separated(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                itemCount: itens.length + 1,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == itens.length) {
                    return _Rodape(controller: _controller);
                  }
                  final chamado = itens[index];
                  return ChamadoResumoCard(
                    chamado: chamado,
                    onTap: () => _abrirDetalhe(chamado),
                    onApontar: () => widget.onApontar(chamado),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Título do painel + total encontrado + recarregar.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.controller});

  final MeusChamadosController controller;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Row(
      children: [
        Expanded(
          child: SignalBuilder(builder: (context) {
            final total = controller.totalElementosSignal.value;
            final carregado = controller.chamadosSignal.value.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meus chamados',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (total > 0)
                  Text(
                    carregado < total
                        ? '$carregado de $total'
                        : '$total ${total == 1 ? 'chamado' : 'chamados'}',
                    style: tt.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
              ],
            );
          }),
        ),
        IconButton(
          onPressed: controller.load,
          tooltip: 'Atualizar chamados',
          icon: const Icon(GjaIcons.refresh, size: 20),
        ),
      ],
    );
  }
}

/// Erro sem nenhum dado na tela. Um 404 aqui não é falha do usuário: significa
/// que o módulo de helpdesk não está habilitado no ambiente.
class _Falha extends StatelessWidget {
  const _Falha({required this.controller});

  final MeusChamadosController controller;

  @override
  Widget build(BuildContext context) {
    final failure = controller.errorSignal.value;
    if (failure is ApiFailure && failure.isNotFound) {
      return const AppEmptyState(
        icon: GjaIcons.disconnected,
        title: 'Chamados indisponíveis',
        subtitle: 'A integração com o helpdesk não está ativa neste ambiente.',
      );
    }
    return AppErrorWidget(
      message: failure?.message,
      onRetry: controller.load,
    );
  }
}

/// Rodapé da lista: progresso da próxima página, ou o botão para quem prefere
/// tocar a rolar.
class _Rodape extends StatelessWidget {
  const _Rodape({required this.controller});

  final MeusChamadosController controller;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) {
      if (controller.carregandoMaisSignal.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      if (!controller.temMaisSignal.value) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(top: AppSpacing.sm),
        child: Center(
          child: TextButton(
            onPressed: controller.carregarMais,
            child: const Text('Carregar mais'),
          ),
        ),
      );
    });
  }
}
