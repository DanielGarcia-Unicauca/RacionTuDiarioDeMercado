package com.racion.diariomercado.data.firebase

import com.racion.diariomercado.core.AppResult
import com.racion.diariomercado.domain.repository.AuthRepository
import com.racion.diariomercado.domain.repository.AuthState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf

/**
 * [AuthRepository] backed by Firebase Authentication.
 *
 * This is SCAFFOLDING, not an implementation. It exists so the login screens, the [AuthRepository]
 * contract and the navigation graph can be built and reviewed before a single credential is sent
 * anywhere; every method that would touch Firebase is a `NotImplementedError`.
 *
 * ## Why [authState] returns a value while the commands throw
 * [authState] is a one-line `flowOf(AuthState.Unauthenticated)`, which is honest for a stub: with
 * no Firebase session restored, "not signed in" is the correct emission, and it lets the login
 * screens render and be previewed today. The commands have no honest stub value — there is no
 * [AppResult] that means "authenticate later" — so they throw, matching every other Firestore
 * stub in this package.
 *
 * DEVIATION FROM THE CONTRACT, deliberate and temporary: a real `flowOf` **completes** after one
 * emission, while [AuthRepository.authState] promises a flow that never completes. Nothing breaks
 * today because the only consumer would treat completion as "still unauthenticated", but this
 * must be replaced by a real `callbackFlow` over `FirebaseAuth.addAuthStateListener` (FF-4), not
 * kept as-is.
 *
 * TODO(FF-4): implement all four members against `FirebaseAuth.getInstance()`.
 */
internal class FirebaseAuthRepository : AuthRepository {

    /**
     * TODO(FF-4): bridge `FirebaseAuth.addAuthStateListener` into a `callbackFlow` that emits
     * [AuthState.Authenticated] when `currentUser != null` and [AuthState.Unauthenticated]
     * otherwise, and `awaitClose { removeAuthStateListener(listener) }`. The listener MUST be
     * removed on close or it leaks the collector for the lifetime of the process.
     */
    override val authState: Flow<AuthState> = flowOf(AuthState.Unauthenticated)

    /**
     * TODO(FF-4): `FirebaseAuth.getInstance().signInWithEmailAndPassword(email, password)`,
     * mapping `FirebaseAuthException` error codes onto [com.racion.diariomercado.core.AppError]
     * (`ERROR_NETWORK_REQUEST_FAILED` -> [com.racion.diariomercado.core.AppError.Network],
     * `ERROR_TOO_MANY_REQUESTS` -> [com.racion.diariomercado.core.AppError.RateLimited], and a
     * wrong-credentials code that has no matching case -> [com.racion.diariomercado.core.AppError.Unknown]
     * carrying the exception for logging only).
     */
    override suspend fun signIn(email: String, password: String): AppResult<Unit> =
        // TODO(FF-4): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "FirebaseAuthRepository.signIn is not implemented yet (FF-4)"
        )

    /**
     * TODO(FF-4): `FirebaseAuth.getInstance().createUserWithEmailAndPassword(email, password)`.
     * `ERROR_EMAIL_ALREADY_IN_USE` is the one that matters for the register screen: it must
     * render "esa cuenta ya existe", not a generic failure, so it needs its own case and its own
     * message rather than falling through to [com.racion.diariomercado.core.AppError.Unknown].
     */
    override suspend fun signUp(email: String, password: String): AppResult<Unit> =
        // TODO(FF-4): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "FirebaseAuthRepository.signUp is not implemented yet (FF-4)"
        )

    /**
     * TODO(FF-4): `FirebaseAuth.getInstance().signOut()`. Signing out with no current user is
     * already a no-op there, so it can be reported as a plain success without a pre-check.
     */
    override suspend fun signOut(): AppResult<Unit> =
        // TODO(FF-4): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "FirebaseAuthRepository.signOut is not implemented yet (FF-4)"
        )
}
