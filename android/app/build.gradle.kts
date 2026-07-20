import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.example.escaner_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            val storeFileValue = keystoreProperties["storeFile"] as? String
            if (storeFileValue.isNullOrBlank()) {
                throw GradleException(
                    "key.properties: 'storeFile' no definido. Genera el keystore y completa android/key.properties"
                )
            }
            storeFile = file(storeFileValue)
            storePassword = keystoreProperties["storePassword"] as? String
                ?: throw GradleException("key.properties: 'storePassword' no definido")
            keyAlias = keystoreProperties["keyAlias"] as? String
                ?: throw GradleException("key.properties: 'keyAlias' no definido")
            keyPassword = keystoreProperties["keyPassword"] as? String
                ?: throw GradleException("key.properties: 'keyPassword' no definido")
        }
    }

    defaultConfig {
        applicationId = "com.example.escaner_1"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    applicationVariants.configureEach {
        outputs.configureEach {
            (this as? ApkVariantOutputImpl)?.outputFileName =
                "SIGA-Escaner-${buildType.name}.apk"
        }
    }
}

flutter {
    source = "../.."
}
