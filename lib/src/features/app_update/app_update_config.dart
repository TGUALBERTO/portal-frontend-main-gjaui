import 'package:flutter/foundation.dart';

/// Configuração da atualização do app Android pelo canal do pipeline.
abstract final class AppUpdateConfig {
  /// Onde o pipeline publica `latest.json` e o APK (job `docker_build` da
  /// `main`, dentro da imagem web de produção).
  ///
  /// É **fixo em produção e não segue o ambiente selecionado no app**: o mesmo
  /// binário atende QAS e PRD (a escolha é em runtime), só a `main` gera APK e
  /// ele só é publicado no site de produção. Por isso também não é um
  /// `BackendService`: aquele registro é de APIs autenticadas, com um host por
  /// ambiente.
  ///
  /// `--dart-define=APP_UPDATE_BASE_URL=...` troca o endereço para teste.
  static const String channelBaseUrl = String.fromEnvironment(
    'APP_UPDATE_BASE_URL',
    defaultValue: 'https://portal.rebic.com.br/downloads/android',
  );

  /// `--dart-define=APP_UPDATE_FORCE=true` liga a feature num build de debug,
  /// para exercitar o fluxo no emulador.
  static const bool forceEnabled = bool.fromEnvironment('APP_UPDATE_FORCE');

  /// Só Android, e só build de release.
  ///
  /// - Web: está sempre na última versão. `defaultTargetPlatform` é `android`
  ///   também no browser de um Android, daí o `kIsWeb` explícito.
  /// - Windows: publicado por script, sem canal.
  /// - Debug: o build local tem build number 1 e outra assinatura; "atualizar"
  ///   baixaria 100 MB para o Android recusar a instalação.
  static bool get isSupported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      (kReleaseMode || forceEnabled);

  /// Intervalo mínimo entre checagens bem-sucedidas enquanto o app fica aberto
  /// (o coletor passa dias sem reiniciar).
  static const Duration recheckInterval = Duration(hours: 6);

  /// Depois de uma checagem que falhou, quanto esperar para tentar de novo.
  /// Curto: a falha típica é o Wi-Fi ainda não ter subido quando o app abre.
  static const Duration retryAfterFailure = Duration(minutes: 5);

  /// Pasta do download dentro do cache do app. Tem de bater com o `path` de
  /// `android/app/src/main/res/xml/app_update_paths.xml`: é a única pasta que o
  /// FileProvider entrega ao instalador.
  static const String cacheDirName = 'app_update';

  /// Canal de plataforma implementado em `MainActivity.kt`.
  static const String methodChannel = 'com.gja.gjamobile/app_update';
}
