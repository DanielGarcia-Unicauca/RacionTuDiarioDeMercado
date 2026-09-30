package com.racion.diariomercado

import android.app.Application
import com.racion.diariomercado.di.AppContainer

/**
 * Application entry point and owner of the dependency graph.
 *
 * There is no Hilt here on purpose: the object graph is a handful of singletons assembled in
 * [AppContainer], which is cheaper to reason about than an annotation processor and keeps the
 * build fast while the data layer is still being written.
 */
class RacionApplication : Application() {

    /**
     * The object graph. Created once in [onCreate] and read by the Activity.
     * `internal` visibility would be wrong here: [com.racion.diariomercado.MainActivity] is in
     * the same module, but keeping the property readable is what makes the container testable.
     */
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)

        // TODO(FF-2): initialise FirebaseApp here, e.g.
        //   FirebaseApp.initializeApp(this)
        //   FirebaseAuth.getInstance().signInAnonymously()
        // then grab the Firestore instance and configure it ONCE.
        //
        // TRAP (FF-2): FirebaseFirestore.setFirestoreSettings() MUST run before ANY other
        // call on that Firestore instance, including a snapshot listener or a get() —
        // otherwise it throws IllegalStateException at runtime, not at compile time. That is
        // why it belongs here and not lazily inside a repository.
        //
        // Do NOT call the deprecated setPersistenceEnabled(): offline persistence is already
        // ON by default through PersistentCacheSettings, and the old call is ignored on
        // Android in recent SDK versions.
    }
}
