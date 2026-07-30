import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun signingValue(environmentName: String, propertyName: String): String? =
    providers.environmentVariable(environmentName).orNull
        ?: keystoreProperties.getProperty(propertyName)

val uploadStoreFile = signingValue("AQUAHUNTER_UPLOAD_STORE_FILE", "storeFile")
val uploadStorePassword = signingValue(
    "AQUAHUNTER_UPLOAD_STORE_PASSWORD",
    "storePassword",
)
val uploadKeyAlias = signingValue("AQUAHUNTER_UPLOAD_KEY_ALIAS", "keyAlias")
val uploadKeyPassword = signingValue(
    "AQUAHUNTER_UPLOAD_KEY_PASSWORD",
    "keyPassword",
)
val hasUploadSigning = listOf(
    uploadStoreFile,
    uploadStorePassword,
    uploadKeyAlias,
    uploadKeyPassword,
).all { !it.isNullOrBlank() }

val validateReleaseDataSources by tasks.registering(Exec::class) {
    group = "verification"
    description = "Blocks release builds without approved commercially reusable data sources."
    workingDir(rootProject.projectDir.parentFile)
    commandLine("python3", "tools/validate_data_sources.py", "--release")
}

val validateReleaseContent by tasks.registering(Exec::class) {
    group = "verification"
    description = "Blocks release builds that still contain fixtures or blocked map code."
    workingDir(rootProject.projectDir.parentFile)
    commandLine("python3", "tools/validate_release_content.py")
}

val validateCommerceCatalog by tasks.registering(Exec::class) {
    group = "verification"
    description =
        "Blocks release builds when paid features use data without commercial derivative rights."
    workingDir(rootProject.projectDir.parentFile)
    commandLine("python3", "tools/validate_commerce_catalog.py")
}

val validateReleaseSigning by tasks.registering {
    group = "verification"
    description = "Blocks release builds that do not have AquaHunter upload signing."
    doLast {
        check(hasUploadSigning) {
            "AquaHunter release signing is missing. Run android/scripts/create_upload_keystore.sh " +
                "and android/scripts/build_signed_release.sh instead of producing an unsigned AAB."
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild") {
        dependsOn(
            validateReleaseDataSources,
            validateCommerceCatalog,
            validateReleaseContent,
            validateReleaseSigning,
        )
    }
}

android {
    namespace = "com.hotseason.aquahunter"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.hotseason.aquahunter"
        minSdk = 26
        targetSdk = 36
        versionCode = 3
        versionName = "1.1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    signingConfigs {
        if (hasUploadSigning) {
            create("release") {
                storeFile = file(uploadStoreFile!!)
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.findByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    sourceSets {
        getByName("main").assets.srcDir("../../map-assets")
        getByName("main").assets.srcDir("../../commerce")
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.06.00")

    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.maplibre.gl:android-sdk-opengl:13.0.2")
    implementation("com.android.billingclient:billing-ktx:9.1.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250517")

    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")

    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
