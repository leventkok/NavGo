plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

fun readMapsApiKey(rootDir: java.io.File): String {
    val localProps = Properties()
    val localPropsFile = rootDir.resolve("local.properties")
    if (localPropsFile.exists()) {
        FileInputStream(localPropsFile).use { stream -> localProps.load(stream) }
        val fromLocal = localProps.getProperty("MAPS_API_KEY")?.trim().orEmpty()
        if (fromLocal.isNotEmpty()) return fromLocal
    }
    val envFile = rootDir.resolve("../../masterfabric-go/.env")
    if (envFile.exists()) {
        for (line in envFile.readLines()) {
            if (line.startsWith("GOOGLE_MAPS_API_KEY=")) {
                return line.substringAfter("=").trim()
            }
        }
    }
    return ""
}

val mapsApiKey = readMapsApiKey(rootProject.projectDir)

configurations.all {
    resolutionStrategy {
        force("androidx.appcompat:appcompat:1.6.1")
    }
}

android {
    namespace = "com.navgo.navgo_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by masterfabric_core → flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.navgo.navgo_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            resValue("string", "app_name", "NavGo")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "NavGo")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}
