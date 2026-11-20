import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase (notifications push, D-68) : le fichier google-services.json n'est
// pas dans le dépôt ; la CI l'écrit depuis le secret GOOGLE_SERVICES_JSON.
// Sans lui, l'application fonctionne sans notifications push.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.ridergroup.rider_group"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ridergroup.rider_group"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signature de production (SEC-01). La clé n'est JAMAIS dans le dépôt :
    // - en CI : variables d'environnement alimentées par les secrets GitHub ;
    // - en local : fichier android/key.properties (ignoré par git).
    // Sans clé (contributeur, test local), on retombe sur la clé de débogage.
    val keyProps = Properties().apply {
        val f = rootProject.file("key.properties")
        if (f.exists()) f.inputStream().use { load(it) }
    }
    fun signingValue(env: String, prop: String): String? =
        System.getenv(env)?.takeIf { it.isNotBlank() } ?: keyProps.getProperty(prop)
    val releaseStore = signingValue("RIDER_KEYSTORE_PATH", "storeFile")
    val hasReleaseKey = releaseStore != null && file(releaseStore).exists()

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(releaseStore!!)
                storePassword = signingValue("RIDER_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = signingValue("RIDER_KEY_ALIAS", "keyAlias")
                keyPassword = signingValue("RIDER_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
