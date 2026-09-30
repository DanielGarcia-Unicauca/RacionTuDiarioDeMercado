package com.racion.diariomercado.ui.screens.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.racion.diariomercado.core.AppError
import com.racion.diariomercado.core.AppResult
import com.racion.diariomercado.domain.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Everything the login and register screens render, and nothing else.
 *
 * [confirmPassword] lives here even though only the register screen uses it: the form fields are
 * `remember`ed state today, and moving them into a single state holder is what makes the
 * "validate before the repository" rule below testable at all.
 */
data class LoginUiState(
    val email: String = "",
    val password: String = "",
    /** Only the register screen reads this. It is never sent anywhere. */
    val confirmPassword: String = "",
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val isLoggedIn: Boolean = false
)

/**
 * Drives both auth screens from a single [AuthRepository].
 *
 * ## Why validation lives here and not in the repository
 * Every rule in [submit] is a rule about *what the user is told*, so it belongs above the data
 * layer: a repository that silently rejects a four-character password teaches the UI nothing
 * about which field was wrong. The repository is only called once the input is known to be
 * plausible, which is also what keeps `signIn`/`signUp` from being a network call per keystroke.
 *
 * ## Why `isLoggedIn` duplicates [com.racion.diariomercado.domain.repository.AuthState]
 * It is a navigation signal, not a second source of truth: the screens need to react *once*, on
 * the transition, and then leave the destination. The observable [AuthRepository.authState] is
 * the durable one and is what FF-7 will gate the start route on. Keeping this flag local means a
 * process death cannot leave the app on the login screen believing it is signed in.
 *
 * Strings here are user-facing copy and are therefore in Spanish; everything else in this file,
 * including this KDoc, is English.
 */
class LoginViewModel(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()

    fun updateEmail(email: String) {
        _uiState.update { it.copy(email = email) }
    }

    fun updatePassword(password: String) {
        _uiState.update { it.copy(password = password) }
    }

    fun updateConfirmPassword(confirmPassword: String) {
        _uiState.update { it.copy(confirmPassword = confirmPassword) }
    }

    /**
     * Validates the login form and, only if it passes, calls [AuthRepository.signIn].
     *
     * The repository is not reached on an invalid form — no call, no [isLoading] flag, just the
     * message. This is asserted by the tests, because a version that called first and validated
     * on the response would still *look* correct in the UI while burning a request.
     */
    fun onSignIn() {
        val state = _uiState.value
        validateEmail(state.email)?.let { message ->
            _uiState.update { it.copy(errorMessage = message, isLoading = false) }
            return
        }
        validatePassword(state.password)?.let { message ->
            _uiState.update { it.copy(errorMessage = message, isLoading = false) }
            return
        }

        _uiState.update { it.copy(isLoading = true, errorMessage = null) }
        viewModelScope.launch {
            when (val result = authRepository.signIn(state.email, state.password)) {
                is AppResult.Success -> _uiState.update {
                    it.copy(isLoading = false, isLoggedIn = true, errorMessage = null)
                }
                // isLoading is cleared on the failure branch too: leaving it true would pin the
                // form behind a spinner with no way to retry.
                is AppResult.Failure -> _uiState.update {
                    it.copy(isLoading = false, errorMessage = result.error.toUserMessage())
                }
            }
        }
    }

    /**
     * Validates the register form and, only if it passes, calls [AuthRepository.signUp].
     *
     * Adds the password-match rule on top of [onSignIn]'s: a mismatch is impossible to detect
     * server-side, so if it were not checked here the account would be created with a password
     * the user cannot reproduce on the next sign-in.
     */
    fun onSignUp() {
        val state = _uiState.value
        validateEmail(state.email)?.let { message ->
            _uiState.update { it.copy(errorMessage = message, isLoading = false) }
            return
        }
        validatePassword(state.password)?.let { message ->
            _uiState.update { it.copy(errorMessage = message, isLoading = false) }
            return
        }
        if (state.confirmPassword.isBlank()) {
            _uiState.update {
                it.copy(errorMessage = "Confirmá la contraseña", isLoading = false)
            }
            return
        }
        if (state.confirmPassword != state.password) {
            _uiState.update {
                it.copy(errorMessage = "Las contraseñas no coinciden", isLoading = false)
            }
            return
        }

        _uiState.update { it.copy(isLoading = true, errorMessage = null) }
        viewModelScope.launch {
            when (val result = authRepository.signUp(state.email, state.password)) {
                is AppResult.Success -> _uiState.update {
                    it.copy(isLoading = false, isLoggedIn = true, errorMessage = null)
                }
                is AppResult.Failure -> _uiState.update {
                    it.copy(isLoading = false, errorMessage = result.error.toUserMessage())
                }
            }
        }
    }

    /**
     * Clears the current error. Called by the screen once the message has been on screen long
     * enough to read, so the next attempt starts from a clean form instead of showing a stale
     * complaint next to fields the user has already fixed.
     */
    fun onErrorShown() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    /** @return the message to show, or `null` when [email] is worth sending to the repository. */
    private fun validateEmail(email: String): String? = when {
        email.isBlank() -> "Ingresá tu correo"
        // A single "@" check, not a regex. A full RFC-shaped pattern rejects valid addresses the
        // provider would accept, and this is a typo guard, not a deliverability test.
        !email.contains("@") -> "Ingresá un correo electrónico válido"
        else -> null
    }

    /** @return `null` when [password] is long enough, otherwise the message to show. */
    private fun validatePassword(password: String): String? =
        if (password.length < MIN_PASSWORD_LENGTH) {
            "La contraseña debe tener al menos 6 caracteres"
        } else {
            null
        }

    /**
     * The user-facing text for a failure.
     *
     * Every [AppError] case gets its own sentence on purpose: a shared "algo salió mal" for both
     * "no connection" and "server error" tells the user nothing about whether retrying helps,
     * which is the only decision the message exists to inform.
     */
    private fun AppError.toUserMessage(): String = when (this) {
        AppError.Network -> "Sin conexión. Revisá tu internet e intentá de nuevo."
        AppError.NotFound -> "No encontramos esos datos."
        AppError.RateLimited -> "Demasiados intentos. Esperá un momento."
        is AppError.Server -> "No pudimos completar la operación. Intentá de nuevo."
        is AppError.Unknown -> "Ocurrió un error inesperado. Intentá de nuevo."
    }

    private companion object {
        /** Firebase's own minimum. Matching it here means the local rule never fights the server. */
        const val MIN_PASSWORD_LENGTH = 6
    }
}
