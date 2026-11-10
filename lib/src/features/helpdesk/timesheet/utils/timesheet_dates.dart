/// Helpers de data do Timesheet: semana dom→sáb e rótulos pt-BR fixos
/// (sem depender de locale/intl inicializado).
library;

const List<String> _weekdaysShort = [
  'dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb', //
];

const List<String> _monthsLong = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Data sem componente de hora.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Domingo da semana de [d] (a semana do timesheet vai de dom a sáb).
DateTime sundayOfWeek(DateTime d) {
  final day = dateOnly(d);
  // DateTime.weekday: seg=1 … dom=7 → dom recua 0 dias, seg 1, … sáb 6.
  return DateTime(day.year, day.month, day.day - (day.weekday % 7));
}

/// Soma [days] preservando "data pura" (evita aritmética com Duration).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Último instante do dia (23:59:59), para o limite superior de intervalos.
DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

/// Formato de data/hora aceito pelo backend nos query params
/// (`2019-05-06T00:00:00` — ISO local, sem milissegundos nem timezone).
String dateTimeParam(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}'
    'T${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

/// Formato de data (sem hora) aceito pelo backend nos query params de
/// `LocalDate` (`2026-07-01` — ISO).
String dateParam(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// "dom", "seg", … "sáb".
String weekdayShortPt(DateTime d) => _weekdaysShort[d.weekday % 7];

/// "qui, 10 de julho".
String dayLabelPt(DateTime d) =>
    '${weekdayShortPt(d)}, ${d.day} de ${_monthsLong[d.month - 1]}';

/// "05/07 – 11/07/2026".
String weekRangeLabel(DateTime start, DateTime end) =>
    '${_two(start.day)}/${_two(start.month)} – '
    '${_two(end.day)}/${_two(end.month)}/${end.year}';

/// "15:46".
String timeHm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// "15:46:24".
String timeHms(DateTime d) => '${timeHm(d)}:${_two(d.second)}';

/// "7h 32min" (ou "0h 00min" para zero).
String durationLabel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${_two(m)}min';
}
