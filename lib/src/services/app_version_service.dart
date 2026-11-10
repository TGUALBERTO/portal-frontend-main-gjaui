import 'package:package_info_plus/package_info_plus.dart';

import '../utils/utils.dart';

/// Versão do binário em execução, como o build a gravou a partir do `version`
/// do `pubspec.yaml`: na web vem do `version.json` servido junto do bundle; no
/// Android/Windows, dos metadados do pacote/executável.
///
/// No CI o job `version` define os dois valores e o build recebe como
/// `--build-name` (data e hora, ex.: `2026.09.24.09.47-qas`) e
/// `--build-number` (número do pipeline, que é o versionCode do Android).
/// [label] expõe só o build name: o número do pipeline continua no
/// `version.json` e no versionCode, mas não aparece na tela.
class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  AsyncAppResult<String>? _label;

  /// O build name (`2026.09.24.09.47-qas`; localmente, o `version` do pubspec
  /// sem o build number). Cacheado: na web a leitura é um fetch, e o valor
  /// não muda em runtime. Falha não fica em cache — a próxima leitura tenta
  /// de novo.
  AsyncAppResult<String> get label => _label ??= _read();

  AsyncAppResult<String> _read() async {
    final result = await runTask(() async {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    });
    if (result.isError()) _label = null;
    return result;
  }

  /// O build number como inteiro: no Android é o `versionCode`, o número do
  /// pipeline que gerou o APK. É ele que a atualização do app compara com o
  /// `versionCode` publicado no canal (ver `features/app_update`).
  ///
  /// Sem cache: é lido só quando a checagem de atualização roda. Falha se o
  /// valor não for inteiro, o que não acontece num build do pipeline.
  AsyncAppResult<int> get buildNumber => runTask(() async {
        final info = await PackageInfo.fromPlatform();
        final number = int.tryParse(info.buildNumber);
        if (number == null) {
          throw FormatException(
            'build number não é inteiro: "${info.buildNumber}"',
          );
        }
        return number;
      });
}
