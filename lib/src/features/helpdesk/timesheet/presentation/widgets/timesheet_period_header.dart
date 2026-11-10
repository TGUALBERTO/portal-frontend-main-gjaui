import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/timesheet_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Cabeçalho da tela de Timesheet: alterna entre as visões semanal/diária e
/// navega o período (semana ou dia, conforme a visão ativa). Tocar no rótulo
/// do período abre um calendário ([dp.WeekPicker] na visão semanal,
/// [dp.DayPicker] na diária) para pular direto para a data desejada.
class TimesheetPeriodHeader extends StatelessWidget {
  const TimesheetPeriodHeader({
    super.key,
    required this.view,
    required this.selectedDate,
    required this.periodLabel,
    required this.onViewChanged,
    required this.onDateSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final TimesheetView view;

  /// Dia selecionado (âncora da semana na visão semanal).
  final DateTime selectedDate;

  /// Rótulo do período visível (intervalo da semana ou o dia selecionado).
  final String periodLabel;
  final ValueChanged<TimesheetView> onViewChanged;

  /// Data escolhida no calendário (dia exato ou início da semana).
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  bool get _isWeekly => view == TimesheetView.semanal;

  Future<void> _openPicker(BuildContext context) async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(DateTime.now().year + 1, 12, 31);
    // 0 = domingo, casando com a semana dom→sáb do timesheet.
    final styles = dp.DatePickerRangeStyles(firstDayOfWeekIndex: 0);

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: _isWeekly
              ? dp.WeekPicker(
                  selectedDate: selectedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  datePickerStyles: styles,
                  onChanged: (period) =>
                      Navigator.of(dialogContext).pop(period.start),
                )
              : dp.DayPicker.single(
                  selectedDate: selectedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  datePickerStyles: styles,
                  onChanged: (day) => Navigator.of(dialogContext).pop(day),
                ),
        ),
      ),
    );
    if (picked != null) onDateSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final switcher = SegmentedButton<TimesheetView>(
      segments: const [
        ButtonSegment(
          value: TimesheetView.semanal,
          label: Text('Semanal'),
          icon: Icon(GjaIcons.timesheet),
        ),
        ButtonSegment(
          value: TimesheetView.diaria,
          label: Text('Diária'),
          icon: Icon(GjaIcons.appointment2),
        ),
      ],
      selected: {view},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onViewChanged(selection.first),
    );

    final navigator = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(GjaIcons.slimArrowLeft),
          tooltip: _isWeekly ? 'Semana anterior' : 'Dia anterior',
        ),
        Tooltip(
          message: _isWeekly ? 'Escolher semana' : 'Escolher dia',
          child: TextButton.icon(
            onPressed: () => _openPicker(context),
            icon: const Icon(GjaIcons.calendar, size: 18),
            label: Text(
              periodLabel,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(GjaIcons.slimArrowRight),
          tooltip: _isWeekly ? 'Próxima semana' : 'Próximo dia',
        ),
        TextButton(onPressed: onToday, child: const Text('Hoje')),
      ],
    );

    if (context.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switcher,
          SizedBox(height: AppSpacing.xs),
          Center(child: navigator),
        ],
      );
    }

    return Row(
      children: [
        switcher,
        const Spacer(),
        navigator,
      ],
    );
  }
}
