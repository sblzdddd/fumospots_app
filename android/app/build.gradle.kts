import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.lc_022.fumospots"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.lc_022.fumospots"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Enables R8 code shrinking, obfuscation, and optimization.
            // Kotlin DSL exposes the Java is*/set* methods as isMinifyEnabled.
            isMinifyEnabled = true

            // Removes unused resources (images, layouts) from dependencies.
            isShrinkResources = true

            // Uses the aggressive optimize ProGuard ruleset
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }

            signingConfig = signingConfigs.getByName("release")
        }
    }

    // AGP output names (build/app/outputs/apk/...). Flutter later copies into
    // flutter-apk/ and renames to app-<abi>-<mode>.apk; see afterEvaluate below.
    applicationVariants.all {
        val variant = this
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
            val versionName = variant.versionName ?: defaultConfig.versionName ?: "0.0.0"
            val arch = output.getFilter(com.android.build.OutputFile.ABI) ?: "universal"
            output.outputFileName = "Fumospots_${versionName}_${arch}.apk"
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

afterEvaluate {
    val versionName = android.defaultConfig.versionName ?: "0.0.0"
    val splitApk = Regex("""^app-(armeabi-v7a|arm64-v8a|x86_64)-(debug|profile|release)\.apk$""")
    val universalApk = Regex("""^app-(debug|profile|release)\.apk$""")

    tasks.matching { it.name.startsWith("assemble") }.configureEach {
        doLast {
            val apkDir = layout.buildDirectory.get().asFile.resolve("outputs/flutter-apk")
            if (!apkDir.isDirectory) return@doLast

            apkDir.listFiles()
                ?.filter { it.isFile && it.extension == "apk" }
                ?.toList()
                .orEmpty()
                .forEach { apk ->
                    val arch =
                        splitApk.matchEntire(apk.name)?.groupValues?.get(1)
                            ?: universalApk.matchEntire(apk.name)?.let { "universal" }
                            ?: return@forEach
                    val renamed = apkDir.resolve("Fumospots_${versionName}_${arch}.apk")
                    Files.copy(
                        apk.toPath(),
                        renamed.toPath(),
                        StandardCopyOption.REPLACE_EXISTING,
                    )
                }
        }
    }
}
