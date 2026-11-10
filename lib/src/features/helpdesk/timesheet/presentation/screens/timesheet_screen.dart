import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado_resumo.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/timesheet_controller.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/apontamento_acoes.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/apontamento_form_sheet.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/meus_chamados_panel.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/timesheet_day_view.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/timesheet_period_header.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/timesheet_week_view.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/wrappers/base_state_wrapper.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Timesheet: histórico de catraca (por matrícula) e apontamentos de tarefas
/// em chamados (por usuário GLPI, resolvido do e-mail), nas visões semanal e
/// diária. As duas fontes são independentes: uma pode faltar/falhar sem
/// derrubar a outra.
class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState
    extends BaseState<TimesheetScreen, TimesheetController> {
  @override
  void onReady() => controller.load();

  /// Abre o formulário de novo apontamento; na visão semanal o formulário
  /// ganha o campo "Dia" (limitado à semana exibida), na diária o dia é o
  /// selecionado. No sucesso mostra o toast e recarrega a semana.
  Future<void> _novoApontamento() =>
      _abrirFormulario(day: controller.selectedDateSignal.value);

  /// Abre o mesmo formulário em modo de edição, no dia do próprio apontamento.
  Future<void> _editarApontamento(Apontamento apontamento) => _abrirFormulario(
        day: apontamento.inicio ?? controller.selectedDateSignal.value,
        apontamento: apontamento,
        tituloChamado:
            controller.titulosChamadosSignal.value[apontamento.chamadoId],
      );

  /// Duplica um apontamento: abre o **mesmo formulário em modo de criação**,
  /// com o chamado travado e horário/descrição já preenchidos a partir do
  /// original — o usuário só troca o dia e salva.
  ///
  /// Criar direto colocaria o bloco novo exatamente em cima do original, que
  /// teria de ser editado em seguida de qualquer forma.
  Future<void> _duplicarApontamento(Apontamento apontamento) async {
    // O apontamento só carrega o `ticketsId` do GLPI; o POST exige o UUID do
    // portal, que veio junto dos títulos no `load()`.
    final chamado = controller.chamadoDe(apontamento.chamadoId);
    if (chamado == null) {
      showToast(
        context,
        message: 'Não foi possível identificar o chamado deste apontamento.',
        status: 'error',
      );
      return;
    }
    await _abrirFormulario(
      day: apontamento.inicio ?? controller.selectedDateSignal.value,
      chamadoPreSelecionado: chamado,
      modelo: apontamento,
    );
  }

  /// Exclui um apontamento direto da agenda, com a mesma confirmação (e o mesmo
  /// texto) do botão dentro do formulário.
  Future<void> _excluirApontamento(Apontamento apontamento) async {
    final id = apontamento.id;
    if (id == null) return;
    final confirmado = await confirmarExclusaoApontamento(context);
    if (!confirmado || !mounted) return;

    final error = await controller.excluirApontamento(id: id);
    if (!mounted) return;
    showToast(
      context,
      message: error ?? 'Apontamento excluído',
      status: error == null ? 'success' : 'error',
    );
    if (error == null) controller.load();
  }

  /// Apontamento a partir do painel de chamados: o chamado vem da lista, mas o
  /// dia continua sendo o selecionado no Timesheet — é lá que as horas entram.
  Future<void> _apontarPara(ChamadoResumo chamado) => _abrirFormulario(
        day: controller.selectedDateSignal.value,
        chamadoPreSelecionado: chamado.toChamado(),
      );

  /// Formulário de apontamento (criação ou edição). No sucesso mostra o toast
  /// do que aconteceu e recarrega a semana; fechar sem salvar não faz nada.
  Future<void> _abrirFormulario({
    required DateTime day,
    Apontamento? apontamento,
    String? tituloChamado,
    Chamado? chamadoPreSelecionado,
    Apontamento? modelo,
  }) async {
    final isWeekly = controller.viewSignal.value == TimesheetView.semanal;
    final resultado = await showAppSheet<ApontamentoFormResult>(
      child: ApontamentoFormSheet(
        day: day,
        weekDays: isWeekly ? controller.weekDaysSignal.value : null,
        apontamento: apontamento,
        tituloChamado: tituloChamado,
        chamadoPreSelecionado: chamadoPreSelecionado,
        modelo: modelo,
      ),
    );
    if (resultado == null || !mounted) return;
    showToast(
      context,
      message: switch (resultado) {
        ApontamentoFormResult.criado => 'Apontamento criado',
        ApontamentoFormResult.atualizado => 'Apontamento atualizado',
        ApontamentoFormResult.excluido => 'Apontamento excluído',
      },
      status: 'success',
    );
    controller.load();
  }

  /// Largura do painel de chamados: um terço do espaço disponível, entre 320 e
  /// 460 px. Largura fixa desperdiça a tela em monitor largo e espreme a agenda
  /// (7 colunas) em tela média; o piso mantém o card legível e o teto impede que
  /// o painel roube espaço da agenda, que é o conteúdo principal.
  static double _larguraPainel(double disponivel) =>
      (disponivel / 3).clamp(320.0, 460.0);

  /// Espaço entre a agenda e o painel (respiro + divisória + respiro).
  static double get _calhaPainel => AppSpacing.md * 2 + 1;

  /// O painel só fica lado a lado quando **sobra** largura para a agenda depois
  /// de descontá-lo.
  ///
  /// O piso de 320 px de [_larguraPainel] não cede: em `expanded` (a partir de
  /// 840 px, onde `isDesktop` já é true) ele consumia ~350 px dos ~776
  /// disponíveis e deixava a agenda com ~425 — menos da metade dos
  /// `48 + 128×7 = 944` px que as 7 colunas exigem, então a semana inteira caía
  /// na rolagem horizontal enquanto o painel seguia inteiro ao lado. Era o
  /// painel parecendo grande demais: ele não crescia, só se recusava a encolher.
  ///
  /// Abaixo desse limite o painel volta para a gaveta, como já acontece no
  /// mobile — a agenda é o conteúdo principal e fica com a tela toda.
  static bool _cabeLadoALado(double disponivel) {
    final restante =
        disponivel - _larguraPainel(disponivel) - _calhaPainel;
    return restante >= TimesheetWeekView.larguraMinima;
  }

  /// Mesma pergunta de [_cabeLadoALado], respondida fora do `LayoutBuilder`
  /// (barra de título e gaveta são montadas antes dele). O corpo é a largura da
  /// janela menos o padding horizontal da página, que é o que o `AppPageScaffold`
  /// desconta — manter as duas respostas iguais é o que evita a tela sem painel
  /// e sem botão para abri-lo.
  static bool _painelLadoALado(BuildContext context) =>
      _cabeLadoALado(context.width - context.pagePadding * 2);

  @override
  Widget build(BuildContext context) {
    // Sem teto de largura: o timesheet é uma agenda de 7 colunas com um painel
    // ao lado, e o limite padrão (até 1440) deixaria faixas mortas nas bordas em
    // monitor largo. O pagePadding responsivo continua dando o respiro lateral.
    return AppPageScaffold(
      scrollable: false,
      maxContentWidth: double.infinity,
      // Em telas estreitas o painel não cabe ao lado: vira gaveta, aberta pelo
      // botão da barra de título.
      endDrawer: _painelLadoALado(context)
          ? null
          : Drawer(
              // Em telas estreitas a gaveta ocupa quase tudo; no tablet fica no
              // mesmo corpo do painel do desktop.
              width: (context.width * 0.86).clamp(300.0, 420.0),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: MeusChamadosPanel(onApontar: _apontarPara),
                ),
              ),
            ),
      // FAB só com matrícula vinculada (mesmo gate do corpo da tela).
      floatingActionButton: SignalBuilder(builder: (context) {
        if (controller.matricula == null) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: _novoApontamento,
          tooltip: 'Novo apontamento',
          child: const Icon(GjaIcons.add),
        );
      }),
      appBar: AppTopBar(
        title: 'Timesheet',
        actions: [
          if (!_painelLadoALado(context))
            Builder(
              builder: (context) => IconButton(
                onPressed: Scaffold.of(context).openEndDrawer,
                tooltip: 'Meus chamados',
                icon: const Icon(GjaIcons.incident),
              ),
            ),
          IconButton(
            onPressed: controller.load,
            tooltip: 'Atualizar',
            icon: const Icon(GjaIcons.refresh),
          ),
        ],
      ),
      body: SignalBuilder(builder: (context) {
        final status = controller.statusSignal.value;

        // Já resolvido (não está carregando) e sem nenhuma fonte de dados:
        // conta sem matrícula (catraca) e sem usuário no helpdesk
        // (apontamentos). O vínculo via KBA, quando aplicável, já é forçado
        // pelo redirect global do router antes de chegar aqui.
        final hasMatricula = controller.matricula != null;
        final hasUsuario = controller.usuarioId != null;
        if (!status.isInitial &&
            !status.isLoading &&
            !hasMatricula &&
            !hasUsuario) {
          if (status.isFailure) {
            return AppErrorWidget(
              message: controller.errorSignal.value?.message,
              onRetry: controller.load,
            );
          }
          return const AppEmptyState(
            icon: GjaIcons.badge,
            title: 'Sem dados de timesheet',
            subtitle: 'Sua conta não tem matrícula funcional vinculada nem '
                'usuário no helpdesk. Procure o suporte para habilitar.',
          );
        }

        final view = controller.viewSignal.value;
        final selectedDay = controller.selectedDateSignal.value;
        final weekDays = controller.weekDaysSignal.value;
        final isWeekly = view == TimesheetView.semanal;
        final partialError = controller.partialErrorSignal.value;

        final Widget content;
        if (status.isInitial || status.isLoading) {
          content = const AppLoading();
        } else if (status.isFailure) {
          content = AppErrorWidget(
            message: controller.errorSignal.value?.message,
            onRetry: controller.load,
          );
        } else if (isWeekly) {
          content = TimesheetWeekView(
            weekDays: weekDays,
            acessosPorDia: controller.acessosPorDiaSignal.value,
            pontosPorDia: controller.pontosPorDiaSignal.value,
            totaisPorDia: controller.totaisPorDiaSignal.value,
            apontamentosPorDia: controller.apontamentosPorDiaSignal.value,
            apontadoPorDia: controller.apontadoPorDiaSignal.value,
            titulosChamados: controller.titulosChamadosSignal.value,
            onDayTap: controller.openDay,
            onApontamentoTap: _editarApontamento,
            onApontamentoDuplicate: _duplicarApontamento,
            onApontamentoDelete: _excluirApontamento,
          );
        } else {
          content = TimesheetDayView(
            day: selectedDay,
            acessos: controller.acessosDoDiaSignal.value,
            total: controller.totaisPorDiaSignal.value[selectedDay] ??
                Duration.zero,
            apontamentos: controller.apontamentosDoDiaSignal.value,
            apontado: controller.apontadoPorDiaSignal.value[selectedDay] ??
                Duration.zero,
            titulosChamados: controller.titulosChamadosSignal.value,
            onRefresh: controller.load,
            onApontamentoTap: _editarApontamento,
            onApontamentoDuplicate: _duplicarApontamento,
            onApontamentoDelete: _excluirApontamento,
          );
        }

        // O header fica fora do switch de status para a navegação de semana/
        // dia continuar acessível enquanto a busca está em andamento.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TimesheetPeriodHeader(
              view: view,
              selectedDate: selectedDay,
              periodLabel: isWeekly
                  ? weekRangeLabel(weekDays.first, weekDays.last)
                  : dayLabelPt(selectedDay),
              onViewChanged: (v) => controller.view = v,
              onDateSelected: controller.selectDate,
              onPrevious:
                  isWeekly ? controller.previousWeek : controller.previousDay,
              onNext: isWeekly ? controller.nextWeek : controller.nextDay,
              onToday: controller.goToToday,
            ),
            SizedBox(height: AppSpacing.sm),
            if (partialError != null) ...[
              _PartialErrorBanner(
                message: partialError.message,
                onRetry: controller.load,
              ),
              SizedBox(height: AppSpacing.sm),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // A decisão vem da largura real do corpo (já sem o padding da
                  // página), não do breakpoint: é ela que a agenda e o painel
                  // dividem de fato.
                  if (!_cabeLadoALado(constraints.maxWidth)) {
                    return content;
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: content),
                      SizedBox(width: AppSpacing.md),
                      const VerticalDivider(width: 1),
                      SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: _larguraPainel(constraints.maxWidth),
                        child: MeusChamadosPanel(onApontar: _apontarPara),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Aviso não-bloqueante: uma das fontes (catraca/apontamentos) falhou, mas a
/// outra carregou. Mostra a mensagem e um botão para tentar de novo.
class _PartialErrorBanner extends StatelessWidget {
  const _PartialErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(GjaIcons.warning,
              size: 20, color: cs.onErrorContainer),
          SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Text(
              'Parte dos dados não carregou: $message',
              style: context.textTheme.bodySmall
                  ?.copyWith(color: cs.onErrorContainer),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: cs.onErrorContainer),
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}
