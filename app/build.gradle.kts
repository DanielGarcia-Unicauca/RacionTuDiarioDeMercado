plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    // TODO(FF-3): do NOT apply `alias(libs.plugins.google.services)` yet.
    // Applying the com.google.gms.google-services plugin WITHOUT a real
    // google-services.json in `app/` HARD FAILS the build: the
    // `processDebugGoogleServices` task throws
    // "File google-services.json is missing. The Google Services Plugin cannot
    // function without it." Uncomment only after FF-1/FF-2 are done.
}

android {
    namespace = "com.racion.diariomercado"
    compileSdk {
        version = release(37)
    }

    defaultConfig {
        applicationId = "com.racion.diariomercado"
        minSdk = 30
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        debug {
            // MANDATORY (OFF-1): Open Food Facts blocks generic/absent User-Agent headers.
            // Format must be: AppName/Version (contact)
            //
            // TODO(OFF-1): `contact@example.com` is a PLACEHOLDER. The contact is how Open Food
            // Facts identifies your app and is what they use to unblock you if the API starts
            // rejecting you. Replace it with a real mailbox BEFORE the first real request, or
            // risk an IP ban you have no way to trace back. Better: read it from a gitignored
            // `local.properties` entry so the address never lands in version control.
            buildConfigField("String", "OPEN_FOOD_FACTS_BASE_URL", "\"https://world.openfoodfacts.org/\"")
            buildConfigField("String", "OPEN_FOOD_FACTS_USER_AGENT", "\"RacionTuDiarioDeMercado/${defaultConfig.versionName} (contact@example.com)\"")
        }
        release {
            // MANDATORY (OFF-1): same two fields, release flavour. Same placeholder caveat.
            buildConfigField("String", "OPEN_FOOD_FACTS_BASE_URL", "\"https://world.openfoodfacts.org/\"")
            buildConfigField("String", "OPEN_FOOD_FACTS_USER_AGENT", "\"RacionTuDiarioDeMercado/${defaultConfig.versionName} (contact@example.com)\"")
            optimization {
                enable = false
            }
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)

    // AndroidX foundation extras
    implementation(libs.androidx.core.splashscreen)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)

    // Networking / serialization (OFF-1..OFF-4)
    implementation(libs.squareup.retrofit)
    implementation(libs.squareup.retrofit.converter.moshi)
    implementation(libs.squareup.moshi)
    // Reflection-based Kotlin adapters: what actually deserializes the OFF DTOs today.
    implementation(libs.squareup.moshi.kotlin)
    implementation(libs.squareup.okhttp.logging.interceptor)
    implementation(libs.kotlinx.coroutines.android)

    // Images (product photos from Open Food Facts)
    implementation(libs.io.coil.kt.coil3)
    implementation(libs.io.coil.kt.coil3.compose)

    // Firebase (FF-1..FF-5) - libraries only, the plugin is NOT applied yet.
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.auth)
    implementation(libs.firebase.firestore)
    implementation(libs.firebase.analytics)

    // Barcode scanning (BC-1)
    implementation(libs.play.services.mlkit.barcode.scanning)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.turbine)

    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(libs.androidx.junit)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
    debugImplementation(libs.androidx.compose.ui.tooling)
}
