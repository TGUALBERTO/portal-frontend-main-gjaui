import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/catraca_acesso.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/ponto_dia.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/timesheet_week_view.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme_constants.dart';

CatracaAcesso _acesso(DateTime data, {bool entrada = true}) => CatracaAcesso(
      origemId: data.millisecondsSinceEpoch,
      data: data,
      tipoAcesso: entrada ? TipoAcesso.entrada : TipoAcesso.saida,
      matricula: '28109',
      nome: 'Fulano',
      cargo: '',
      lotacao: '',
      catraca: 'Catraca Portaria 1',
      idCatraca: 1,
    );

void main() {
  // Semana real dos logs: dom 05/07 → sáb 11/07/2026.
  final weekDays =
      List.generate(7, (i) => DateTime(2026, 7, 5 + i));
  final d09 = DateTime(2026, 7, 9);
  final d10 = DateTime(2026, 7, 10);

  final acessosPorDia = {
    d09: [
      _acesso(DateTime(2026, 7, 9, 9, 27)),
      _acesso(DateTime(2026, 7, 9, 12, 54), entrada: false),
      _acesso(DateTime(2026, 7, 9, 13, 10)),
      _acesso(DateTime(2026, 7, 9, 18, 56), entrada: false),
    ],
    d10: [
      _acesso(DateTime(2026, 7, 9, 8, 12)),
      _acesso(DateTime(2026, 7, 10, 18, 14), entrada: false),
    ],
  };
  // Ponto diário (relógio de ponto): badges à esquerda, sem sobrepor os
  // badges dos acessos (à direita).
  final pontosPorDia = {
    d09: PontoDia(
      matricula: '28109',
      data: d09,
      entrada: DateTime(2026, 7, 9, 7, 58),
      saida: DateTime(2026, 7, 9, 19, 3),
    ),
    d10: PontoDia(
      matricula: '28109',
      data: d10,
      entrada: DateTime(2026, 7, 10, 8, 5),
      saida: null, // jornada aberta: só o badge de entrada
    ),
  };

  final apontamentosPorDia = {
    d09: [
      const Apontamento(
        id: 79480,
        chamadoId: 2026042116,
        data: null,
        usuarioId: 5270,
        content: '&#60;p&#62;Apontamento&#60;/p&#62;',
        actiontime: 10800,
        beginDate: null,
        endDate: null,
      ),
    ],
  };
  // Reinstancia com data preenchida (entity é imutável). `state: 2` real do
  // backend → bloco verde (concluída).
  apontamentosPorDia[d09] = [
    Apontamento(
      id: 79480,
      chamadoId: 2026042116,
      data: DateTime(2026, 7, 9, 8),
      usuarioId: 5270,
      content: '&#60;p&#62;Apontamento&#60;/p&#62;',
      actiontime: 10800,
      beginDate: null,
      endDate: null,
      estado: TarefaEstado.concluida,
    ),
  ];

  Future<void> pumpWeekView(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp(
          theme: buildLightTheme(primaryColorHex: '#de3438'),
          home: Scaffold(
            // Mesmo shape da tela: a week view vive dentro de um Expanded.
            body: Column(
              children: [
                Expanded(
                  child: TimesheetWeekView(
                    weekDays: weekDays,
                    acessosPorDia: acessosPorDia,
                    pontosPorDia: pontosPorDia,
                    totaisPorDia: {
                      d09: const Duration(hours: 9, minutes: 13),
                      d10: const Duration(hours: 10, minutes: 2),
                    },
                    apontamentosPorDia: apontamentosPorDia,
                    apontadoPorDia: {d09: const Duration(hours: 3)},
                    titulosChamados: const {
                      2026042116: 'Melhoria no módulo de faturamento',
                    },
                    onDayTap: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza a agenda sem erro de layout (tela larga)',
      (tester) async {
    await pumpWeekView(tester, size: const Size(1400, 900));

    expect(tester.takeException(), isNull);
    // Bloco do apontamento na grade, com o título do chamado.
    expect(find.textContaining('#2026042116'), findsWidgets);
    expect(find.textContaining('Melhoria no módulo de faturamento'),
        findsWidgets);
    // Eixo de horas do dia completo (00:00 → 23:00).
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
    // Cabeçalhos dos 7 dias.
    expect(find.text('dom'), findsOneWidget);
    expect(find.text('sáb'), findsOneWidget);
    // Badges de entrada/saída da catraca nos horários das marcações.
    expect(find.text('09:27'), findsOneWidget); // entrada qui
    expect(find.text('12:54'), findsOneWidget); // saída qui
    // Badges do ponto (à esquerda): entrada/saída de qui e só entrada de sex
    // (jornada aberta, sem saída).
    expect(find.text('07:58'), findsOneWidget); // ponto entrada qui
    expect(find.text('19:03'), findsOneWidget); // ponto saída qui
    expect(find.text('08:05'), findsOneWidget); // ponto entrada sex
  });

  testWidgets('renderiza com scroll horizontal em tela estreita',
      (tester) async {
    await pumpWeekView(tester, size: const Size(500, 800));

    expect(tester.takeException(), isNull);
    expect(find.text('dom'), findsOneWidget);
  });

  testWidgets('semana vazia renderiza grade 00–24 sem erro',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp(
          theme: buildLightTheme(primaryColorHex: '#de3438'),
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: TimesheetWeekView(
                    weekDays: weekDays,
                    acessosPorDia: const {},
                    pontosPorDia: const {},
                    totaisPorDia: const {},
                    apontamentosPorDia: const {},
                    apontadoPorDia: const {},
                    titulosChamados: const {},
                    onDayTap: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
  });
}
