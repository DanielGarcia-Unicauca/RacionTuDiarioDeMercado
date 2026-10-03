plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    // FF-3 DONE. The plugin IS applied, and the precondition it warned about is met: FF-1 landed a
    // real `app/google-services.json` (project_id `racion-tu-diario-de-mercado`, package_name
    // `com.racion.diariomercado`), so `processDebugGoogleServices` has a file to read.
    //
    // What this plugin actually does, since it is invisible and that is confusing: it does NOT talk
    // to Firebase and it does NOT authenticate anything. It reads `google-services.json` at BUILD
    // time and GENERATES resource values from it, which is the only way the runtime can learn the
    // project id and API key. Without it the file sits in `app/` unread, and `FirebaseApp` has no
    // project to connect to — the "phone with no SIM card" case.
    //
    // Keep this line above the "do not remove" markers: deleting it does not fail the build loudly,
    // it just makes every Firebase call fail at runtime instead.
    alias(libs.plugins.google.services)
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
