import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../acoes_navegacao/button/gja_button.dart';
import '../../feedback_sobreposicoes/popover/gja_popover.dart';
import '../input/gja_input.dart';

/// Seletor de data, como o `sap.m.DatePicker` do SAPUI5.
///
/// O campo mostra [dateValue] no formato curto do idioma e aceita uma data
/// digitada nesse formato; o ícone de calendário (ou F4, ou Alt+seta para
/// baixo) abre um calendário mensal. É controlado: escolher um dia, ou
/// confirmar (Enter ou perda de foco) uma data válida, chama [onChange] com
/// ela, e esvaziar o campo chama `onChange(null)`; o seletor não muda
/// sozinho.
///
/// Um texto que não é data, ou que está fora de [minDate]–[maxDate], não
/// chama [onChange]: o campo fica no estado de erro até a próxima edição. No
/// calendário, os dias fora dos limites ficam desabilitados. As horas das
/// datas são ignoradas.
///
/// No cabeçalho do calendário, o mês e o ano abrem a escolha dos meses e dos
/// anos; com [showCurrentDateButton], um botão escolhe a data de hoje.
///
/// ```dart
/// GjaDatePicker(
///   semanticLabel: 'Data de entrega',
///   dateValue: entrega,
///   minDate: hoje,
///   onChange: (date) => setState(() => entrega = date),
/// )
/// ```
class GjaDatePicker extends StatefulWidget {
  /// Cria o seletor.
  const GjaDatePicker({
    this.dateValue,
    this.onChange,
    this.minDate,
    this.maxDate,
    this.placeholder,
    this.semanticLabel,
    this.enabled = true,
    this.editable = true,
    this.valueState = GjaValueState.none,
    this.valueStateText,
    this.showCurrentDateButton = false,
    super.key,
  });

  /// Data mostrada.
  final DateTime? dateValue;

  /// Chamado com a nova data, ou nulo quando o campo é esvaziado, como o
  /// evento `change` do UI5.
  final ValueChanged<DateTime?>? onChange;

  /// Primeira data aceita.
  final DateTime? minDate;

  /// Última data aceita.
  final DateTime? maxDate;

  /// Texto do campo vazio; nulo usa o padrão da data no idioma.
  final String? placeholder;

  /// Nome anunciado pelo leitor de tela; sem ele, vale o [placeholder].
  final String? semanticLabel;

  /// Se o seletor pode receber foco e edição.
  final bool enabled;

  /// Se a data pode ser mudada; `false` deixa o campo somente leitura.
  final bool editable;

  /// Estado de valor do campo; diferente de `none`, prevalece sobre o erro
  /// de uma data inválida.
  final GjaValueState valueState;

  /// Mensagem do estado de valor.
  final String? valueStateText;

  /// Se o cabeçalho do calendário tem o botão "Hoje", que escolhe a data
  /// atual.
  final bool showCurrentDateButton;

  @override
  State<GjaDatePicker> createState() => _GjaDatePickerState();
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDay(DateTime? a, DateTime? b) =>
    a != null && b != null && _day(a) == _day(b);

class _GjaDatePickerState extends State<GjaDatePicker> {
  final _popover = GjaPopoverController();

  /// Texto em edição; nulo mostra [GjaDatePicker.dateValue] formatada.
  String? _text;

  /// Se o último texto confirmado não foi uma data aceita.
  bool _invalid = false;

  @override
  void didUpdateWidget(GjaDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(oldWidget.dateValue, widget.dateValue) ||
        (oldWidget.dateValue == null) != (widget.dateValue == null)) {
      _text = null;
      _invalid = false;
    }
  }

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  bool _inRange(DateTime date) {
    final min = widget.minDate;
    final max = widget.maxDate;
    return (min == null || !date.isBefore(_day(min))) &&
        (max == null || !date.isAfter(_day(max)));
  }

  void _select(DateTime? date) {
    setState(() {
      _text = null;
      _invalid = false;
    });
    final current = widget.dateValue;
    final changed = date == null ? current != null : !_sameDay(date, current);
    if (changed) widget.onChange?.call(date);
  }

  void _confirm(String text) {
    if (text.trim().isEmpty) return _select(null);
    final date = GjaLocalizations.of(context).parseDate(text);
    if (date == null || !_inRange(date)) {
      setState(() => _invalid = true);
    } else {
      _select(date);
    }
  }

  void _open() {
    if (widget.enabled && widget.editable) _popover.open();
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.minDate;
    final max = widget.maxDate;
    assert(
      min == null || max == null || !_day(min).isAfter(_day(max)),
      'minDate não pode ser depois de maxDate',
    );
    final l10n = GjaLocalizations.of(context);
    final date = widget.dateValue;
    final placeholder = widget.placeholder ?? l10n.datePattern;
    final parentState = widget.valueState != GjaValueState.none;
    return GjaPopover(
      controller: _popover,
      semanticLabel: widget.semanticLabel ?? placeholder,
      padded: false,
      content: _Calendar(
        selected: date == null ? null : _day(date),
        minDate: min == null ? null : _day(min),
        maxDate: max == null ? null : _day(max),
        showToday: widget.showCurrentDateButton,
        onSelect: (day) {
          _popover.close();
          _select(day);
        },
      ),
      child: GjaInput(
        value: _text ?? (date == null ? '' : l10n.formatDate(date)),
        placeholder: placeholder,
        semanticLabel: widget.semanticLabel,
        enabled: widget.enabled,
        editable: widget.editable,
        valueState: parentState
            ? widget.valueState
            : (_invalid ? GjaValueState.error : GjaValueState.none),
        valueStateText: parentState
            ? widget.valueStateText
            : (_invalid ? l10n.valueState(GjaValueState.error) : null),
        showValueHelp: true,
        valueHelpIconSrc: GjaIcons.calendar,
        onValueHelpRequest: _open,
        onLiveChange: (text) => setState(() {
          _text = text;
          _invalid = false;
        }),
        onChange: _confirm,
      ),
    );
  }
}

/// Calendário mensal do seletor, como o `sap.ui.unified.Calendar`.
class _Calendar extends StatefulWidget {
  const _Calendar({
    required this.selected,
    required this.minDate,
    required this.maxDate,
    required this.showToday,
    required this.onSelect,
  });

  final DateTime? selected;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool showToday;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_Calendar> createState() => _CalendarState();
}

/// Vista do calendário: dias de um mês, os meses de um ano ou vinte anos.
enum _View { days, months, years }

class _CalendarState extends State<_Calendar> {
  final _node = FocusNode();

  /// Foco do mês ou do ano mostrado, nas escolhas de mês e de ano.
  final _pickNode = FocusNode();
  _View _view = _View.days;
  late DateTime _focused = widget.selected ?? _day(DateTime.now());
  late DateTime _month = DateTime(_focused.year, _focused.month);

  @override
  void initState() {
    super.initState();
    // Ao abrir, o foco vai ao dia escolhido (ou a hoje), e não ao primeiro
    // botão do cabeçalho.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _node.dispose();
    _pickNode.dispose();
    super.dispose();
  }

  /// Primeiro ano da escolha de anos: dez antes do ano mostrado.
  int get _firstYear => _month.year - 10;

  /// Se algum dia entre [first] e [last] está dentro dos limites.
  bool _anyEnabled(DateTime first, DateTime last) {
    final min = widget.minDate;
    final max = widget.maxDate;
    return (min == null || !last.isBefore(min)) &&
        (max == null || !first.isAfter(max));
  }

  void _showView(_View view) {
    setState(() => _view = view);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) (view == _View.days ? _node : _pickNode).requestFocus();
    });
  }

  void _step(int direction) => setState(() {
    _month = switch (_view) {
      _View.days => DateTime(_month.year, _month.month + direction),
      _View.months => DateTime(_month.year + direction, _month.month),
      _View.years => DateTime(_month.year + 20 * direction, _month.month),
    };
  });

  /// Mostra os dias de [month], com o foco no mesmo dia, limitado ao fim do
  /// mês.
  void _pickMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0).day;
    final day = DateTime(
      month.year,
      month.month,
      _focused.day > last ? last : _focused.day,
    );
    setState(() {
      _month = month;
      if (_enabled(day)) _focused = day;
    });
    _showView(_View.days);
  }

  bool _enabled(DateTime day) {
    final min = widget.minDate;
    final max = widget.maxDate;
    return (min == null || !day.isBefore(min)) &&
        (max == null || !day.isAfter(max));
  }

  void _moveFocus(DateTime day) {
    if (!_enabled(day)) return;
    setState(() {
      _focused = day;
      _month = DateTime(day.year, day.month);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final f = _focused;
    final DateTime? target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => DateTime(
        f.year,
        f.month,
        f.day + (rtl ? -1 : 1),
      ),
      LogicalKeyboardKey.arrowLeft => DateTime(
        f.year,
        f.month,
        f.day + (rtl ? 1 : -1),
      ),
      LogicalKeyboardKey.arrowDown => DateTime(f.year, f.month, f.day + 7),
      LogicalKeyboardKey.arrowUp => DateTime(f.year, f.month, f.day - 7),
      LogicalKeyboardKey.pageDown => _addMonths(f, 1),
      LogicalKeyboardKey.pageUp => _addMonths(f, -1),
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    _moveFocus(target);
    return KeyEventResult.handled;
  }

  /// [date] [months] meses depois, no último dia do mês quando ele é curto.
  static DateTime _addMonths(DateTime date, int months) {
    final last = DateTime(date.year, date.month + months + 1, 0).day;
    return DateTime(
      date.year,
      date.month + months,
      date.day > last ? last : date.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final l10n = GjaLocalizations.of(context);
    final colors = theme.colors;
    final today = _day(DateTime.now());
    final offset = (_month.weekday - l10n.firstDayOfWeek) % 7;
    final first = DateTime(_month.year, _month.month, 1 - offset);
    final weekdayStyle = theme.typography.small.copyWith(color: colors.label);

    return Padding(
      padding: EdgeInsets.all(theme.spacing.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.xs,
        children: [
          _header(context),
          if (_view == _View.months)
            _pickGrid(
              columns: 3,
              cells: [
                for (var m = 1; m <= 12; m++)
                  (
                    text: l10n.monthNames[m - 1],
                    current: m == _month.month,
                    enabled: _anyEnabled(
                      DateTime(_month.year, m),
                      DateTime(_month.year, m + 1, 0),
                    ),
                    onPress: () => _pickMonth(DateTime(_month.year, m)),
                  ),
              ],
            ),
          if (_view == _View.years)
            _pickGrid(
              columns: 4,
              cells: [
                for (var y = _firstYear; y < _firstYear + 20; y++)
                  (
                    text: l10n.formatYear(DateTime(y)),
                    current: y == _month.year,
                    enabled: _anyEnabled(DateTime(y), DateTime(y, 12, 31)),
                    onPress: () => _pickMonth(DateTime(y, _month.month)),
                  ),
              ],
            ),
          if (_view == _View.days) ...[
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final name in l10n.shortWeekdays)
                    Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: weekdayStyle,
                      ),
                    ),
                ],
              ),
            ),
            Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var week = 0; week < 6; week++)
                    Row(
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: _dayCell(
                              DateTime(
                                first.year,
                                first.month,
                                first.day + week * 7 + i,
                              ),
                              today: today,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final l10n = GjaLocalizations.of(context);
    final today = _day(DateTime.now());
    final title = theme.typography.baseBold.copyWith(color: theme.colors.text);
    return Row(
      children: [
        GjaButton(
          icon: GjaIcons.slimArrowLeft,
          tooltip: l10n.previous,
          type: GjaButtonType.transparent,
          onPress: () => _step(-1),
        ),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_view == _View.days)
                GjaButton(
                  text: l10n.monthNames[_month.month - 1],
                  type: GjaButtonType.transparent,
                  onPress: () => _showView(_View.months),
                ),
              if (_view != _View.years)
                GjaButton(
                  text: l10n.formatYear(_month),
                  type: GjaButtonType.transparent,
                  onPress: () => _showView(_View.years),
                )
              else
                Text(
                  '${l10n.formatYear(DateTime(_firstYear))} – '
                  '${l10n.formatYear(DateTime(_firstYear + 19))}',
                  style: title,
                ),
            ],
          ),
        ),
        if (widget.showToday)
          GjaButton(
            icon: GjaIcons.calendar,
            tooltip: l10n.today,
            type: GjaButtonType.transparent,
            enabled: _enabled(today),
            onPress: () => widget.onSelect(today),
          ),
        GjaButton(
          icon: GjaIcons.slimArrowRight,
          tooltip: l10n.next,
          type: GjaButtonType.transparent,
          onPress: () => _step(1),
        ),
      ],
    );
  }

  /// Grade da escolha de mês ou de ano.
  Widget _pickGrid({
    required int columns,
    required List<
      ({String text, bool current, bool enabled, VoidCallback onPress})
    >
    cells,
  }) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < cells.length; row += columns)
          Row(
            children: [
              for (final cell in cells.skip(row).take(columns))
                Expanded(
                  child: MergeSemantics(
                    child: GjaInteractable(
                      semanticLabel: cell.text,
                      selected: cell.current,
                      focusNode: cell.current ? _pickNode : null,
                      onPressed: cell.enabled ? cell.onPress : null,
                      focusRingBorderRadius: BorderRadius.circular(
                        theme.radius.field,
                      ),
                      builder: (context, states) {
                        final active =
                            states.contains(GjaInteractionState.hovered) ||
                            states.contains(GjaInteractionState.pressed);
                        return ExcludeSemantics(
                          child: Opacity(
                            opacity: theme.interaction.opacity(states),
                            child: SizedBox(
                              height: theme.density.minTargetSize,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: cell.current
                                      ? colors.brand
                                      : (active
                                            ? colors.hoverBackground
                                            : null),
                                  borderRadius: BorderRadius.circular(
                                    theme.radius.field,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    cell.text,
                                    style: theme.typography.base.copyWith(
                                      color: cell.current
                                          ? colors.contrastText
                                          : colors.text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(DateTime day, {required DateTime today}) {
    final theme = GjaThemeData.of(context);
    final colors = theme.colors;
    final l10n = GjaLocalizations.of(context);
    final selected = day == widget.selected;
    final focused = day == _focused;
    final inMonth = day.month == _month.month;
    final cell = GjaInteractable(
      semanticLabel: l10n.formatLongDate(day),
      selected: selected,
      focusNode: focused ? _node : null,
      autofocus: focused,
      onPressed: _enabled(day) ? () => widget.onSelect(day) : null,
      focusRingBorderRadius: BorderRadius.circular(theme.radius.field),
      builder: (context, states) {
        final active =
            states.contains(GjaInteractionState.hovered) ||
            states.contains(GjaInteractionState.pressed);
        final Color? background = selected
            ? colors.brand
            : (active ? colors.hoverBackground : null);
        final color = selected
            ? colors.contrastText
            : (inMonth ? colors.text : colors.label);
        return ExcludeSemantics(
          child: Opacity(
            opacity: theme.interaction.opacity(states),
            child: SizedBox(
              height: theme.density.minTargetSize,
              child: Center(
                child: SizedBox.square(
                  dimension: theme.density.minTargetSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(theme.radius.field),
                      border: day == today && !selected
                          ? Border.all(
                              color: colors.brand,
                              width: const BorderSide().width,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        l10n.formatInteger(day.day),
                        style: theme.typography.base.copyWith(color: color),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    // Foco itinerante: só o dia focado é parada de Tab.
    return MergeSemantics(child: focused ? cell : ExcludeFocus(child: cell));
  }
}
