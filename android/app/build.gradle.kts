import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sawa.sawa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        applicationId = "com.sawa.sawa"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.play:feature-delivery:2.1.0")
    implementation("com.google.android.play:core-common:2.0.4")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

val sanitizeReleaseGeneratedPluginRegistrant by tasks.registering {
    doLast {
        val registrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
        if (!registrant.exists()) return@doLast

        val original = registrant.readText()
        val blockedPlugins = listOf(
            "flutter_native_splash" to
                "net\\.jonhanson\\.flutter_native_splash\\.FlutterNativeSplashPlugin",
            "integration_test" to
                "dev\\.flutter\\.plugins\\.integration_test\\.IntegrationTestPlugin",
        )

        var sanitized = original
        for ((pluginName, pluginClassPattern) in blockedPlugins) {
            sanitized = sanitized.replace(
                Regex(
                    "\\s*try \\{\\s*" +
                        "flutterEngine\\.getPlugins\\(\\)\\.add\\(new $pluginClassPattern\\(\\)\\);\\s*" +
                        "\\} catch \\(Exception e\\) \\{\\s*" +
                        "Log\\.e\\(TAG, \"Error registering plugin $pluginName, $pluginClassPattern\", e\\);\\s*" +
                        "\\}",
                    RegexOption.DOT_MATCHES_ALL,
                ),
                "",
            )
        }

        if (sanitized != original) {
            registrant.writeText(sanitized)
            println("Sanitized release GeneratedPluginRegistrant.java")
        }
    }
}

tasks.matching { it.name == "compileReleaseJavaWithJavac" }.configureEach {
    dependsOn(sanitizeReleaseGeneratedPluginRegistrant)
}
