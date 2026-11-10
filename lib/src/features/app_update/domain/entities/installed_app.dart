/// O build instalado no aparelho.
///
/// - [buildNumber]: no Android é o `versionCode`, o número do pipeline que gerou
///   o APK. É o que se compara com o `versionCode` publicado no canal.
/// - [versionName]: data e hora do build, o mesmo texto da tela de login. Só
///   para exibir.
typedef InstalledApp = ({int buildNumber, String versionName});
