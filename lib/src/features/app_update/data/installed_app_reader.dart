import 'package:gjamobile/src/features/app_update/domain/entities/installed_app.dart';
import 'package:gjamobile/src/services/app_version_service.dart';

/// Lê o build instalado pelo [AppVersionService] (`package_info_plus`).
///
/// `null` quando o build number não pôde ser lido ou não é inteiro: sem ele não
/// há como decidir se existe versão mais nova, e a checagem é abandonada.
Future<InstalledApp?> readInstalledApp() async {
  final buildNumber = (await AppVersionService.instance.buildNumber).getOrNull();
  if (buildNumber == null) return null;

  final versionName = (await AppVersionService.instance.label).getOrNull();
  return (buildNumber: buildNumber, versionName: versionName ?? '');
}
