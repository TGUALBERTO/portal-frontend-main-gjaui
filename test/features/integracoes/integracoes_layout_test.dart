import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gjamobile/src/features/integracoes/data/models/models.dart';
import 'package:gjamobile/src/features/integracoes/presentation/controllers/integracoes_controller.dart';
import 'package:gjamobile/src/features/integracoes/presentation/screens/integracoes_screen.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme_constants.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// A tabela nao rola na horizontal: as 8 colunas cabem na largura da janela.
///
/// Sem isto, um ajuste de largura de coluna empurra a ultima ("Acoes", onde
/// fica o botao de disparo) para fora da area visivel — e o administrador nao
/// acha o botao, que foi exatamente o que aconteceu.
ProcessoIntegracao _processo(String nome) => ProcessoIntegracao(
      nome: nome,
      // Descricao longa de proposito: e ela que pressiona a coluna elastica.
      descricao:
          'Carga completa de funcionarios do FPW: le todos os cadastros, '
          'ativos e rescindidos, e reconcilia o espelho local.',
      tipo: TipoProcesso.cargaCompleta,
      grupoRecurso: 'funcionarios-fpw',
      requisitos: 'Oracle + Helpdesk',
      ativo: true,
      disparoManual: true,
      bloqueado: false,
      emExecucao: false,
      podeExecutar: true,
      proximaExecucao: DateTime(2026, 9, 6, 6, 30),
      ultimaExecucao: ExecucaoIntegracao(
        id: 'x-$nome',
        processo: nome,
        status: StatusExecucao.concluido,
        iniciadoEm: DateTime(2026, 9, 3, 16, 8),
        duracaoMs: 1234,
        registrosProcessados: 1234,
        registrosInseridos: 12,
        registrosAtualizados: 34,
      ),
    );

void main() {
  // O formatador da tela usa pt_BR (como em main.dart); sem isto o teste
  // quebra na formatacao da data, nao no layout.
  setUpAll(() => initializeDateFormatting('pt_BR'));

  final processos = [
    _processo('funcionario-fpw-completo'),
    _processo('projetos-tarefas-chamados'),
  ];

  Future<void> montarEm(WidgetTester tester, double largura) async {
    tester.view.physicalSize = Size(largura, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp(
          theme: buildDarkTheme(primaryColorHex: '#de3438'),
          home: Scaffold(
            body: IntegracoesConteudo(
              processos: processos,
              total: processos.length,
              sortColumn: ProcessoSortColumn.nome,
              sortAscending: true,
              executandoNome: null,
              onSort: (_, __) {},
              onExecutar: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Larguras tipicas, comecando no limite de baixo da tabela.
  for (final largura in <double>[1068, 1100, 1280, 1440, 1920]) {
    testWidgets('sem overflow em ${largura.toInt()}px', (tester) async {
      await montarEm(tester, largura);
      // Overflow de layout chega como excecao; qualquer estouro reprova aqui.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a tabela nao tem rolagem horizontal', (tester) async {
    await montarEm(tester, 1280);

    final horizontais = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .where((s) => s.scrollDirection == Axis.horizontal);

    expect(horizontais, isEmpty,
        reason: 'a tabela deve caber na largura, sem rolagem lateral');
  });

  // O caso que motivou este arquivo: sem rolagem, uma coluna larga demais faz
  // o botao sair da tela e o disparo manual fica inalcancavel.
  for (final largura in <double>[1068, 1100, 1280, 1440, 1920]) {
    testWidgets('o botao de executar cabe na janela de ${largura.toInt()}px',
        (tester) async {
      await montarEm(tester, largura);

      // O botao e o ultimo elemento da linha: se ele cabe, nenhuma coluna
      // ficou para fora.
      final botoes = find.byIcon(GjaIcons.mediaPlay);
      expect(botoes, findsWidgets);

      for (final elemento in botoes.evaluate()) {
        final caixa = elemento.renderObject! as RenderBox;
        final direita = caixa.localToGlobal(Offset(caixa.size.width, 0)).dx;
        expect(direita, lessThanOrEqualTo(largura),
            reason: 'o botao de executar esta fora da area visivel');
      }
    });
  }

  testWidgets('abaixo do corte troca para cards', (tester) async {
    await montarEm(tester, IntegracoesConteudo.larguraMinimaTabela - 1);

    expect(find.byType(DataTable), findsNothing);
    // Nos cards o botao aparece rotulado, nao como icone solto.
    expect(find.text('Executar agora'), findsWidgets);
  });
}
