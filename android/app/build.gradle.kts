plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val qaKeystorePath =
    providers.environmentVariable("SCRATCHLESS_QA_KEYSTORE_PATH").orNull.orEmpty()
val qaKeystorePassword =
    providers.environmentVariable("SCRATCHLESS_QA_KEYSTORE_PASSWORD").orNull.orEmpty()
val qaKeyAlias =
    providers.environmentVariable("SCRATCHLESS_QA_KEY_ALIAS").orNull.orEmpty()
val qaKeyPassword =
    providers.environmentVariable("SCRATCHLESS_QA_KEY_PASSWORD").orNull.orEmpty()

val qaSigningValues = listOf(
    qaKeystorePath,
    qaKeystorePassword,
    qaKeyAlias,
    qaKeyPassword,
)
val configuredQaSigningValues = qaSigningValues.count { it.isNotEmpty() }
val hasCompleteQaSigning = configuredQaSigningValues == qaSigningValues.size

val isQaReleaseRequested = gradle.startParameter.taskNames.any { taskName ->
    val normalized = taskName.lowercase()
    normalized.contains("qa") && normalized.contains("release")
}

if (isQaReleaseRequested && configuredQaSigningValues in 1 until qaSigningValues.size) {
    throw GradleException(
        "Incomplete ScratchLess QA signing configuration. Provide every QA signing value.",
    )
}

if (isQaReleaseRequested && !hasCompleteQaSigning) {
    throw GradleException(
        "ScratchLess QA release signing is not configured. Stable QA release builds fail closed.",
    )
}

if (isQaReleaseRequested && hasCompleteQaSigning && !file(qaKeystorePath).isFile) {
    throw GradleException(
        "ScratchLess QA keystore file does not exist at the configured path.",
    )
}

val storeKeystorePath =
    providers.environmentVariable("SCRATCHLESS_STORE_KEYSTORE_PATH").orNull.orEmpty()
val storeKeystorePassword =
    providers.environmentVariable("SCRATCHLESS_STORE_KEYSTORE_PASSWORD").orNull.orEmpty()
val storeKeyAlias =
    providers.environmentVariable("SCRATCHLESS_STORE_KEY_ALIAS").orNull.orEmpty()
val storeKeyPassword =
    providers.environmentVariable("SCRATCHLESS_STORE_KEY_PASSWORD").orNull.orEmpty()
val allowDebugStoreCandidate =
    providers.environmentVariable("SCRATCHLESS_ALLOW_DEBUG_STORE_CANDIDATE").orNull == "true"

val storeSigningValues = listOf(
    storeKeystorePath,
    storeKeystorePassword,
    storeKeyAlias,
    storeKeyPassword,
)
val configuredStoreSigningValues = storeSigningValues.count { it.isNotEmpty() }
val hasCompleteStoreSigning =
    configuredStoreSigningValues == storeSigningValues.size

val isStoreReleaseRequested = gradle.startParameter.taskNames.any { taskName ->
    val normalized = taskName.lowercase()
    normalized.contains("store") && normalized.contains("release")
}

if (isStoreReleaseRequested &&
    configuredStoreSigningValues in 1 until storeSigningValues.size
) {
    throw GradleException(
        "Incomplete ScratchLess Store signing configuration. " +
            "Provide every Store signing value or none of them.",
    )
}

if (isStoreReleaseRequested &&
    !hasCompleteStoreSigning &&
    !allowDebugStoreCandidate
) {
    throw GradleException(
        "ScratchLess Store release signing is not configured. " +
            "Production Store builds fail closed unless signing is complete. " +
            "Only CI candidate builds may explicitly set " +
            "SCRATCHLESS_ALLOW_DEBUG_STORE_CANDIDATE=true.",
    )
}

if (isStoreReleaseRequested &&
    hasCompleteStoreSigning &&
    !file(storeKeystorePath).isFile
) {
    throw GradleException(
        "ScratchLess Store keystore file does not exist at the configured path.",
    )
}

android {
    namespace = "com.cube23.scratchless"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cube23.scratchless"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasCompleteQaSigning) {
            create("qaRelease") {
                storeFile = file(qaKeystorePath)
                storePassword = qaKeystorePassword
                keyAlias = qaKeyAlias
                keyPassword = qaKeyPassword
            }
        }

        if (hasCompleteStoreSigning) {
            create("storeRelease") {
                storeFile = file(storeKeystorePath)
                storePassword = storeKeystorePassword
                keyAlias = storeKeyAlias
                keyPassword = storeKeyPassword
            }
        }
    }

    flavorDimensions += "distribution"

    productFlavors {
        create("qa") {
            dimension = "distribution"
            applicationIdSuffix = ".qa"
            versionNameSuffix = "-qa"
            resValue("string", "app_name", "ScratchLess QA")
            manifestPlaceholders["appIcon"] =
                "@drawable/ic_launcher_qa"
            signingConfig = if (hasCompleteQaSigning) {
                signingConfigs.getByName("qaRelease")
            } else {
                signingConfigs.getByName("debug")
            }
        }

        create("store") {
            dimension = "distribution"
            resValue("string", "app_name", "ScratchLess")
            manifestPlaceholders["appIcon"] =
                "@mipmap/ic_launcher"
            signingConfig = if (hasCompleteStoreSigning) {
                signingConfigs.getByName("storeRelease")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    buildTypes {
        release {
            // Distribution flavors own their signing configuration.
            // QA release builds use the dedicated stable QA signing key.
            // Store is either explicitly candidate-debug or uses the
            // secret-fed Store release signing config.
        }
    }

    packaging {
        resources {
            excludes += "META-INF/versions/9/OSGI-INF/MANIFEST.MF"
        }
    }
}

flutter {
    source = "../.."
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
