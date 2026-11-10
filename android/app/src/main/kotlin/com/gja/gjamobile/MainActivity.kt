package com.gja.gjamobile

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * Além de hospedar o Flutter, expõe o canal `com.gja.gjamobile/app_update`, usado
 * pela feature de atualização do app (`lib/src/features/app_update`). São as duas
 * coisas que o Dart não consegue fazer sozinho:
 *
 *  - `signerSha256`: SHA-256 do certificado que assinou ESTE apk. O app só oferece
 *    a atualização se for o mesmo certificado do APK publicado, porque o Android
 *    recusa instalar por cima com assinatura diferente.
 *  - `installApk`: entrega o APK baixado ao instalador do sistema.
 *
 * Um canal próprio em vez de um plugin: são poucas linhas, e cada plugin a mais é
 * um ponto de quebra na migração do Flutter para o Kotlin embutido.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "signerSha256" -> result.success(signerSha256())
                        "installApk" -> {
                            val path = call.argument<String>("path")
                            if (path.isNullOrEmpty()) {
                                result.error("invalid_args", "argumento 'path' ausente", null)
                            } else {
                                installApk(path)
                                result.success(null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("app_update_failed", e.message ?: e.javaClass.simpleName, null)
                }
            }
    }

    /**
     * Mesmo valor que o `apksigner verify --print-certs` chama de
     * "Signer #1 certificate SHA-256 digest" e que o pipeline grava em
     * `latest.json` como `signerSha256`: hex minúsculo, sem separadores.
     */
    private fun signerSha256(): String {
        val certificate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val info = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNING_CERTIFICATES,
            )
            val signingInfo = checkNotNull(info.signingInfo) { "pacote sem signingInfo" }
            // apkContentsSigners é quem assinou este APK. O
            // signingCertificateHistory incluiria chaves antigas de uma rotação.
            signingInfo.apkContentsSigners.first()
        } else {
            @Suppress("DEPRECATION")
            val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            @Suppress("DEPRECATION")
            checkNotNull(info.signatures) { "pacote sem signatures" }.first()
        }
        val digest = MessageDigest.getInstance("SHA-256").digest(certificate.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }

    /**
     * Abre o instalador do Android para o APK em [path].
     *
     * O arquivo precisa estar em `cacheDir/app_update/`, a única pasta que o
     * [AppUpdateFileProvider] expõe (ver `res/xml/app_update_paths.xml`). A partir
     * do Android 7 um `file://` para outro app lança FileUriExposedException; o
     * instalador recebe um `content://` com permissão de leitura só para ele.
     *
     * Não se confere antes a permissão de "instalar apps desconhecidos": sem ela o
     * próprio instalador explica, leva à configuração e volta para a instalação.
     * Declarar REQUEST_INSTALL_PACKAGES no manifest é o que habilita esse caminho.
     */
    private fun installApk(path: String) {
        val file = File(path)
        require(file.isFile) { "arquivo não encontrado: $path" }

        val uri = FileProvider.getUriForFile(this, "$packageName.appupdate", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private companion object {
        const val APP_UPDATE_CHANNEL = "com.gja.gjamobile/app_update"
    }
}

/**
 * FileProvider próprio da feature de atualização. Uma subclasse, e não o
 * `androidx.core.content.FileProvider` direto no manifest: o merge de manifests
 * junta `<provider>` pelo nome da classe, e um plugin que declarasse o mesmo nome
 * com outra authority quebraria o build.
 */
class AppUpdateFileProvider : FileProvider()
