plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.jkreadnlearn.jkreadnlearn"
    // Both of these are set by dependencies, not by preference. Taking the
    // higher of the two keeps them correct if either side moves.
    //
    // compileSdk: permission_handler_android declares compileSdk 37, and AGP
    // fails the build if the app compiles against anything lower:
    //   Dependency ':permission_handler_android' requires libraries and
    //   applications that depend on it to compile against version 37 or later
    //   of the Android APIs. :app is currently compiled against android-36.
    // Flutter 3.47's own default is 36, so this has to be raised explicitly.
    //
    // minSdk: flutter_tts declares minSdkVersion 24. Flutter's default is also
    // 24, but stating the floor as a max keeps the intent visible.
    compileSdk = maxOf(37, flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jkreadnlearn.jkreadnlearn"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
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
