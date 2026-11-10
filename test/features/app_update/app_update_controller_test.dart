import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/app_update/domain/entities/installed_app.dart';
import 'package:gjamobile/src/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:gjamobile/src/utils/utils.dart';

import 'fakes/fake_app_update.dart';

/// A regra da atualização do app: quando oferecer, quando calar, e o caminho
/// download → conferência → instalador. Tudo com fakes, sem aparelho.
void main() {
  late FakeAppUpdateRepository repository;
  late FakeAppUpdatePlatform platform;
  late AppUpdateController controller;

  // Instalado: build 119. Publicado por padrão nos fakes: build 120.
  InstalledApp? installed = (buildNumber: 119, versionName: '2026.10.02.13.46');
  var supported = true;
  var now = DateTime(2026, 10, 3, 8);

  AppUpdateController build() => AppUpdateController(
        repository: repository,
        platform: platform,
        installedApp: () async => installed,
        isSupported: () => supported,
        clock: () => now,
        recheckInterval: const Duration(hours: 6),
        retryAfterFailure: const Duration(minutes: 5),
      );

  setUp(() {
    repository = FakeAppUpdateRepository();
    platform = FakeAppUpdatePlatform();
    installed = (buildNumber: 119, versionName: '2026.10.02.13.46');
    supported = true;
    now = DateTime(2026, 10, 3, 8);
    controller = build();
  });

  tearDown(() => controller.dispose());

  group('checkForUpdate', () {
    test('fora do Android/release não consulta o canal', () async {
      supported = false;

      await controller.checkForUpdate();

      expect(repository.fetchCount, 0);
      expect(controller.statusSignal.value, AppUpdateStatus.idle);
    });

    test('publicado maior que o instalado: atualização disponível', () async {
      await controller.checkForUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.available);
      expect(controller.releaseSignal.value?.versionCode, 120);
      expect(controller.installedSignal.value?.buildNumber, 119);
      expect(controller.isUpdateAvailableSignal.value, isTrue);
      expect(controller.shouldPromptSignal.value, isTrue);
    });

    test('publicado igual ao instalado: em dia', () async {
      repository.latest = Success(release(versionCode: 119));

      await controller.checkForUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.upToDate);
      expect(controller.releaseSignal.value, isNull);
      expect(controller.isUpdateAvailableSignal.value, isFalse);
      expect(controller.shouldPromptSignal.value, isFalse);
    });

    test('publicado menor que o instalado: nunca oferece downgrade', () async {
      repository.latest = Success(release(versionCode: 100));

      await controller.checkForUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.upToDate);
      expect(controller.isUpdateAvailableSignal.value, isFalse);
    });

    test('assinatura diferente da publicada: não oferece', () async {
      // Build local de um dev, assinado com a chave de debug.
      platform.signer = signerDebug;

      await controller.checkForUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.upToDate);
      expect(controller.isUpdateAvailableSignal.value, isFalse);
    });

    test('assinatura comparada sem diferenciar maiúsculas', () async {
      platform.signer = signerPipeline.toUpperCase();

      await controller.checkForUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.available);
    });

    test('falha ao ler a assinatura instalada: não oferece', () async {
      platform.signerError = StateError('sem signingInfo');

      await controller.checkForUpdate();

      expect(controller.isUpdateAvailableSignal.value, isFalse);
    });

    test('canal sem signerSha256: oferece sem consultar a assinatura',
        () async {
      repository.latest = Success(release(signerSha256: null));

      await controller.checkForUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.available);
      expect(platform.signerCalls, 0);
    });

    test('só confere a assinatura quando há build mais novo', () async {
      repository.latest = Success(release(versionCode: 119));

      await controller.checkForUpdate();

      expect(platform.signerCalls, 0);
    });

    test('falha na consulta é silenciosa: sem erro, sem oferta', () async {
      repository.latest = const Failure(NetworkFailure('sem conexão'));

      await controller.checkForUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.idle);
      expect(controller.errorSignal.value, isNull);
      expect(controller.isUpdateAvailableSignal.value, isFalse);
    });

    test('sem conseguir ler a versão instalada, nem consulta o canal',
        () async {
      installed = null;

      await controller.checkForUpdate();

      expect(repository.fetchCount, 0);
      expect(controller.statusSignal.value, AppUpdateStatus.idle);
    });

    test('com atualização pendente, preserva no cache só o APK dela',
        () async {
      await controller.checkForUpdate();

      expect(repository.cleaned, ['gjamobile-2026.10.03.09.15.apk']);
    });

    test('em dia, esvazia o cache: o APK publicado é o que já foi instalado',
        () async {
      repository.latest = Success(release(versionCode: 119));

      await controller.checkForUpdate();

      expect(repository.cleaned, [null]);
    });

    test('respeita o intervalo entre consultas bem-sucedidas', () async {
      await controller.checkForUpdate();
      now = now.add(const Duration(hours: 5, minutes: 59));
      await controller.checkForUpdate();
      expect(repository.fetchCount, 1);

      now = now.add(const Duration(minutes: 2));
      await controller.checkForUpdate();
      expect(repository.fetchCount, 2);
    });

    test('depois de uma falha, tenta de novo em poucos minutos', () async {
      repository.latest = const Failure(NetworkFailure('sem conexão'));
      await controller.checkForUpdate();

      now = now.add(const Duration(minutes: 4));
      await controller.checkForUpdate();
      expect(repository.fetchCount, 1);

      // O Wi-Fi subiu.
      repository.latest = Success(release());
      now = now.add(const Duration(minutes: 2));
      await controller.checkForUpdate();
      expect(repository.fetchCount, 2);
      expect(controller.statusSignal.value, AppUpdateStatus.available);
    });

    test('atualização que deixa de existir some da tela', () async {
      await controller.checkForUpdate();
      expect(controller.isUpdateAvailableSignal.value, isTrue);

      // O canal voltou a publicar o build instalado (rollback).
      repository.latest = Success(release(versionCode: 119));
      now = now.add(const Duration(hours: 7));
      await controller.checkForUpdate();

      expect(controller.isUpdateAvailableSignal.value, isFalse);
      expect(controller.releaseSignal.value, isNull);
    });
  });

  group('aviso ao usuário', () {
    test('depois de mostrado, não pede de novo na mesma execução', () async {
      await controller.checkForUpdate();
      controller.markPromptHandled();

      expect(controller.shouldPromptSignal.value, isFalse);
      // A atualização continua pendente: é o que mantém a entrada na Home.
      expect(controller.isUpdateAvailableSignal.value, isTrue);
    });

    test('reconsulta com o app aberto não reabre o aviso', () async {
      await controller.checkForUpdate();
      controller.markPromptHandled();

      now = now.add(const Duration(hours: 7));
      repository.latest = Success(release(versionCode: 121));
      await controller.checkForUpdate();

      expect(controller.releaseSignal.value?.versionCode, 121);
      expect(controller.shouldPromptSignal.value, isFalse);
    });
  });

  group('startUpdate', () {
    setUp(() => controller.checkForUpdate());

    test('baixa, confere e abre o instalador', () async {
      await controller.startUpdate();

      expect(repository.downloadCount, 1);
      expect(repository.verifyCount, 1);
      expect(platform.installed, ['/cache/app_update/gjamobile.apk']);
      expect(controller.statusSignal.value, AppUpdateStatus.readyToInstall);
      expect(controller.progressSignal.value, 1);
      expect(controller.errorSignal.value, isNull);
    });

    test('informa o progresso durante o download', () async {
      repository.downloadGate = Completer<void>();

      final running = controller.startUpdate();
      await pumpEventQueue();

      expect(controller.statusSignal.value, AppUpdateStatus.downloading);
      expect(controller.progressSignal.value, 0.5);
      expect(controller.isBusy, isTrue);

      repository.downloadGate!.complete();
      await running;
      expect(controller.statusSignal.value, AppUpdateStatus.readyToInstall);
    });

    test('falha no download: mostra o erro e permite tentar de novo',
        () async {
      repository.downloadResult =
          const Failure(NetworkFailure('Sem conexão com o servidor.'));

      await controller.startUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.failed);
      expect(controller.errorSignal.value?.message, contains('Sem conexão'));
      expect(platform.installed, isEmpty);
      expect(controller.isUpdateAvailableSignal.value, isTrue);

      repository.downloadResult =
          const Success('/cache/app_update/gjamobile.apk');
      await controller.startUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.readyToInstall);
      expect(controller.errorSignal.value, isNull);
      expect(platform.installed, hasLength(1));
    });

    test('arquivo baixado que não confere é apagado e NÃO vai ao instalador',
        () async {
      repository.verifyResults = [
        const Failure(ValidationFailure('SHA-256 diferente')),
      ];

      await controller.startUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.failed);
      expect(controller.errorSignal.value?.message, 'SHA-256 diferente');
      expect(repository.discarded, ['/cache/app_update/gjamobile.apk']);
      expect(platform.installed, isEmpty);
      // Não entra em laço baixando de novo sozinho.
      expect(repository.downloadCount, 1);
    });

    test('cancelar interrompe o download e mantém a atualização disponível',
        () async {
      repository.downloadGate = Completer<void>();

      final running = controller.startUpdate();
      await pumpEventQueue();
      controller.cancelDownload();
      repository.downloadGate!.complete();
      await running;

      expect(controller.statusSignal.value, AppUpdateStatus.available);
      expect(controller.errorSignal.value, isNull);
      expect(platform.installed, isEmpty);
      expect(repository.verifyCount, 0);
    });

    test('chamadas repetidas durante o download não iniciam outro', () async {
      repository.downloadGate = Completer<void>();

      final running = controller.startUpdate();
      await pumpEventQueue();
      await controller.startUpdate();
      repository.downloadGate!.complete();
      await running;

      expect(repository.downloadCount, 1);
    });

    test('APK já baixado e íntegro é reaproveitado, sem novo download',
        () async {
      repository.cachedPath = '/cache/app_update/ja-baixado.apk';

      await controller.startUpdate();

      expect(repository.downloadCount, 0);
      expect(platform.installed, ['/cache/app_update/ja-baixado.apk']);
      expect(controller.statusSignal.value, AppUpdateStatus.readyToInstall);
    });

    test('APK em cache corrompido é descartado e baixado de novo, uma vez',
        () async {
      repository.cachedPath = '/cache/app_update/ja-baixado.apk';
      repository.verifyResults = [
        const Failure(ValidationFailure('SHA-256 diferente')),
        const Success(unit),
      ];

      await controller.startUpdate();

      expect(repository.discarded, ['/cache/app_update/ja-baixado.apk']);
      expect(repository.downloadCount, 1);
      expect(platform.installed, ['/cache/app_update/gjamobile.apk']);
      expect(controller.statusSignal.value, AppUpdateStatus.readyToInstall);
    });

    test('sem atualização pendente não faz nada', () async {
      final idle = build();
      addTearDown(idle.dispose);

      await idle.startUpdate();

      expect(repository.downloadCount, 0);
    });
  });

  group('install', () {
    setUp(() => controller.checkForUpdate());

    test('instalador que não abre: erro na tela e o arquivo continua pronto',
        () async {
      platform.installError = StateError('sem atividade para o intent');

      await controller.startUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.readyToInstall);
      expect(controller.errorSignal.value?.message, contains('instalador'));

      // Tentar de novo não baixa outra vez.
      platform.installError = null;
      await controller.install();

      expect(platform.installed, hasLength(1));
      expect(controller.errorSignal.value, isNull);
      expect(repository.downloadCount, 1);
    });

    test('usuário saiu do instalador: Instalar abre de novo, sem download',
        () async {
      await controller.startUpdate();
      await controller.install();

      expect(platform.installed, hasLength(2));
      expect(repository.downloadCount, 1);
    });

    test('antes de o arquivo estar conferido não abre o instalador', () async {
      await controller.install();

      expect(platform.installed, isEmpty);
    });

    test('reconsulta com o mesmo build não desfaz o arquivo pronto', () async {
      await controller.startUpdate();

      now = now.add(const Duration(hours: 7));
      await controller.checkForUpdate();

      expect(controller.statusSignal.value, AppUpdateStatus.readyToInstall);
      await controller.install();
      expect(platform.installed, hasLength(2));
    });
  });
}
