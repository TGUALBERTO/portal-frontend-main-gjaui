import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;

import '../../imports/imports.dart';

/// Abre o seletor de intervalo de datas e devolve o período escolhido, ou
/// `null` se o usuário cancelar.
///
/// O `RangePicker` só notifica a seleção parcial enquanto o usuário clica, por
/// isso o estado vive num `StatefulBuilder` e só vira resultado no "Aplicar" —
/// sem isso, o primeiro clique (que zera o fim do período) já fecharia o
/// diálogo com um intervalo de um dia.
Future<dp.DatePeriod?> pickDatePeriod(
  BuildContext context, {
  DateTime? inicio,
  DateTime? fim,
  DateTime? primeiraData,
  DateTime? ultimaData,
}) {
  final agora = DateTime.now();
  var periodo = (inicio != null && fim != null)
      ? dp.DatePeriod(inicio, fim)
      : dp.DatePeriod(DateTime(agora.year, agora.month, 1), agora);

  return showDialog<dp.DatePeriod>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('Selecione o período'),
        content: SizedBox(
          width: 320,
          height: 360,
          child: dp.RangePicker(
            selectedPeriod: periodo,
            firstDate: primeiraData ?? DateTime(agora.year - 3),
            lastDate: ultimaData ?? agora,
            onChanged: (p) => setDialog(() => periodo = p),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, periodo),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    ),
  );
}
