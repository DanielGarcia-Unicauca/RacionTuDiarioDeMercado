package com.racion.diariomercado.domain.repository

import com.racion.diariomercado.core.AppResult
import kotlinx.coroutines.flow.Flow

/**
 * Whether the app currently has a signed-in user.
 *
 * It is a two-state sealed interface and not a nullable `User` on purpose: the screens branch on
 * *authenticated / not authenticated*, never on a particular provider's user object, and a
 * `sealed` makes an unhandled third state a compile error instead of a runtime `null` deref.
 *
 * Note there is deliberately no "loading" state. [AuthRepository.authState] must emit a value as
 * soon as the persisted session is known, and a screen that has not heard back yet is better
 * modelled by its own local flag than by a global third state that every screen would then have
 * to special-case.
 */
sealed interface AuthState {
    /** No signed-in user: the sign-in / sign-up screens are the only reachable destinations. */
    data object Unauthenticated : AuthState

    /** A signed-in user. The uid lives in the repository, not here — no screen needs it yet. */
    data object Authenticated : AuthState
}

/**
 * Email/password authentication and the observable session it produces.
 *
 * Contract:
 * - The session is observable ([authState]) because it changes from *outside* the screen: a token
 *   refresh, a sign-out triggered from another destination, or a restored session on process
 *   death all move it without the user touching the login form.
 * - The commands are `suspend` and return [AppResult]; a network failure is a value on the
 *   result, never an exception on the caller's coroutine. The UI must be able to render a
 *   message for every one of those cases, and a thrown exception cannot be rendered that way.
 * - The implementation owns credential validation beyond what a `TextField` can express. The
 *   ViewModel still validates the obvious cases (blank, malformed, too short) *before* calling,
 *   because that is a UX decision, not a data-layer one — see `LoginViewModel`.
 */
interface AuthRepository {

    /**
     * The current session, re-emitting on every change.
     *
     * The returned flow must never complete and never throw: a collector that has to wrap
     * `collect` in `try/catch` and handle a `CompletionException` will eventually get it wrong,
     * and "we could not read the session" is [AuthState.Unauthenticated] as far as the UI is
     * concerned, not an error state the user can act on.
     */
    val authState: Flow<AuthState>

    /**
     * Signs in an existing user.
     *
     * Returns [AppResult] of [Unit]: the session afterwards is read from [authState], not from
     * the return value, so a "success" that carries a `User` object would be a second source of
     * truth for the same fact.
     */
    suspend fun signIn(email: String, password: String): AppResult<Unit>

    /**
     * Creates a new account. A provider that rejects a duplicate address maps that to
     * [com.racion.diariomercado.core.AppError.Server], not to a thrown exception, so the screen
     * can tell "already registered" from "no connection".
     */
    suspend fun signUp(email: String, password: String): AppResult<Unit>

    /**
     * Ends the session. Signing out when nobody is signed in is a no-op success, not a failure:
     * the observable end state the user cares about is already correct.
     */
    suspend fun signOut(): AppResult<Unit>
}
