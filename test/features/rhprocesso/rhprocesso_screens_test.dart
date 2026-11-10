import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/cadastros_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/estrutura_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/caracteristicas_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/estrutura_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/parametros_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/screens/caracteristicas_screen.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/screens/estrutura_screen.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/screens/parametros_screen.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/widgets/rh_tabela.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme_constants.dart';
import 'package:go_router/go_router.dart';

import 'fake_api.dart';

/// Spec portal-rhprocesso: as ações de inclusão, alteração e exclusão só
/// aparecem para quem tem a permissão correspondente.
bool Function(PermissionAction) so(Set<PermissionAction> acoes) =>
    (a) => acoes.contains(a);

Future<void> montar(WidgetTester tester, Widget tela) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // O AppTopBar consulta o GoRouter (botão voltar).
  final router = GoRouter(routes: [GoRoute(path: '/', builder: (c, s) => tela)]);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ScreenUtilWrapper(
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildLightTheme(primaryColorHex: '#de3438'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('RhTabela', () {
    Future<void> tabela(WidgetTester tester, int total) => montar(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: RhTabela<int>(
                colunas: const [RhColuna('N')],
                itens: [for (var i = 1; i <= total; i++) i],
                celulas: (i) => [Text('linha $i')],
                paginacaoNoTopo: true,
              ),
            ),
          ),
        );

    testWidgets('última página só tem as linhas que existem', (tester) async {
      await tabela(tester, 31);

      await tester.tap(find.byTooltip('Última página').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('linha '), findsNWidgets(11));
      expect(find.text('21 – 31 de 31'), findsNWidgets(2));
    });

    testWidgets('paginação no topo e no rodapé navegam juntas', (tester) async {
      await tabela(tester, 45);

      expect(find.text('1 – 20 de 45'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Próxima página').first);
      await tester.pumpAndSettle();

      expect(find.text('21 – 40 de 45'), findsNWidgets(2));
      expect(find.text('linha 21'), findsOneWidget);
    });

    testWidgets('lista de uma página não mostra paginação', (tester) async {
      await tabela(tester, 5);

      expect(find.byTooltip('Próxima página'), findsNothing);
      expect(find.textContaining('linha '), findsNWidgets(5));
    });
  });

  group('Parâmetros Gerais', () {
    late ParametrosController controller;

    setUp(() {
      final api = FakeApi()
        ..quando('GET /api/v1/parametros', RespostaFake.json([
          {'id': 1, 'descricao': 'PERIODO LIMITE', 'valor': 202401},
        ]));
      controller = ParametrosController(
        repository: CadastrosRepository(api.dio, exigeRede: false),
      );
    });

    testWidgets('só leitura: lista sem a edição', (tester) async {
      await montar(tester, ParametrosScreen(
        controller: controller,
        pode: so({PermissionAction.read}),
      ));

      expect(find.text('PERIODO LIMITE'), findsOneWidget);
      expect(find.byTooltip('Editar parâmetro'), findsNothing);
    });

    testWidgets('com alteração: mostra a edição', (tester) async {
      await montar(tester, ParametrosScreen(
        controller: controller,
        pode: so({PermissionAction.read, PermissionAction.update}),
      ));

      expect(find.byTooltip('Editar parâmetro'), findsOneWidget);
    });
  });

  group('Estrutura Comercial', () {
    late EstruturaController controller;

    setUp(() {
      final api = FakeApi()
        ..quando('GET /api/v1/estrutura-comercial/periodos-workflow', RespostaFake.json(['202610']))
        ..quando('GET /api/v1/estrutura-comercial', RespostaFake.json([
          {'periodo': 202610, 'unidade': '1', 'rota': '101', 'matriculaConsultor': '1', 'nomeConsultor': 'ANA'},
        ]));
      controller = EstruturaController(
        repository: EstruturaRepository(api.dio, exigeRede: false),
      );
    });

    testWidgets('só leitura: sem importar e sem editar', (tester) async {
      await montar(tester, EstruturaScreen(
        controller: controller,
        pode: so({PermissionAction.read}),
      ));

      expect(find.text('1 · ANA'), findsOneWidget);
      expect(find.text('Importar do Workflow'), findsNothing);
      expect(find.byTooltip('Editar rota'), findsNothing);
    });

    testWidgets('inclusão e alteração: importar e editar visíveis', (tester) async {
      await montar(tester, EstruturaScreen(
        controller: controller,
        pode: so({PermissionAction.read, PermissionAction.create, PermissionAction.update}),
      ));

      expect(find.text('Importar do Workflow'), findsOneWidget);
      expect(find.byTooltip('Editar rota'), findsOneWidget);
    });
  });

  group('Características de Produto', () {
    testWidgets('remover só com exclusão', (tester) async {
      final api = FakeApi()
        ..quando('GET /api/v1/produtos', RespostaFake.json([
          {'codigo': '101', 'descricao': 'AGUA', 'fator': 1, 'grupo': 'AGUA', 'subgrupo': 'SEM GAS'},
        ]));
      final controller = CaracteristicasController(
        repository: CadastrosRepository(api.dio, exigeRede: false),
      );
      // Fora do fake async do testWidgets: a resposta do Dio é um Future real.
      await tester.runAsync(() => controller.mostrarCaracterizados(true));

      await montar(tester, CaracteristicasScreen(
        controller: controller,
        pode: so({PermissionAction.read, PermissionAction.create}),
      ));

      expect(find.text('AGUA'), findsWidgets);
      expect(find.byTooltip('Trocar característica'), findsOneWidget);
      expect(find.byTooltip('Remover característica'), findsNothing);
    });
  });
}
