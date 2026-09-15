import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Dedicated test identity keeps runner install/uninstall away from normal app data.
val storageQa = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { String(Base64.getDecoder().decode(it)) == "STORAGE_QA=true" } == true

// Optional, machine-local shared development key. Keep private keys out of Git
// and do not replace the user's global Android debug key for other projects.
val localSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("debug-signing.properties")
    if (propertiesFile.exists()) propertiesFile.inputStream().use { load(it) }
}
val developmentKeyPath = localSigningProperties.getProperty("uiLab.debugKeystore")

android {
    namespace = "com.maintainiac.ui_lab_2_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    if (!developmentKeyPath.isNullOrBlank()) {
        val developmentKey = rootProject.file(developmentKeyPath)
        require(developmentKey.isFile) {
            "Configured UI Lab development signing key is missing: $developmentKey"
        }
        signingConfigs.getByName("debug") {
            storeFile = developmentKey
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    if (storageQa) {
        sourceSets.getByName("debug") {
            java.srcDir("src/storageQa/java")
            manifest.srcFile("src/storageQa/AndroidManifest.xml")
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = if (storageQa) "com.maintainiac.ui_lab_2_1.storageqa" else "com.tameyourbiz.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        multiDexEnabled = true
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
