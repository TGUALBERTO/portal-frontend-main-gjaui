import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:go_router/go_router.dart';

/// O botão voltar do Android fechava o app em qualquer tela: todas as rotas
/// eram irmãs no topo do router e `context.go` trocava a pilha inteira, então
/// não sobrava nada para desempilhar.
///
/// Estes testes montam a **mesma forma** do `appRouter` (login irmão da Home,
/// features filhas dela) e exercitam `popRoute()`, que é o que o sistema chama
/// no gesto de voltar. Não usam o `appRouter` real porque ele resolve
/// controllers do DI nos builders — o que está em teste é a topologia das
/// rotas, não as telas.
void main() {
  Widget tela(String nome) => Scaffold(body: Text(nome));

  GoRouter montarRouter() => GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (c, s) => tela('LOGIN'),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (c, s) => tela('HOME'),
            routes: [
              GoRoute(
                path: homeChild(AppRoutes.gjaautoInboundCheckInVeiculo),
                builder: (c, s) => tela('ENTRADA'),
              ),
              GoRoute(
                path: homeChild(AppRoutes.gjaautoInboundContagemCega),
                builder: (c, s) => tela('SCAN'),
                routes: [
                  GoRoute(
                    path: subRota(
                      AppRoutes.gjaautoInboundContagemCegaNotas,
                      AppRoutes.gjaautoInboundContagemCega,
                    ),
                    builder: (c, s) => tela('NOTAS'),
                    routes: [
                      GoRoute(
                        path: subRota(
                          AppRoutes.gjaautoInboundContagemCegaItens,
                          AppRoutes.gjaautoInboundContagemCegaNotas,
                        ),
                        builder: (c, s) => tela('ITENS'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  Future<GoRouter> pump(WidgetTester tester) async {
    final router = montarRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  /// O que o sistema chama no gesto/botão de voltar. `false` = ninguém tratou,
  /// e o Android fecha o app.
  Future<bool> voltar(WidgetTester tester, GoRouter router) async {
    final tratou = await router.routerDelegate.popRoute();
    await tester.pumpAndSettle();
    return tratou;
  }

  testWidgets('voltar numa tela de feature volta para a Home, não fecha o app',
      (tester) async {
    final router = await pump(tester);
    router.go(AppRoutes.gjaautoInboundCheckInVeiculo);
    await tester.pumpAndSettle();
    expect(find.text('ENTRADA'), findsOneWidget);

    expect(await voltar(tester, router), isTrue,
        reason: 'o voltar precisa ser tratado pela pilha, não pelo sistema');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('na Home o voltar chega ao sistema (onde o PopScope confirma)',
      (tester) async {
    final router = await pump(tester);
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();

    // Sem PopScope nesta árvore de teste: `false` prova que o gesto chega ao
    // sistema — é exatamente esse ponto que o PopScope da HomePage intercepta
    // para pedir confirmação em vez de deixar o app fechar direto.
    expect(await voltar(tester, router), isFalse);
  });

  testWidgets('voltar da Home nunca cai na tela de login', (tester) async {
    final router = await pump(tester);
    expect(find.text('LOGIN'), findsOneWidget);

    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);

    await voltar(tester, router);
    expect(find.text('LOGIN'), findsNothing,
        reason: 'login é irmão da Home, não pai — não pode ficar na pilha');
  });

  testWidgets('deep-link fundo reconstrói a pilha e volta uma tela por vez',
      (tester) async {
    final router = await pump(tester);

    // Um refresh na web (ou um link) direto na tela mais funda do fluxo.
    router.go(AppRoutes.gjaautoInboundContagemCegaItensPath(0));
    await tester.pumpAndSettle();
    expect(find.text('ITENS'), findsOneWidget);

    expect(await voltar(tester, router), isTrue);
    expect(find.text('NOTAS'), findsOneWidget);

    expect(await voltar(tester, router), isTrue);
    expect(find.text('SCAN'), findsOneWidget);

    expect(await voltar(tester, router), isTrue);
    expect(find.text('HOME'), findsOneWidget);

    // Só na Home o gesto escapa para o sistema.
    expect(await voltar(tester, router), isFalse);
  });

  group('homeChild / subRota', () {
    test('homeChild tira a barra inicial e preserva o resto', () {
      expect(homeChild('/GJAAUTO/IN/contagemCega'), 'GJAAUTO/IN/contagemCega');
      expect(homeChild('/ga/groups'), 'ga/groups');
    });

    test('subRota devolve só o trecho abaixo do pai', () {
      expect(
        subRota(
          AppRoutes.gjaautoInboundContagemCegaNotas,
          AppRoutes.gjaautoInboundContagemCega,
        ),
        'notas',
      );
      expect(
        subRota(
          AppRoutes.gjaautoInboundContagemCegaItens,
          AppRoutes.gjaautoInboundContagemCegaNotas,
        ),
        ':nota',
      );
    });

    test('subRota recusa um par que não é pai/filho', () {
      // Sem isso a rota não casaria e a tela ficaria inalcançável — melhor
      // falhar no boot do que descobrir com o conferente na doca.
      expect(
        () => subRota('/ga/groups', '/GJAAUTO/IN'),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
