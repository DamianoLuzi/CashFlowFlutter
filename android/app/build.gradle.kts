plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    //id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutterapp"
    compileSdk = flutter.compileSdkVersion
    //ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    //compileOptions {
    //    sourceCompatibility = JavaVersion.VERSION_11
    //    targetCompatibility = JavaVersion.VERSION_11
    //}

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutterapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
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
    implementation ("androidx.window:window:1.0.0")
    implementation ("androidx.window:window-java:1.0.0")
    coreLibraryDesugaring ("com.android.tools:desugar_jdk_libs:2.1.4")
}
configurations.all {
    resolutionStrategy {
        // Force a specific version for a transitive dependency
        force("com.android.tools:desugar_jdk_libs:2.1.4")

        // Optionally, for more granular control if 'force' doesn't work alone,
        // you can use 'eachDependency'. However, 'force' is usually sufficient.
        /*
        eachDependency {
            if (requested.group == "com.android.tools" && requested.name == "desugar_jdk_libs") {
                useVersion("2.1.4")
                because "flutter_local_notifications requires 2.1.4 or higher"
            }
        }
        */
    }
}

// Apply the Google services plugin the old way in Kotlin DSL:
apply(plugin = "com.google.gms.google-services")

flutter {
    source = "../.."
}
