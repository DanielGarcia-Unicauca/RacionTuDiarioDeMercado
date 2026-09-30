package com.racion.diariomercado.di

import android.content.Context
import com.racion.diariomercado.BuildConfig
import com.racion.diariomercado.data.firebase.FirebaseAuthRepository
import com.racion.diariomercado.data.openfood.OpenFoodFactsService
import com.racion.diariomercado.domain.repository.AuthRepository
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Manual dependency container: the single place where concrete implementations are chosen.
 *
 * ## Why manual DI instead of Hilt (for now)
 * - **Zero annotation processing.** Hilt requires KSP/KAPT on this module, which is pure
 *   build time and configuration surface while the data layer is still `TODO`s.
 * - **Fully explicit.** Every edge is a `by lazy` property you can read top to bottom. With
 *   Hilt, the graph lives in generated code and the runtime cost shows up in a `@Singleton`
 *   whose scope is easy to get subtly wrong.
 * - **Trivially swappable.** Swapping to Hilt later is a mechanical change: these `by lazy`
 *   bodies become `@Provides @Singleton` functions and screens keep depending on the
 *   interfaces in `domain/repository/`, which never change.
 *
 * Everything is `by lazy` so nothing is built until first use, and nothing holds a `Context`
 * beyond the application context (a static `Context` is a leak otherwise).
 */
class AppContainer(private val context: Context) {

    /**
     * MANDATORY (OFF-1): Open Food Facts blocks requests that do not send a proper
     * `User-Agent`. The value comes from `BuildConfig.OPEN_FOOD_FACTS_USER_AGENT`, which is
     * built as `AppName/Version (contact)` — the exact shape their bot filter expects.
     * Without this interceptor the API answers 403/503 and returns nothing.
     */
    private val okHttpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .header("User-Agent", BuildConfig.OPEN_FOOD_FACTS_USER_AGENT)
                    .build()
                chain.proceed(request)
            }
            .apply {
                if (BuildConfig.DEBUG) {
                    // BODY logging is a rate-limit footgun: OFF responses are large and
                    // logging them is pure overhead. HEADERS is enough to debug wiring.
                    addInterceptor(
                        HttpLoggingInterceptor().apply {
                            level = HttpLoggingInterceptor.Level.HEADERS
                        }
                    )
                }
            }
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .build()
    }

    /**
     * The DTOs in `data/openfood/dto` are annotated `@JsonClass(generateAdapter = true)`, which
     * asks Moshi for a *generated* adapter class — and no annotation processor runs in this
     * module yet, so no `*JsonAdapter` class is ever produced.
     *
     * ## Why the factory below is load-bearing
     * It is tempting to read that annotation as a landmine that throws on the first response.
     * It does not, and `MoshiAdapterTest` pins down why. In Moshi 1.15.2 the
     * `@JsonClass(generateAdapter = true)` branch lives inside a **built-in**
     * [com.squareup.moshi.JsonAdapter.Factory], and factories registered on
     * [Moshi.Builder] are consulted *before* the built-ins. So [KotlinJsonAdapterFactory]
     * claims these DTOs first and the missing generated class is never looked up.
     *
     * Build this Moshi **without** the factory and it does throw
     * `RuntimeException: Failed to find the generated JsonAdapter class for class
     * ...OffProductResponseDto`. That is the one change to this block that breaks the OFF
     * integration, and the test guards it.
     *
     * TODO(OFF-1): apply KSP with `libs.squareup.moshi.kotlin.codegen`, at which point the
     * existing `@JsonClass` annotations on the DTOs start doing real work and this factory can
     * be dropped. Codegen is faster, reflection-free, and proguard-safe. Keep the annotation
     * in the meantime: it is inert but harmless, and removing it would only add churn to that
     * migration.
     */
    private val moshi: Moshi by lazy {
        Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()
    }

    private val retrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(BuildConfig.OPEN_FOOD_FACTS_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    /** Retrofit-generated implementation of the OFF endpoints. */
    val openFoodFactsService: OpenFoodFactsService by lazy {
        retrofit.create(OpenFoodFactsService::class.java)
    }

    /**
     * [AuthRepository] backed by Firebase Authentication.
     *
     * The one repository in this container that needs NO constructor argument, because
     * [FirebaseAuthRepository] has no Firebase handle yet — it cannot touch Firebase until the
     * google-services plugin is applied (FF-3) and `FirebaseApp` is initialised (FF-2). It takes
     * none today; it will take `FirebaseAuth.getInstance()` the moment both land, and that is the
     * one signature change this property will see.
     *
     * It is exposed here, rather than left in the TODO block below, because the login screens are
     * real now and they need an interface to bind against. The dependency is on the INTERFACE
     * only — see the note in the TODO block.
     */
    val authRepository: AuthRepository by lazy {
        FirebaseAuthRepository()
    }

    // TODO(OFF-4): expose the repository interfaces once their implementations exist:
    //
    //   val foodCatalogRepository: FoodCatalogRepository by lazy {
    //       OpenFoodFactsCatalogRepository(openFoodFactsService)
    //   }
    //   val diaryRepository: DiaryRepository by lazy { FirestoreDiaryRepository(firestore) }
    //   val goalsRepository: GoalsRepository by lazy { FirestoreGoalsRepository(firestore) }
    //   val profileRepository: ProfileRepository by lazy { FirestoreProfileRepository(firestore) }
    //
    // Screens must depend on the INTERFACES, never on the implementations above, so the
    // Open Food Facts / Firestore choice stays replaceable.
    //
    // TODO(FF-4): `firestore` is FirebaseFirestore.getInstance() created after the
    // setFirestoreSettings() call in RacionApplication.onCreate().
    //
    // TODO(ST-1): once ViewModels exist, scope the repositories to them (or to an explicit
    // application-scoped holder) instead of leaking them into the Activity.
}
