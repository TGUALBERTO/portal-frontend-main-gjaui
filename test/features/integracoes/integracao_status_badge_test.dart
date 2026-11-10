import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/integracoes/data/models/status_execucao.dart';
import 'package:gjamobile/src/features/integracoes/presentation/integracao_format.dart';
import 'package:gjamobile/src/features/integracoes/presentation/widgets/integracao_status_badge.dart';
import 'package:gjamobile/src/shared/widgets/status_pill.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme_constants.dart';

/// O badge e o formatador da tela de integrações. São a leitura que o
/// administrador faz num relance: se um deles mentir, a tela inteira mente.
void main() {
  Future<void> montar(WidgetTester tester, Widget widget, {bool escuro = false}) {
    return tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp(
          theme: escuro
              ? buildDarkTheme(primaryColorHex: '#de3438')
              : buildLightTheme(primaryColorHex: '#de3438'),
          home: Scaffold(body: Center(child: widget)),
        ),
      ),
    );
  }

  group('IntegracaoStatusBadge', () {
    testWidgets('mostra o rótulo do status', (tester) async {
      await montar(
        tester,
        const IntegracaoStatusBadge(status: StatusExecucao.concluido),
      );

      expect(find.text('Concluído'), findsOneWidget);
    });

    testWidgets('status transitório ganha spinner', (tester) async {
      // O disparo é assíncrono; sem o spinner a tela parece travada.
      await montar(
        tester,
        const IntegracaoStatusBadge(status: StatusExecucao.executando),
      );

      expect(find.text('Executando'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('status final não tem spinner', (tester) async {
      await montar(
        tester,
        const IntegracaoStatusBadge(status: StatusExecucao.erro),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('processo desativado ignora o status da última execução',
        (tester) async {
      // Mostrar "Concluído" para uma integração desligada sugeriria que ela
      // acabou de rodar.
      await montar(
        tester,
        const IntegracaoStatusBadge(
          status: StatusExecucao.concluido,
          ativo: false,
        ),
      );

      expect(find.text('Desativado'), findsOneWidget);
      expect(find.text('Concluído'), findsNothing);
    });

    testWidgets('renderiza no tema escuro', (tester) async {
      await montar(
        tester,
        const IntegracaoStatusBadge(status: StatusExecucao.erro),
        escuro: true,
      );

      expect(find.byType(StatusPill), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('IntegracaoFormat.duracao', () {
    test('escala a unidade conforme a grandeza', () {
      // Um delta some em milissegundos e uma carga completa leva dezenas de
      // minutos: uma unidade só deixaria uma das pontas ilegível.
      expect(IntegracaoFormat.duracao(820), '820 ms');
      expect(IntegracaoFormat.duracao(47000), '47 s');
      expect(IntegracaoFormat.duracao(750000), '12 min 30 s');
      expect(IntegracaoFormat.duracao(1800000), '30 min');
      expect(IntegracaoFormat.duracao(7500000), '2 h 05 min');
    });

    test('sem duração mostra travessão', () {
      expect(IntegracaoFormat.duracao(null), '—');
      expect(IntegracaoFormat.duracao(-1), '—');
    });
  });

  group('IntegracaoFormat.registros', () {
    test('detalha inseridos e atualizados quando há os dois', () {
      final texto = IntegracaoFormat.registros(
        processados: 1204,
        inseridos: 30,
        atualizados: 1174,
      );

      expect(texto, '1.204 (+30 ~1.174)');
    });

    test('rotina sem detalhe mostra só o total', () {
      // Exibir "~0" sugeriria um detalhe que o backend não tem para essa rotina.
      final texto = IntegracaoFormat.registros(
        processados: 500,
        inseridos: 500,
        atualizados: 0,
      );

      expect(texto, '500');
    });

    test('execução sem gravação mostra zero', () {
      expect(
        IntegracaoFormat.registros(processados: 0, inseridos: 0, atualizados: 0),
        '0',
      );
    });
  });
}
