/// O que a atualização do app precisa do Android e o Dart não alcança sozinho.
///
/// Contrato na `domain` para o controller poder ser testado com um fake; a
/// implementação real fala com o canal de `MainActivity.kt`.
abstract interface class AppUpdatePlatform {
  /// SHA-256 (hex minúsculo) do certificado que assinou o app **instalado**.
  Future<String> signerSha256();

  /// Entrega o APK em [path] ao instalador do sistema. O arquivo tem de estar na
  /// pasta de cache da atualização, a única que o FileProvider expõe.
  ///
  /// Retorna quando o instalador foi aberto, não quando a instalação terminou:
  /// daí em diante o Android assume, e o processo do app é encerrado se o
  /// usuário confirmar.
  Future<void> installApk(String path);
}
