import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:gjamobile/src/features/app_update/presentation/widgets/app_update_dialog.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme.dart';
import 'package:gjamobile/src/utils/utils.dart';

import 'fakes/fake_app_update.dart';

/// O diálogo roda no coletor da doca: tela pequena, operado com luva. Cada
/// estado do controller precisa caber e ter os botões certos.
void main() {
  late FakeAppUpdateRepository repository;
  late FakeAppUpdatePlatform platform;
  late AppUpdateController controller;

  setUp(() async {
    repository = FakeAppUpdateRepository();
    platform = FakeAppUpdatePlatform();
    controller = AppUpdateController(
      repository: repository,
      platform: platform,
      installedApp: () async =>
          (buildNumber: 119, versionName: '2026.10.02.13.46'),
      isSupported: () => true,
    );
    await controller.checkForUpdate();
  });

  tearDown(() => controller.dispose());

  Future<void> pumpDialog(
    WidgetTester tester, {
    Size size = const Size(360, 690),
  }) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp(
          theme: buildLightTheme(primaryColorHex: '#de3438'),
          home: Scaffold(
            body: Center(child: AppUpdateDialog(controller: controller)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('disponível: mostra as versões, o tamanho e as duas saídas',
      (tester) async {
    await pumpDialog(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Atualização do app'), findsOneWidget);
    expect(find.text('2026.10.03.09.15'), findsOneWidget); // nova
    expect(find.text('2026.10.02.13.46'), findsOneWidget); // instalada
    expect(find.text('80,1 MB'), findsOneWidget);
    expect(find.text('Atualizar agora'), findsOneWidget);
    expect(find.text('Depois'), findsOneWidget);
  });

  for (final entry in const <String, Size>{
    'coletor pequeno (320x480)': Size(320, 480),
    'coletor deitado (690x360)': Size(690, 360),
    'desktop (1440x900)': Size(1440, 900),
  }.entries) {
    testWidgets('sem overflow em ${entry.key}', (tester) async {
      await pumpDialog(tester, size: entry.value);

      expect(tester.takeException(), isNull);
      expect(find.text('Atualizar agora'), findsOneWidget);
    });
  }

  testWidgets('baixando: mostra o percentual e só o Cancelar', (tester) async {
    repository.downloadGate = Completer<void>();
    await pumpDialog(tester);

    await tester.tap(find.text('Atualizar agora'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Baixando a atualização… 50%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Depois'), findsNothing);
    expect(find.text('Atualizar agora'), findsNothing);

    // Cancelar devolve o diálogo ao estado de oferta.
    await tester.tap(find.text('Cancelar'));
    repository.downloadGate!.complete();
    await tester.pump();
    await tester.pump();

    expect(find.text('Atualizar agora'), findsOneWidget);
    expect(platform.installed, isEmpty);
  });

  testWidgets('download concluído: abre o instalador e mantém o Instalar',
      (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Atualizar agora'));
    await tester.pump();
    await tester.pump();

    expect(platform.installed, hasLength(1));
    expect(find.text('Instalar'), findsOneWidget);
    expect(find.text('Depois'), findsOneWidget);

    // Voltou do instalador sem instalar: Instalar abre de novo.
    await tester.tap(find.text('Instalar'));
    await tester.pump();

    expect(platform.installed, hasLength(2));
    expect(repository.downloadCount, 1);
  });

  testWidgets('falha: mostra a mensagem e o Tentar de novo', (tester) async {
    repository.downloadResult =
        const Failure(NetworkFailure('Sem conexão com o servidor.'));
    await pumpDialog(tester);

    await tester.tap(find.text('Atualizar agora'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Sem conexão com o servidor.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.text('Depois'), findsOneWidget);

    repository.downloadResult =
        const Success('/cache/app_update/gjamobile.apk');
    await tester.tap(find.text('Tentar de novo'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Instalar'), findsOneWidget);
    expect(platform.installed, hasLength(1));
  });
}
