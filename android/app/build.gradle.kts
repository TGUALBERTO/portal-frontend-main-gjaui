import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release. O Android so instala uma atualizacao por cima do app
// se ela vier assinada com o MESMO certificado, entao o release precisa de um
// keystore fixo, e nao da chave de debug (que e diferente em cada maquina).
//
// O keystore e a senha NAO ficam no repositorio: vem de `android/key.properties`
// (ignorado pelo git). No CI o job `build_apk` monta esse arquivo a partir das
// variaveis ANDROID_KEYSTORE_*; na maquina do dev quem gera e o
// `scripts/gen-android-keystore.ps1 -WriteKeyProperties`.
//
// Sem o arquivo o release continua assinado com a chave de debug, para
// `flutter run --release` funcionar em qualquer maquina. Ver
// docs/ANDROID_ASSINATURA_RELEASE.md.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKeystore) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

fun keystoreProperty(name: String): String =
    requireNotNull(keystoreProperties.getProperty(name)) {
        "android/key.properties sem a propriedade '$name'"
    }

android {
    namespace = "com.gja.gjamobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.gja.gjamobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Required by flutter_appauth — scheme used by Microsoft OAuth2
        // redirect. The explicit RedirectUriReceiverActivity in the manifest
        // restricts matching to scheme+host, but AppAuth still checks this.
        // Dedicated reverse-domain scheme (not `msauth`) to avoid the Microsoft
        // Authenticator broker hijacking the redirect.
        manifestPlaceholders["appAuthRedirectScheme"] = "com.gja.gjamobile"
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                // Caminho absoluto, ou relativo a android/app. Em .properties a
                // barra invertida e escape: use sempre "/" (C:/Users/...).
                storeFile = file(keystoreProperty("storeFile"))
                storePassword = keystoreProperty("storePassword")
                keyAlias = keystoreProperty("keyAlias")
                // Keystore PKCS12 tem uma senha so: a da chave e a do store.
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: keystoreProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hasReleaseKeystore) "release" else "debug"
            )
        }
    }
}

flutter {
    source = "../.."
}
