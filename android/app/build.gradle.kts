plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ares.soundwave"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ares.soundwave"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
// Compatibility shim for old plugins that still apply the external Kotlin Gradle plugin
subprojects {
    // afterEvaluate { project ->
    //     if (project.plugins.hasPlugin("kotlin-android")) {
    //         // Ensure a namespace is set (required by AGP 8+)
    //         project.extensions.findByName("android")?.let { androidExt ->
    //             val android = androidExt as com.android.build.api.dsl.LibraryExtension
    //             if (android.namespace == null) {
    //                 android.namespace = "com.lucasjosino.on_audio_query"
    //             }
    //         }
    //     }
    // }
}
