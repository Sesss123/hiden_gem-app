plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

layout.buildDirectory.set(file("../../build/app"))

android {
    namespace = "com.hidden.gems.hidden_gems_sl"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // 🔥 IMPORTANT FIX (Java 9+ compatibility)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.hidden.gems.hidden_gems_sl"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { project.file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                if (project.hasProperty("allowDebugSigningForRelease") || System.getenv("ALLOW_DEBUG_SIGNING") == "true") {
                    println("================================================================================")
                    println("⚠️  WARNING: RELEASE BUILD SIGNED WITH DEBUG KEY (allowDebugSigningForRelease is set)!")
                    println("================================================================================")
                    signingConfigs.getByName("debug")
                } else {
                    throw GradleException("❌ RELEASE BUILD FAILED: android/key.properties is missing! To build a release APK with debug keys for local testing, pass -PallowDebugSigningForRelease=true or set ALLOW_DEBUG_SIGNING=true.")
                }
            }
        }
    }
}

dependencies {
    // 🔥 REQUIRED for Java 17 + older plugins (ARCore fix)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}