import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.projectDir.resolve("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sehaj.amaiyuki"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // We're targetting Java 17 for the build environment compatibility.
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        
        // Enabling core library desugaring so that modern Java APIs 
        // (like java.time used by flutter_local_notifications) work on older Android devices.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // Unique Application ID to avoid conflicts on the device.
        applicationId = "com.sehaj.amaiyuki"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]?.toString()?.trim()
            keyPassword = keystoreProperties["keyPassword"]?.toString()?.trim()
            storeFile = keystoreProperties["storeFile"]?.toString()?.trim()?.let { rootProject.projectDir.resolve("app").resolve(it) }
            storePassword = keystoreProperties["storePassword"]?.toString()?.trim()
        }
    }

    buildTypes {
        release {
            // Signing with the release keys.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add the desugaring engine to support Java 8+ features on pre-API 26 devices.
    // Crucial for dependencies like flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
