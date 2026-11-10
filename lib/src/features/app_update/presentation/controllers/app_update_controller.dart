import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/app_update/app_update_config.dart';
import 'package:gjamobile/src/features/app_update/data/repositories/app_update_repository.dart';
import 'package:gjamobile/src/features/app_update/domain/entities/app_release.dart';
import 'package:gjamobile/src/features/app_update/domain/entities/installed_app.dart';
import 'package:gjamobile/src/features/app_update/domain/services/app_update_platform.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Em que ponto da atualização o app está.
enum AppUpdateStatus {
  /// Ainda não se sabe (checagem não rodou ou falhou).
  idle,

  /// A última checagem não achou nada mais novo — ou achou, mas este build não
  /// pode recebê-lo (assinatura diferente).
  upToDate,

  /// Há um build mais novo publicado, pronto para o usuário decidir.
  available,

  downloading,

  /// Conferindo tamanho e SHA-256 do arquivo baixado.
  verifying,

  /// Arquivo conferido; falta o usuário confirmar no instalador do Android.
  readyToInstall,

  /// O download ou a conferência falhou. Tentar de novo volta a [downloading].
  failed,
}

/// App-scoped. Decide se há atualização e conduz download → conferência →
/// instalador. Toda a regra mora aqui, com as dependências injetadas, para ser
/// testável sem aparelho.
///
/// A **checagem** é silenciosa por contrato: qualquer falha nela (sem rede,
/// canal fora do ar, JSON inesperado) só vai para o log e o app segue como se
/// não houvesse atualização. O alvo é o coletor da doca; um aviso sobre algo que
/// o operador não pediu, no meio de um caminhão, é o que não pode acontecer. Só
/// falhas do download que o próprio usuário iniciou aparecem na tela.
class AppUpdateController {
  AppUpdateController({
    required AppUpdateRepository repository,
    required AppUpdatePlatform platform,
    required Future<InstalledApp?> Function() installedApp,
    bool Function()? isSupported,
    DateTime Function()? clock,
    Duration recheckInterval = AppUpdateConfig.recheckInterval,
    Duration retryAfterFailure = AppUpdateConfig.retryAfterFailure,
  })  : _repository = repository,
        _platform = platform,
        _installedApp = installedApp,
        _isSupported = isSupported ?? (() => AppUpdateConfig.isSupported),
        _clock = clock ?? DateTime.now,
        _recheckInterval = recheckInterval,
        _retryAfterFailure = retryAfterFailure;

  final AppUpdateRepository _repository;
  final AppUpdatePlatform _platform;
  final Future<InstalledApp?> Function() _installedApp;
  final bool Function() _isSupported;
  final DateTime Function() _clock;
  final Duration _recheckInterval;
  final Duration _retryAfterFailure;

  late final Signal<AppUpdateStatus> _status = signal(AppUpdateStatus.idle);
  late final Signal<AppRelease?> _release = signal(null);
  late final Signal<InstalledApp?> _installed = signal(null);
  late final Signal<double> _progress = signal(0);
  late final Signal<AppFailure?> _error = signal(null);
  late final Signal<bool> _promptHandled = signal(false);

  late final Computed<bool> _isUpdateAvailable = computed(() {
    final status = _status.value;
    return _release.value != null &&
        status != AppUpdateStatus.idle &&
        status != AppUpdateStatus.upToDate;
  });

  late final Computed<bool> _shouldPrompt =
      computed(() => _isUpdateAvailable.value && !_promptHandled.value);

  ReadonlySignal<AppUpdateStatus> get statusSignal => _status;

  /// O build publicado que motivou a oferta. Nulo enquanto não há atualização.
  ReadonlySignal<AppRelease?> get releaseSignal => _release;

  ReadonlySignal<InstalledApp?> get installedSignal => _installed;

  /// Fração baixada, de 0 a 1. Só faz sentido em [AppUpdateStatus.downloading].
  ReadonlySignal<double> get progressSignal => _progress;

  ReadonlySignal<AppFailure?> get errorSignal => _error;

  /// Há um build mais novo que este aparelho pode instalar. Continua verdadeiro
  /// durante o download e a instalação, para a entrada da Home não sumir.
  ReadonlySignal<bool> get isUpdateAvailableSignal => _isUpdateAvailable;

  /// Há atualização e o diálogo ainda não foi mostrado nesta execução do app.
  ReadonlySignal<bool> get shouldPromptSignal => _shouldPrompt;

  bool get isBusy =>
      _status.peek() == AppUpdateStatus.downloading ||
      _status.peek() == AppUpdateStatus.verifying;

  bool _checking = false;
  DateTime? _nextCheckAllowedAt;
  AppDownloadHandle? _download;
  String? _downloadedPath;

  /// Consulta o canal e atualiza o estado. Chamado ao abrir o app e a cada
  /// volta ao primeiro plano; o intervalo mínimo entre consultas faz a segunda
  /// chamada ser barata.
  Future<void> checkForUpdate() async {
    if (!_isSupported()) return;
    // Não interrompe um download/conferência nem empilha duas consultas.
    if (_checking || isBusy) return;

    final now = _clock();
    final allowedAt = _nextCheckAllowedAt;
    if (allowedAt != null && now.isBefore(allowedAt)) return;

    _checking = true;
    try {
      final checked = await _check();
      _nextCheckAllowedAt =
          now.add(checked ? _recheckInterval : _retryAfterFailure);
    } catch (e, st) {
      // Rede de segurança: nada daqui pode vazar para quem chamou.
      AppLogger.error('app_update: checagem falhou', e, st);
      _nextCheckAllowedAt = now.add(_retryAfterFailure);
    } finally {
      _checking = false;
    }
  }

  /// `true` quando a consulta chegou a uma conclusão (há ou não há atualização).
  Future<bool> _check() async {
    final installed = await _installedApp();
    if (installed == null) {
      AppLogger.warning('app_update: não foi possível ler a versão instalada');
      return false;
    }
    _installed.value = installed;

    final result = await _repository.fetchLatest();
    final release = result.getOrNull();
    if (release == null) {
      AppLogger.info(
        'app_update: canal indisponível: ${result.exceptionOrNull()?.message}',
      );
      return false;
    }

    final isNewer = release.isNewerThan(installed.buildNumber);
    // Em dia: nada no cache serve mais, nem o APK publicado — ele é o que
    // acabou de ser instalado, e ficaria ocupando ~100 MB do coletor até sair a
    // versão seguinte. Com atualização pendente, preserva só o APK dela (pode
    // já estar baixado e conferido).
    await _repository.cleanStale(
      keepFileName: isNewer ? release.apkFileName : null,
    );

    if (!isNewer) {
      _setUpToDate();
      return true;
    }
    if (!await _signerMatches(release)) {
      _setUpToDate();
      return true;
    }
    _offer(release);
    return true;
  }

  /// O Android só instala por cima se o certificado for o mesmo. Um build com
  /// outra assinatura (o de um dev, assinado com a chave de debug) baixaria
  /// ~100 MB para o sistema recusar com "App não instalado" — então nem se
  /// oferece. Todo coletor que tem esta feature veio do pipeline e confere.
  Future<bool> _signerMatches(AppRelease release) async {
    final expected = release.signerSha256;
    if (expected == null) return true;
    try {
      final installed = (await _platform.signerSha256()).toLowerCase();
      if (installed == expected) return true;
      AppLogger.warning(
        'app_update: build ${release.versionCode} publicado com outra '
        'assinatura ($expected); este app é $installed. Atualização ignorada.',
      );
      return false;
    } catch (e) {
      AppLogger.warning('app_update: falha ao ler a assinatura instalada: $e');
      return false;
    }
  }

  void _setUpToDate() {
    batch(() {
      _release.value = null;
      _error.value = null;
      _downloadedPath = null;
      _status.value = AppUpdateStatus.upToDate;
    });
  }

  void _offer(AppRelease release) {
    // Uma reconsulta que acha o MESMO build não pode desfazer o que já andou
    // (ex.: o arquivo conferido, esperando o usuário tocar em Instalar).
    final sameRelease = _release.peek()?.versionCode == release.versionCode;
    if (sameRelease && _isUpdateAvailable.peek()) return;

    batch(() {
      _release.value = release;
      _error.value = null;
      _progress.value = 0;
      _downloadedPath = null;
      _status.value = AppUpdateStatus.available;
    });
  }

  /// Baixa (ou reaproveita o que já está no cache), confere e abre o instalador.
  Future<void> startUpdate() => _startUpdate(allowCache: true);

  Future<void> _startUpdate({required bool allowCache}) async {
    final release = _release.peek();
    if (release == null || isBusy) return;
    _error.value = null;

    final cached = allowCache ? await _repository.cachedApkPath(release) : null;
    final path = cached ?? await _downloadApk(release);
    if (path == null) return; // cancelado ou falhou; o estado já foi ajustado

    _status.value = AppUpdateStatus.verifying;
    final verified = await _repository.verify(path, release);
    final failure = verified.exceptionOrNull();
    if (failure != null) {
      await _repository.discard(path);
      if (cached != null) {
        // Era um arquivo antigo no cache e não confere mais: baixa de novo, uma
        // vez só, em vez de mostrar erro por algo que o usuário não fez.
        _status.value = AppUpdateStatus.available;
        return _startUpdate(allowCache: false);
      }
      _fail(failure);
      return;
    }

    _downloadedPath = path;
    _status.value = AppUpdateStatus.readyToInstall;
    await install();
  }

  Future<String?> _downloadApk(AppRelease release) async {
    final handle = AppDownloadHandle();
    _download = handle;
    batch(() {
      _progress.value = 0;
      _status.value = AppUpdateStatus.downloading;
    });

    final result = await _repository.download(
      release,
      onProgress: (fraction) => _progress.value = fraction,
      handle: handle,
    );
    _download = null;

    if (handle.isCancelled) {
      _status.value = AppUpdateStatus.available;
      return null;
    }
    return result.fold(
      (path) => path,
      (failure) {
        _fail(failure);
        return null;
      },
    );
  }

  void _fail(AppFailure failure) {
    AppLogger.warning('app_update: ${failure.message}');
    batch(() {
      _error.value = failure;
      _status.value = AppUpdateStatus.failed;
    });
  }

  /// Interrompe o download em andamento; o app volta a [AppUpdateStatus.available].
  void cancelDownload() => _download?.cancel();

  /// Abre o instalador do Android para o arquivo já conferido. Pode ser chamado
  /// de novo: se o usuário sair do instalador sem instalar, o arquivo continua
  /// no cache e não precisa de outro download.
  Future<void> install() async {
    final path = _downloadedPath;
    if (path == null || _status.peek() != AppUpdateStatus.readyToInstall) {
      return;
    }
    _error.value = null;
    try {
      await _platform.installApk(path);
    } catch (e, st) {
      AppLogger.error('app_update: falha ao abrir o instalador', e, st);
      // Continua em readyToInstall: o arquivo está bom, só o instalador não
      // abriu. O diálogo mostra o erro e mantém o botão Instalar.
      _error.value = UnknownFailure(
        'Não foi possível abrir o instalador do Android.',
        cause: e,
      );
    }
  }

  /// O diálogo de atualização já apareceu nesta execução do app (o usuário
  /// atualizou ou deixou para depois). Só volta a aparecer sozinho no próximo
  /// início; até lá a atualização fica na entrada "Atualizar app" da Home.
  void markPromptHandled() => _promptHandled.value = true;

  void dispose() {
    _download?.cancel();
    _status.dispose();
    _release.dispose();
    _installed.dispose();
    _progress.dispose();
    _error.dispose();
    _promptHandled.dispose();
    _isUpdateAvailable.dispose();
    _shouldPrompt.dispose();
  }
}
