import java.util.Base64
import java.util.Properties
import java.security.KeyStore
import java.security.MessageDigest

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Dedicated test identity keeps runner install/uninstall away from normal app data.
val storageQa = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { String(Base64.getDecoder().decode(it)) == "STORAGE_QA=true" } == true

// Machine-local shared development key. Keep private keys out of Git
// and do not replace the user's global Android debug key for other projects.
val localSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("debug-signing.properties")
    if (propertiesFile.exists()) propertiesFile.inputStream().use { load(it) }
}
val developmentKeyPath = localSigningProperties.getProperty("uiLab.debugKeystore")
require(storageQa || !developmentKeyPath.isNullOrBlank()) {
    "UI Lab development signing is not configured. Set uiLab.debugKeystore in " +
        "android/debug-signing.properties to the shared Mac/HP development key. " +
        "See docs/android_development_signing.md. No machine-default key will be substituted."
}

android {
    namespace = "com.maintainiac.ui_lab_2_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    if (!developmentKeyPath.isNullOrBlank()) {
        val developmentKey = rootProject.file(developmentKeyPath)
        require(developmentKey.isFile) {
            "Configured UI Lab development signing key is missing: $developmentKey"
        }
        val keyStore = KeyStore.getInstance(developmentKey, "android".toCharArray())
        val certificate = requireNotNull(keyStore.getCertificate("androiddebugkey")) {
            "The shared development key must contain the androiddebugkey certificate."
        }
        val fingerprint = MessageDigest.getInstance("SHA-256")
            .digest(certificate.encoded).joinToString("") { "%02x".format(it) }
        require(fingerprint == "bde55b812494eb3c0451c9011b53feda5be6fe9546f48555915c2c5f766c4189") {
            "Wrong UI Lab development signing certificate. Use the verified shared Mac/HP key; " +
                "do not uninstall the app or substitute another key."
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
    testOptions {
        unitTests.isIncludeAndroidResources = true
    }
}

dependencies {
    // Direct async provider avoids the reference wrapper's persistent DataStore.
    implementation("com.google.android.gms:play-services-deviceperformance:16.0.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.16")
    val receiptCameraXVersion = "1.5.0"
    implementation("androidx.camera:camera-core:$receiptCameraXVersion")
    implementation("androidx.camera:camera-camera2:$receiptCameraXVersion")
    implementation("androidx.camera:camera-lifecycle:$receiptCameraXVersion")
    implementation("androidx.camera:camera-view:$receiptCameraXVersion")
    implementation("androidx.exifinterface:exifinterface:1.4.2")
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

// AGP host-test packaging consumes Flutter's merged assets. Declare the producer
// explicitly so Gradle 9 cannot package tests before Flutter copies those assets.
tasks.configureEach {
    if (name == "packageDebugUnitTestForUnitTest") {
        dependsOn("copyFlutterAssetsDebug")
    }
}
