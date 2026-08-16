import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // Package name приложения в Google Play — совпадает с bundle id iOS (uz.taketool.app).
    // ВНИМАНИЕ: после публикации в Play менять нельзя.
    namespace = "uz.taketool.app"
    // Google Play с 31.08.2026 требует targetSdk 36 для новых приложений и обновлений
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "uz.taketool.app"
        // Яндекс MapKit требует minSdk 26
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Релиз подписываем ТОЛЬКО upload-ключом из key.properties.
            // Раньше был тихий фолбэк на debug-ключ — такой AAB Play отклоняет.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                null
        }
    }
}

// Запрет релизной сборки без upload-ключа (debug-сборки не трогаем)
gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any { it.name.contains("Release") }
    if (wantsRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "android/key.properties не найден — релизная сборка должна быть подписана upload-ключом (upload-keystore.jks)"
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Тот же артефакт, что использует плагин yandex_mapkit — нужен для MapKitFactory.setApiKey в MainActivity
    compileOnly("com.yandex.android:maps.mobile:4.22.0-lite")
}
