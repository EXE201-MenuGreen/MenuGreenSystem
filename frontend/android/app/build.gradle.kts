plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase: apply sau Flutter plugin (đọc google-services.json)
    id("com.google.gms.google-services")
}

// Load signing configuration from key.properties
import java.util.Properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
val hasReleaseSigningConfig =
    listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
        .all { !keystoreProperties.getProperty(it).isNullOrBlank() }
val allowDebugReleaseSigning =
    System.getenv("ALLOW_DEBUG_RELEASE_SIGNING")?.equals("true", ignoreCase = true) == true

android {
    namespace = "com.menugreen.food"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "AndroidDebugKey"
            keyPassword = "android"
        }
        if (hasReleaseSigningConfig) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.menugreen.food"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Ensure AGP picks up libapp.so produced by Flutter Gradle plugin's AOT step.
        ndk {
            // no abiFilters override here - let --target-platform drive it
        }
    }

    // Include Flutter's AOT-compiled libapp.so into the APK packaging.
    sourceSets {
        getByName("main") {
            jniLibs.srcDirs(
                "src/main/jniLibs",
                "../../build/app/intermediates/flutter/release/jniLibs",
            )
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigningConfig) {
                signingConfig = signingConfigs.getByName("release")
            } else if (allowDebugReleaseSigning) {
                // Explicit opt-in for disposable LAN/test artifacts only.
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any { it.name.contains("Release", ignoreCase = true) }
    if (releaseRequested && !hasReleaseSigningConfig && !allowDebugReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Provide android/key.properties or explicitly set " +
                "ALLOW_DEBUG_RELEASE_SIGNING=true for a disposable LAN/test build.",
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
