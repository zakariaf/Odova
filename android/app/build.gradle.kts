plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.applander.odova"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications REQUIRES this — its AAR metadata declares
        // it, and `flutter build apk` fails outright without it rather than
        // degrading. The plugin uses java.time on a minSdk of 26, and
        // desugaring is what backfills the parts of it that are not on every
        // API 26 device.
        //
        // Found by CI, not by a test: the `flutter` and `goldens` lanes were
        // both green and the app simply would not assemble. That is what the
        // android lane is for, and it is the reason this repo compiles for a
        // real target on every PR.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "io.applander.odova"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // SPEC.md §17 Targets: Android 8.0 / API 26+. Pinned rather than read
        // from flutter.minSdkVersion, which moves with the toolchain.
        minSdk = 26
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
    // Pinned, like every other version in this repo. The plugin's README names
    // 2.1.4 as its floor; a caret here would let a Gradle resolution move the
    // toolchain with no diff to review.
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
