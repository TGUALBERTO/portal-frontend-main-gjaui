import 'package:equatable/equatable.dart';

/// Um build do app publicado no canal de atualização: o conteúdo do
/// `latest.json` que o job `build_apk` grava ao lado do APK.
///
/// ```json
/// { "versionCode": 119, "versionName": "2026.10.02.13.46",
///   "apk": "gjamobile-2026.10.02.13.46.apk", "size": 108373219,
///   "sha256": "…", "signerSha256": "…", "commit": "d242ba97",
///   "builtAt": "2026-10-02T16:55:00Z" }
/// ```
class AppRelease extends Equatable {
  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.apkFileName,
    required this.sizeBytes,
    required this.sha256,
    this.signerSha256,
    this.commit,
    this.builtAt,
  });

  /// Leitura **estrita**, ao contrário do `fromJson` tolerante das entidades de
  /// API: daqui sai um arquivo que será instalado no aparelho. Campo faltando ou
  /// de tipo errado lança [FormatException] e a checagem é tratada como falha —
  /// melhor não oferecer atualização do que oferecer uma que não se sabe conferir.
  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final apk = _string(json, 'apk');
    if (!_apkName.hasMatch(apk)) {
      // O nome vira caminho no cache e trecho de URL: só nome de arquivo simples.
      throw FormatException('latest.json: "apk" inválido: $apk');
    }

    final sha256 = _string(json, 'sha256').toLowerCase();
    if (!_sha256Hex.hasMatch(sha256)) {
      throw const FormatException('latest.json: "sha256" não é um SHA-256 em hex');
    }

    final size = _int(json, 'size');
    if (size <= 0) {
      throw FormatException('latest.json: "size" inválido: $size');
    }

    final signer = json['signerSha256'];
    final signerSha256 =
        signer is String && signer.isNotEmpty ? signer.toLowerCase() : null;
    if (signerSha256 != null && !_sha256Hex.hasMatch(signerSha256)) {
      throw const FormatException(
        'latest.json: "signerSha256" não é um SHA-256 em hex',
      );
    }

    final commit = json['commit'];
    final builtAt = json['builtAt'];

    return AppRelease(
      versionCode: _int(json, 'versionCode'),
      versionName: _string(json, 'versionName'),
      apkFileName: apk,
      sizeBytes: size,
      sha256: sha256,
      signerSha256: signerSha256,
      commit: commit is String && commit.isNotEmpty ? commit : null,
      builtAt: builtAt is String ? DateTime.tryParse(builtAt) : null,
    );
  }

  /// `versionCode` do Android: o número do pipeline (`CI_PIPELINE_IID`),
  /// inteiro e sempre crescente. É o único campo que decide se há atualização.
  final int versionCode;

  /// Data e hora do build (`2026.10.02.13.46`). Só para exibir.
  final String versionName;

  /// Nome do arquivo do APK, relativo ao canal.
  final String apkFileName;

  final int sizeBytes;

  /// SHA-256 do arquivo do APK, hex minúsculo.
  final String sha256;

  /// SHA-256 do certificado que assinou o APK, hex minúsculo. Nulo quando o
  /// canal não informa.
  final String? signerSha256;

  final String? commit;
  final DateTime? builtAt;

  /// Há atualização só quando o publicado é **estritamente** maior que o
  /// instalado. Igual ou menor é "em dia" — nunca se oferece um downgrade.
  bool isNewerThan(int installedBuildNumber) =>
      versionCode > installedBuildNumber;

  /// Tamanho para exibir, em MB com uma casa e vírgula decimal (`103,4 MB`).
  String get sizeLabel {
    final megabytes = sizeBytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  static final RegExp _apkName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*\.apk$');
  static final RegExp _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    // JSON não distingue 119 de 119.0; aceita o inteiro escrito como double.
    if (value is double && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('latest.json: "$key" ausente ou não é inteiro');
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('latest.json: "$key" ausente ou vazio');
  }

  @override
  List<Object?> get props => [
        versionCode,
        versionName,
        apkFileName,
        sizeBytes,
        sha256,
        signerSha256,
        commit,
        builtAt,
      ];
}
