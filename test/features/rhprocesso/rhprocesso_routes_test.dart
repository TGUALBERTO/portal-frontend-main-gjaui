import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/user_access.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/home/domain/feature_routes.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/rhprocesso_features.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:gjamobile/src/routing/routes/rhprocesso_routes.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:result_dart/result_dart.dart';


/// `/users/me` com as permissões dadas na feature de Volume x NF.
Map<String, dynamic> usuario({required bool leVolume}) => {
      'user': {'id': 'u1', 'email': 'rh@grupo.com', 'name': 'RH'},
      'groups': [
        {
          'id': 'g1',
          'name': 'RH',
          'permissions': [
            if (leVolume)
              {
                'feature': {
                  'id': 'f1',
                  'code': RhprocessoFeatures.volume,
                  'label': 'RH Volume x NF',
                  'module': {'id': 'm1', 'code': 'RH', 'label': 'RH Processo'},
                },
                'canRead': true,
              },
          ],
        },
      ],
    };

/// `/users/me` em memória. Fake do repositório, e não do Dio: num
/// `testWidgets` o HTTP é bloqueado e a checagem de conexão do `runTask`
/// falharia antes de chegar ao adapter.
class _AccessRepositoryFake implements AccessRepository {
  _AccessRepositoryFake(this.me);

  final Map<String, dynamic> me;

  @override
  AsyncAppResult<UserAccess> fetchCurrent() async => Success(UserAccess.fromJson(me));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Future<AccessController> acessoCarregado(Map<String, dynamic> me) async {
  final controller = AccessController(repository: _AccessRepositoryFake(me));
  await controller.load();
  return controller;
}

void main() {
  test('os quatro feature.code do RH abrem as telas pela Home', () {
    expect(routeForFeatureCode(RhprocessoFeatures.volume), AppRoutes.rhVolume);
    expect(routeForFeatureCode(RhprocessoFeatures.estrutura), AppRoutes.rhEstrutura);
    expect(routeForFeatureCode(RhprocessoFeatures.caracteristicas), AppRoutes.rhCaracteristicas);
    expect(routeForFeatureCode(RhprocessoFeatures.parametros), AppRoutes.rhParametros);
    expect(adminOnlyFeatureCodes.any((c) => c.startsWith('rhprocesso_')), isFalse);
  });

  test('as rotas do RH são filhas da Home (voltar do Android)', () {
    for (final rota in rhprocessoRoutes.cast<GoRoute>()) {
      expect(rota.path.startsWith('/'), isFalse, reason: rota.path);
      expect(rota.redirect, isNotNull, reason: rota.path);
    }
  });

  Future<GoRouter> navegar(WidgetTester tester, AccessController access) async {
    final router = GoRouter(
      initialLocation: AppRoutes.rhVolume,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (c, s) => const Text('HOME'),
          routes: [
            GoRoute(
              path: homeChild(AppRoutes.rhVolume),
              redirect: exigeFeatureRh(RhprocessoFeatures.volume, access: () => access),
              builder: (c, s) => const Text('VOLUME'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('sem a feature, o acesso direto à URL volta para a Home', (tester) async {
    final access = await acessoCarregado(usuario(leVolume: false));

    await navegar(tester, access);

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('VOLUME'), findsNothing);
  });

  testWidgets('com leitura na feature, a tela abre', (tester) async {
    final access = await acessoCarregado(usuario(leVolume: true));

    await navegar(tester, access);

    expect(find.text('VOLUME'), findsOneWidget);
  });

  testWidgets('enquanto o /users/me não chegou, a rota não redireciona', (tester) async {
    final access = AccessController(repository: _AccessRepositoryFake(const {}));

    await navegar(tester, access);

    expect(find.text('VOLUME'), findsOneWidget);
  });
}
