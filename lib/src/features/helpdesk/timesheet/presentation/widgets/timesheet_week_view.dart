import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/catraca_acesso.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/ponto_dia.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/apontamento_acoes.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Visão semanal do Timesheet em formato agenda (estilo calendário): eixo de
/// horas à esquerda (dia completo, 00→24h), um dia por coluna (dom→sáb), os
/// períodos de presença (pares entrada→saída da catraca) como faixas suaves ao
/// fundo e os apontamentos como blocos posicionados pelo horário, com altura
/// proporcional à duração. O cabeçalho dos dias fica fixo; o corpo rola
/// verticalmente e abre posicionado nas 07:00. Tocar em um dia abre a visão
/// diária.
class TimesheetWeekView extends StatefulWidget {
  const TimesheetWeekView({
    super.key,
    required this.weekDays,
    required this.acessosPorDia,
    required this.pontosPorDia,
    required this.totaisPorDia,
    required this.apontamentosPorDia,
    required this.apontadoPorDia,
    required this.titulosChamados,
    required this.onDayTap,
    this.onApontamentoTap,
    this.onApontamentoDuplicate,
    this.onApontamentoDelete,
  });

  /// Os 7 dias da semana visível, de domingo a sábado.
  final List<DateTime> weekDays;
  final Map<DateTime, List<CatracaAcesso>> acessosPorDia;

  /// Ponto diário (primeira/última marcação do relógio de ponto) por dia.
  final Map<DateTime, PontoDia> pontosPorDia;

  final Map<DateTime, Duration> totaisPorDia;
  final Map<DateTime, List<Apontamento>> apontamentosPorDia;
  final Map<DateTime, Duration> apontadoPorDia;

  /// Títulos dos chamados (`ticketsId → titulo`), quando resolvidos.
  final Map<int, String> titulosChamados;

  final ValueChanged<DateTime> onDayTap;

  /// Abre a edicao de um apontamento ao tocar no bloco. Nulo (ou apontamento
  /// sem id) deixa o bloco apenas informativo, e o toque cai no dia.
  final ValueChanged<Apontamento>? onApontamentoTap;

  /// Duplica um apontamento (abre o formulário de criação a partir dele).
  /// Nulo esconde a ação.
  final ValueChanged<Apontamento>? onApontamentoDuplicate;

  /// Exclui um apontamento — a confirmação é de quem trata. Nulo esconde a
  /// ação.
  final ValueChanged<Apontamento>? onApontamentoDelete;

  static const double _minColumnWidth = 128;
  static const double _axisWidth = 48;
  static const double _hourHeight = 56;

  /// Largura abaixo da qual a grade da semana entra em rolagem horizontal
  /// (eixo de horas + 7 colunas no mínimo legível). Pública porque quem monta a
  /// tela decide, a partir dela, se ainda cabe o painel de chamados ao lado.
  static const double larguraMinima = _axisWidth + _minColumnWidth * 7;

  /// Faixa de horas exibida: dia completo (00:00 → 24:00).
  static const int _startHour = 0;
  static const int _endHour = 24;

  /// Hora em que a grade abre posicionada (a madrugada fica acima, rolável).
  static const int _initialHour = 7;

  /// Altura visual mínima de um bloco (apontamentos muito curtos ainda
  /// precisam ser legíveis/tocáveis).
  static const Duration _minBlockSpan = Duration(minutes: 30);

  static Duration _spanOf(Apontamento ap) =>
      ap.duration < _minBlockSpan ? _minBlockSpan : ap.duration;

  @override
  State<TimesheetWeekView> createState() => _TimesheetWeekViewState();
}

class _TimesheetWeekViewState extends State<TimesheetWeekView> {
  /// Scroll vertical do corpo da agenda, já aberto nas 07:00.
  late final ScrollController _vertical = ScrollController(
    initialScrollOffset:
        (TimesheetWeekView._initialHour - TimesheetWeekView._startHour) *
            TimesheetWeekView._hourHeight,
  );

  @override
  void dispose() {
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final needsHScroll = constraints.maxWidth <
            TimesheetWeekView._axisWidth +
                TimesheetWeekView._minColumnWidth * widget.weekDays.length;

        final grid = _buildGrid(context, fixedColumns: needsHScroll);
        // Largura fixa fica DENTRO do frame: a borda do Container soma por
        // fora, sem estourar a largura das linhas (evita overflow de 2px).
        final framed = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            border: Border.all(color: context.colors.outlineVariant),
            borderRadius: AppBorders.card,
          ),
          child: needsHScroll
              ? SizedBox(
                  width: TimesheetWeekView._axisWidth +
                      TimesheetWeekView._minColumnWidth *
                          widget.weekDays.length,
                  child: grid,
                )
              : grid,
        );

        if (!needsHScroll) return framed;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: framed,
        );
      },
    );
  }

  /// Cabeçalho fixo + corpo (eixo de horas e colunas-agenda) rolável.
  Widget _buildGrid(BuildContext context, {required bool fixedColumns}) {
    final cs = context.colors;
    final weekDays = widget.weekDays;
    const bodyHeight =
        (TimesheetWeekView._endHour - TimesheetWeekView._startHour) *
            TimesheetWeekView._hourHeight;

    Widget sized(Widget child) => fixedColumns
        ? SizedBox(width: TimesheetWeekView._minColumnWidth, child: child)
        : Expanded(child: child);

    Widget bordered(int index, Widget child) => index == 0
        ? child
        : DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: cs.outlineVariant, width: 1),
              ),
            ),
            child: child,
          );

    return Column(
      children: [
        // Cabeçalho fixo: dia da semana + totais (trabalhado / apontado).
        // IntrinsicHeight limita o `stretch` à altura do maior cabeçalho.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: TimesheetWeekView._axisWidth),
              for (var i = 0; i < weekDays.length; i++)
                sized(bordered(
                  i,
                  _DayHeader(
                    day: weekDays[i],
                    trabalhado: widget.totaisPorDia[weekDays[i]] ??
                        Duration.zero,
                    apontado:
                        widget.apontadoPorDia[weekDays[i]] ?? Duration.zero,
                    onTap: () => widget.onDayTap(weekDays[i]),
                  ),
                )),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: cs.outlineVariant),
        // Corpo rolável: eixo de horas + colunas-agenda dos dias.
        Expanded(
          child: SingleChildScrollView(
            controller: _vertical,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HourAxis(
                  startHour: TimesheetWeekView._startHour,
                  endHour: TimesheetWeekView._endHour,
                  hourHeight: TimesheetWeekView._hourHeight,
                  width: TimesheetWeekView._axisWidth,
                ),
                for (var i = 0; i < weekDays.length; i++)
                  sized(bordered(
                    i,
                    _DayAgendaColumn(
                      day: weekDays[i],
                      acessos: widget.acessosPorDia[weekDays[i]] ?? const [],
                      ponto: widget.pontosPorDia[weekDays[i]],
                      apontamentos:
                          widget.apontamentosPorDia[weekDays[i]] ?? const [],
                      titulosChamados: widget.titulosChamados,
                      startHour: TimesheetWeekView._startHour,
                      height: bodyHeight,
                      hourHeight: TimesheetWeekView._hourHeight,
                      onTap: () => widget.onDayTap(weekDays[i]),
                      onApontamentoTap: widget.onApontamentoTap,
                      onApontamentoDuplicate: widget.onApontamentoDuplicate,
                      onApontamentoDelete: widget.onApontamentoDelete,
                    ),
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Cabeçalho de um dia: "qui 10" + horas trabalhadas (catraca) e apontadas.
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.trabalhado,
    required this.apontado,
    required this.onTap,
  });

  final DateTime day;
  final Duration trabalhado;
  final Duration apontado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = day.isToday;
    final cs = context.colors;
    final tt = context.textTheme;
    final onBg = isToday ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isToday ? cs.primaryContainer : cs.surfaceContainerHigh,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Text(
              weekdayShortPt(day),
              maxLines: 1,
              style: tt.labelSmall?.copyWith(color: onBg),
            ),
            Text(
              '${day.day}',
              maxLines: 1,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isToday ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
            // Linhas sempre presentes (espaço em branco) para os cabeçalhos
            // terem a mesma altura em todas as colunas.
            Text(
              trabalhado > Duration.zero ? durationLabel(trabalhado) : ' ',
              maxLines: 1,
              style: tt.labelSmall?.copyWith(color: onBg),
            ),
            if (apontado > Duration.zero)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(GjaIcons.fobWatch,
                      size: 10, color: isToday ? onBg : cs.primary),
                  SizedBox(width: AppSpacing.xxs),
                  Text(
                    durationLabel(apontado),
                    maxLines: 1,
                    style: tt.labelSmall?.copyWith(
                      color: isToday ? onBg : cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Text(' ', maxLines: 1, style: tt.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Eixo vertical de horas ("00:00", "01:00", …).
class _HourAxis extends StatelessWidget {
  const _HourAxis({
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.width,
  });

  final int startHour;
  final int endHour;
  final double hourHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return SizedBox(
      width: width,
      height: (endHour - startHour) * hourHeight,
      child: Stack(
        children: [
          for (var h = startHour; h < endHour; h++)
            Positioned(
              top: (h - startHour) * hourHeight + 2,
              right: AppSpacing.xs,
              child: Text(
                '${h.toString().padLeft(2, '0')}:00',
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

/// Coluna-agenda de um dia: linhas de hora, faixas de presença (catraca) e
/// blocos de apontamento posicionados pelo horário.
class _DayAgendaColumn extends StatelessWidget {
  const _DayAgendaColumn({
    required this.day,
    required this.acessos,
    required this.ponto,
    required this.apontamentos,
    required this.titulosChamados,
    required this.startHour,
    required this.height,
    required this.hourHeight,
    required this.onTap,
    required this.onApontamentoTap,
    required this.onApontamentoDuplicate,
    required this.onApontamentoDelete,
  });

  final DateTime day;

  /// Marcações do dia em ordem crescente de horário.
  final List<CatracaAcesso> acessos;

  /// Ponto diário do dia (primeira/última marcação), quando sincronizado.
  final PontoDia? ponto;

  /// Apontamentos do dia em ordem crescente de horário (todos com `data`).
  final List<Apontamento> apontamentos;

  /// Títulos dos chamados (`ticketsId → titulo`), quando resolvidos.
  final Map<int, String> titulosChamados;

  final int startHour;
  final double height;
  final double hourHeight;

  /// Abre a edicao de um apontamento (nulo = bloco apenas informativo).
  final ValueChanged<Apontamento>? onApontamentoTap;

  /// Ações rápidas do bloco (hover / menu). Nulas escondem a ação.
  final ValueChanged<Apontamento>? onApontamentoDuplicate;
  final ValueChanged<Apontamento>? onApontamentoDelete;

  final VoidCallback onTap;

  DateTime get _dayStart =>
      DateTime(day.year, day.month, day.day, startHour);

  double _topOf(DateTime t) =>
      (t.difference(_dayStart).inMinutes / 60.0) * hourHeight;

  /// Pares entrada→saída sequenciais (mesma regra do total de horas do
  /// controller). Entrada sem saída correspondente fica de fora.
  List<(DateTime, DateTime)> _presenca() {
    final out = <(DateTime, DateTime)>[];
    DateTime? entrada;
    for (final acesso in acessos) {
      if (acesso.tipoAcesso.isEntrada) {
        entrada ??= acesso.data;
      } else if (entrada != null) {
        out.add((entrada, acesso.data));
        entrada = null;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isToday = day.isToday;

    // Distribui apontamentos sobrepostos em "faixas" lado a lado.
    final lanes = <int>[];
    final laneEnds = <DateTime>[];
    for (final ap in apontamentos) {
      final start = ap.data!;
      final end = start.add(TimesheetWeekView._spanOf(ap));
      var lane = -1;
      for (var i = 0; i < laneEnds.length; i++) {
        if (!laneEnds[i].isAfter(start)) {
          lane = i;
          laneEnds[i] = end;
          break;
        }
      }
      if (lane == -1) {
        laneEnds.add(end);
        lane = laneEnds.length - 1;
      }
      lanes.add(lane);
    }
    final laneCount = laneEnds.isEmpty ? 1 : laneEnds.length;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final laneWidth =
                (width - AppSpacing.xs * 2 - (laneCount - 1) * 2) / laneCount;

            return Stack(
              children: [
                if (isToday)
                  Positioned.fill(
                    child: ColoredBox(
                      color: cs.primary.withValues(alpha: 0.04),
                    ),
                  ),
                // Linhas de hora.
                for (var i = 1; i * hourHeight < height; i++)
                  Positioned(
                    top: i * hourHeight,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                // Faixas de presença (entrada→saída).
                for (final (entrada, saida) in _presenca())
                  Positioned(
                    top: _topOf(entrada).clamp(0.0, height),
                    left: 0,
                    right: 0,
                    height: (_topOf(saida) - _topOf(entrada))
                        .clamp(2.0, height - _topOf(entrada).clamp(0.0, height)),
                    child: Tooltip(
                      message:
                          'Presença: ${timeHm(entrada)} – ${timeHm(saida)}',
                      child: ColoredBox(
                        color: context.appColors.success
                            .withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                // Blocos de apontamento antes dos badges, para que um bloco
                // largo não cubra as marcações de ponto e catraca.
                for (var i = 0; i < apontamentos.length; i++)
                  _positionedBlock(
                    context,
                    apontamentos[i],
                    lane: lanes[i],
                    laneWidth: laneWidth,
                  ),
                // Badges (catraca e ponto) por último: no Stack o último filho
                // é o que aparece por cima. O `IgnorePointer` devolve o toque
                // ao bloco embaixo — sem ele o badge roubaria o clique e faria
                // o hover do bloco piscar. O horário já está escrito no badge,
                // então perder o tooltip não esconde informação.
                //
                // Badges de entrada/saída da catraca, no horário de cada
                // marcação, alinhados à esquerda.
                for (final acesso in acessos)
                  Positioned(
                    top: (_topOf(acesso.data) - 8).clamp(0.0, height - 16),
                    left: 2,
                    child: IgnorePointer(child: _AcessoBadge(acesso: acesso)),
                  ),
                // Badges do ponto (primeira/última marcação do relógio),
                // alinhados à direita para não ficarem em cima dos badges
                // dos acessos.
                if (ponto != null) ...[
                  Positioned(
                    top: (_topOf(ponto!.entrada) - 8).clamp(0.0, height - 16),
                    right: 2,
                    child: IgnorePointer(
                      child: _TimeBadge(
                        isEntrada: true,
                        horario: ponto!.entrada,
                        icon: GjaIcons.badge,
                        tooltip: 'Ponto · Entrada · ${timeHms(ponto!.entrada)}',
                      ),
                    ),
                  ),
                  if (ponto!.saida != null)
                    Positioned(
                      top: (_topOf(ponto!.saida!) - 8).clamp(0.0, height - 16),
                      right: 2,
                      child: IgnorePointer(
                        child: _TimeBadge(
                          isEntrada: false,
                          horario: ponto!.saida!,
                          icon: GjaIcons.badge,
                          tooltip: 'Ponto · Saída · ${timeHms(ponto!.saida!)}',
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _positionedBlock(
    BuildContext context,
    Apontamento ap, {
    required int lane,
    required double laneWidth,
  }) {
    final start = ap.data!;
    final span = TimesheetWeekView._spanOf(ap);
    final top = _topOf(start).clamp(0.0, height - 20);
    final blockHeight =
        ((span.inMinutes / 60.0) * hourHeight).clamp(20.0, height - top);

    return Positioned(
      top: top,
      left: AppSpacing.xs + lane * (laneWidth + 2),
      width: laneWidth,
      height: blockHeight,
      child: _AgendaBlock(
        apontamento: ap,
        titulo: titulosChamados[ap.chamadoId],
        height: blockHeight,
        // A largura da faixa decide se os ícones de ação cabem inline; sem
        // ela o bloco precisaria de um LayoutBuilder só para reler o que a
        // coluna já calculou.
        width: laneWidth,
        // Sem id nao ha o que editar (o id vem de `_links.self.href`); nesse
        // caso o toque escapa para a coluna e abre a visao diaria.
        onTap: onApontamentoTap == null || ap.id == null
            ? null
            : () => onApontamentoTap!(ap),
        onDuplicate: onApontamentoDuplicate == null || ap.id == null
            ? null
            : () => onApontamentoDuplicate!(ap),
        onDelete: onApontamentoDelete == null || ap.id == null
            ? null
            : () => onApontamentoDelete!(ap),
      ),
    );
  }
}

/// Badge de uma marcação de catraca na agenda: verde para entrada, vermelho
/// para saída (refeitório com ícone próprio), com o horário. Tooltip detalha
/// tipo, horário completo e catraca.
class _AcessoBadge extends StatelessWidget {
  const _AcessoBadge({required this.acesso});

  final CatracaAcesso acesso;

  @override
  Widget build(BuildContext context) {
    final isEntrada = acesso.tipoAcesso.isEntrada;
    return _TimeBadge(
      isEntrada: isEntrada,
      horario: acesso.data,
      icon: acesso.isRefeitorio
          ? GjaIcons.meal
          : (isEntrada ? GjaIcons.journeyArrive : GjaIcons.log),
      tooltip: [
        '${acesso.tipoAcesso.label} · ${timeHms(acesso.data)}',
        if (acesso.catraca.isNotEmpty) acesso.catraca,
      ].join('\n'),
    );
  }
}

/// Badge de horário na agenda (marcação de catraca ou de ponto): verde para
/// entrada, vermelho para saída, com ícone e horário. Tooltip com os detalhes.
class _TimeBadge extends StatelessWidget {
  const _TimeBadge({
    required this.isEntrada,
    required this.horario,
    required this.icon,
    required this.tooltip,
  });

  final bool isEntrada;
  final DateTime horario;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final cs = context.colors;
    final bg = isEntrada ? ac.success : cs.error;
    final fg = isEntrada ? ac.onSuccess : cs.onError;

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppBorders.full,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: fg),
            SizedBox(width: AppSpacing.xxs),
            Text(
              timeHm(horario),
              style: context.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloco de um apontamento na agenda: chamado + duração (e descrição quando a
/// altura permite). Tooltip com os detalhes completos.
///
/// No hover (mouse) surgem os ícones de duplicar e excluir no canto superior
/// direito, mas só quando o bloco tem espaço para eles sem cobrir o rótulo.
/// Abaixo desse limite — e no toque — as mesmas ações saem pelo menu de
/// pressão longa / botão direito, que existe em **todo** bloco.
class _AgendaBlock extends StatefulWidget {
  const _AgendaBlock({
    required this.apontamento,
    required this.titulo,
    required this.height,
    required this.width,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Apontamento apontamento;

  /// Título do chamado (nulo = não resolvido).
  final String? titulo;

  final double height;

  /// Largura da faixa (lane) ocupada: com 3 apontamentos sobrepostos numa
  /// coluna mínima sobram ~38px, e aí os ícones não cabem.
  final double width;

  /// Abre a edicao do apontamento. Como o bloco e descendente do `InkWell` da
  /// coluna, este gesto vence a arena: tocar no bloco edita, tocar no vazio do
  /// dia continua abrindo a visao diaria.
  final VoidCallback? onTap;

  /// Ações rápidas (hover e menu). Nulas escondem a ação correspondente.
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  // Medidas de hit-test dos ícones. Números crus como os demais desta agenda
  // (`_hourHeight`, `_minColumnWidth`): `AppSpacing` é escalado pelo ScreenUtil
  // e tornaria o limiar dependente do dispositivo — o oposto do que um limiar
  // precisa ser.

  /// Tamanho do glifo, igual aos ícones do `ApontamentoCard`.
  static const double _iconSize = 14;

  /// Alvo de toque de um ícone. Um `IconButton`, mesmo `VisualDensity.compact`,
  /// mede 40×40 por causa do `kMinInteractiveDimension` e não caberia aqui.
  static const double _iconBox = 18;

  /// Largura da tira das duas ações (2 ícones + 2px de respiro).
  static const double _actionsWidth = _iconBox * 2 + 2;

  /// Abaixo destes limites os ícones cobririam o rótulo. A altura mínima é a
  /// do menor bloco modelado (30 min × 56 px/h); só blocos espremidos pelo
  /// `clamp` no fim do dia ficam abaixo dela.
  static const double _minWidthForActions = 44;
  static const double _minHeightForActions = 28;

  @override
  State<_AgendaBlock> createState() => _AgendaBlockState();
}

class _AgendaBlockState extends State<_AgendaBlock> {
  bool _hovering = false;

  /// O menu rouba o ponteiro e dispara o `onExit`; sem isto os ícones sumiriam
  /// no meio da interação.
  bool _menuOpen = false;

  bool get _temAcoes => widget.onDuplicate != null || widget.onDelete != null;

  bool get _ativo => _hovering || _menuOpen;

  /// Ícones inline só onde cabem; abaixo disso sobra o menu, que vale para
  /// qualquer bloco.
  bool get _mostrarAcoesInline =>
      _temAcoes &&
      _ativo &&
      widget.width >= _AgendaBlock._minWidthForActions &&
      widget.height >= _AgendaBlock._minHeightForActions;

  Future<void> _abrirMenu(Offset globalPosition) async {
    if (!_temAcoes) return;
    final position = apontamentoMenuPosition(context, globalPosition);
    setState(() => _menuOpen = true);
    final acao = await showApontamentoMenu(
      context,
      position: position,
      podeDuplicar: widget.onDuplicate != null,
      podeExcluir: widget.onDelete != null,
    );
    // A semana pode ter recarregado com o menu aberto.
    if (!mounted) return;
    setState(() => _menuOpen = false);
    switch (acao) {
      case ApontamentoAcao.duplicar:
        widget.onDuplicate?.call();
      case ApontamentoAcao.excluir:
        widget.onDelete?.call();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ac = context.appColors;
    final tt = context.textTheme;
    final apontamento = widget.apontamento;
    final titulo = widget.titulo;
    final height = widget.height;
    final mostrarAcoes = _mostrarAcoesInline;
    final chamado = apontamento.chamadoId;
    final label = chamado != null ? '#$chamado' : 'Tarefa';
    final content = apontamento.contentPlain;
    final hora = apontamento.data!;
    final estado = apontamento.estado;
    final compact = height < 44;
    final contentLines = ((height - 48) / 16).floor().clamp(0, 3);

    // Bloco sempre azul (família `tertiary` do Fiori — par fundo/texto com
    // contraste garantido nos dois temas, imune ao override do `primary`).
    // O estado aparece como um ponto colorido: verde = concluída,
    // amarelo = pendente, nada = sem estado.
    final bg = cs.tertiaryContainer;
    final fg = cs.onTertiaryContainer;
    final Color? estadoCor = switch (estado) {
      TarefaEstado.concluida => ac.success,
      TarefaEstado.pendente => ac.warning,
      TarefaEstado.nenhum => null,
    };

    return MouseRegion(
      // Fora do Tooltip: assim o hover cobre o retângulo inteiro do bloco,
      // borda inclusive. Dentro do Container a área de padding não dispararia
      // e o cursor piscaria nas bordas.
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        // Com as ações à mostra o tooltip multilinha cobriria justamente os
        // ícones que o usuário está tentando alcançar. Mensagem vazia não
        // renderiza nada.
        message: _ativo
            ? ''
            : [
                if (chamado != null) 'Chamado #$chamado' else 'Tarefa',
                if (titulo != null && titulo.isNotEmpty) titulo,
                if (estado.label != null) 'Estado: ${estado.label}',
                'Apontado: ${durationLabel(apontamento.duration)}',
                'Horário: ${timeHm(hora)}',
                if (content.isNotEmpty) content,
              ].join('\n'),
        // Maior que o round-trip onEnter → setState → rebuild, então a
        // mensagem já está vazia quando o tooltip tentaria aparecer.
        waitDuration: AppDurations.normal,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPressStart: (d) => _abrirMenu(d.globalPosition),
          onSecondaryTapDown: (d) => _abrirMenu(d.globalPosition),
          child: AnimatedContainer(
            duration: AppDurations.microInteraction,
            curve: AppCurves.standard,
            clipBehavior: Clip.hardEdge,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppBorders.sm,
              // Hover: borda opaca + sombra mínima. Nada muda de tamanho — o
              // bloco é posicionado, e crescer desalinharia a faixa do eixo
              // de horas.
              border: Border.all(
                color: _ativo ? fg : fg.withValues(alpha: 0.35),
              ),
              boxShadow: _ativo ? AppShadows.subtle : AppShadows.none,
            ),
            // O Stack fica DENTRO do Container: o `Clip.hardEdge` recortaria
            // qualquer coisa fora dele, e uma tira que vazasse cairia sobre a
            // faixa vizinha (2px ao lado) e roubaria o hover dela.
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (estadoCor != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: estadoCor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            compact
                                ? '$label · '
                                    '${durationLabel(apontamento.duration)}'
                                : label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Reserva o espaço da tira em vez de deixá-la por
                        // cima: assim o rótulo reticencia, não fica coberto.
                        if (mostrarAcoes)
                          const SizedBox(
                            width: _AgendaBlock._actionsWidth,
                          ),
                      ],
                    ),
                    if (!compact)
                      Text(
                        durationLabel(apontamento.duration),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    // Título do chamado tem prioridade sobre o conteúdo da
                    // tarefa no espaço restante do bloco.
                    if (contentLines > 0 && (titulo?.isNotEmpty ?? false))
                      Flexible(
                        child: Text(
                          titulo!,
                          maxLines: contentLines,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(
                            color: fg.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (contentLines > 0 && content.isNotEmpty)
                      Flexible(
                        child: Text(
                          content,
                          maxLines: contentLines,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(
                            color: fg.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                  ],
                ),
                if (mostrarAcoes)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _BlockActions(
                      foreground: fg,
                      onDuplicate: widget.onDuplicate,
                      onDelete: widget.onDelete,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tira de ações do bloco (duplicar / excluir), exibida no hover.
///
/// O `GestureDetector` opaco em volta é a rede de segurança: um toque que
/// caísse no vão entre os dois ícones escaparia para o bloco e abriria a
/// edição sem querer.
class _BlockActions extends StatelessWidget {
  const _BlockActions({
    required this.foreground,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Color foreground;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Material(
        // O bloco é um Container, não um Material: o InkWell precisa deste
        // ancestral para a tinta (e para o foco de teclado, que num backoffice
        // web conta).
        type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDuplicate != null)
              _BlockActionButton(
                icon: GjaIcons.copy,
                tooltip: 'Duplicar',
                color: foreground,
                onPressed: onDuplicate!,
              ),
            if (onDuplicate != null && onDelete != null)
              SizedBox(width: AppSpacing.xxs),
            if (onDelete != null)
              _BlockActionButton(
                icon: GjaIcons.delete,
                tooltip: 'Excluir',
                color: context.colors.error,
                onPressed: onDelete!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Botão de ação do bloco, menor que qualquer `IconButton` (que tem piso de
/// 40×40 pelo `kMinInteractiveDimension`) — é o que permite caber numa faixa
/// estreita da agenda.
class _BlockActionButton extends StatelessWidget {
  const _BlockActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      // O tooltip do bloco está suprimido durante o hover, então este é o
      // único que aparece.
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppBorders.xs,
        child: SizedBox(
          width: _AgendaBlock._iconBox,
          height: _AgendaBlock._iconBox,
          child: Icon(icon, size: _AgendaBlock._iconSize, color: color),
        ),
      ),
    );
  }
}
