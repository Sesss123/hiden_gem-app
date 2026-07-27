plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// A custom layout.buildDirectory.set(file("../../build/app")) redirect used
// to live here. Removed: it ran after the Flutter Gradle plugin's own
// plugins{} application above already captured the default build directory
// for jniLibs source-set wiring (FlutterPlugin.kt's sourceSets.all{} block
// resolves the intermediates path eagerly at apply time), so libapp.so was
// compiled into the redirected build/app/... tree but Android's native-lib
// merge kept looking in the default android/app/build/... tree, silently
// dropping the app's own compiled code from every release APK. Flutter's
// default build output location (android/app/build) is used instead.

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

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    val localPropertiesFile = rootProject.file("local.properties")
    val localProperties = Properties()
    if (localPropertiesFile.exists()) {
        localProperties.load(FileInputStream(localPropertiesFile))
    }
    val mapsApiKey = localProperties["MAPS_API_KEY"] as String? ?: ""

    defaultConfig {
        applicationId = "com.hidden.gems.hidden_gems_sl"
        minSdk = 28
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
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

    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
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