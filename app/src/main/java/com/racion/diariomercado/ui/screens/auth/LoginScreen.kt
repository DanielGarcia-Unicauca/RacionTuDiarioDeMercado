package com.racion.diariomercado.ui.screens.auth

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.racion.diariomercado.ui.theme.NutriAppTheme
import kotlinx.coroutines.delay

/**
 * Sign-in form. Stateless by construction: it renders a [LoginUiState] and reports intent through
 * lambdas, so the same composable is used by the navigation graph, by `@Preview`, and by any
 * future screenshot test without a ViewModel in reach.
 *
 * Note there is no Scaffold here and no `AppBottomBar`. Every other screen in the app renders its
 * own, but the auth screens are a modal flow outside the tabbed shell — showing the bottom bar
 * here would let the user tab away into a destination that assumes a session.
 */
@Composable
fun LoginScreen(
    state: LoginUiState,
    onEmailChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    onSignIn: () -> Unit,
    onSignUpClick: () -> Unit,
    onErrorShown: () -> Unit,
    modifier: Modifier = Modifier
) {
    // The message is cleared on a timer instead of on the next keystroke: clearing it as the user
    // types is unreadable, because the complaint about a 4-character password disappears after the
    // fifth character and the user never learns what was wrong.
    LaunchedEffect(state.errorMessage) {
        if (state.errorMessage != null) {
            delay(ERROR_VISIBLE_MILLIS)
            onErrorShown()
        }
    }

    Scaffold(modifier = modifier) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .imePadding()
                .padding(horizontal = 24.dp, vertical = 32.dp),
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Iniciar sesión",
                style = MaterialTheme.typography.headlineLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "Ingresá a tu cuenta para ver tu diario",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(32.dp))

            OutlinedTextField(
                value = state.email,
                onValueChange = onEmailChange,
                label = { Text("Correo electrónico") },
                singleLine = true,
                enabled = !state.isLoading,
                isError = state.errorMessage != null,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Next
                ),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(16.dp))

            OutlinedTextField(
                value = state.password,
                onValueChange = onPasswordChange,
                label = { Text("Contraseña") },
                singleLine = true,
                enabled = !state.isLoading,
                isError = state.errorMessage != null,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done
                ),
                modifier = Modifier.fillMaxWidth()
            )

            if (state.errorMessage != null) {
                Spacer(Modifier.height(12.dp))
                Text(
                    text = state.errorMessage,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }

            Spacer(Modifier.height(28.dp))

            Button(
                onClick = onSignIn,
                // Disabled while loading AND the spinner: without the disable, a double tap fires
                // two sign-in calls, which is exactly how an account gets rate-limited.
                enabled = !state.isLoading,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
            ) {
                if (state.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.height(24.dp),
                        strokeWidth = 2.dp,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Text("Iniciar sesión", style = MaterialTheme.typography.titleLarge)
                }
            }

            Spacer(Modifier.height(12.dp))

            TextButton(
                onClick = onSignUpClick,
                enabled = !state.isLoading,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            ) {
                Text("¿No tenés cuenta? Crear cuenta")
            }
        }
    }
}

/** How long an error stays on screen before it clears itself. */
private const val ERROR_VISIBLE_MILLIS = 4_000L

@Preview(showBackground = true)
@Composable
private fun LoginScreenPreview() {
    NutriAppTheme {
        LoginScreen(
            state = LoginUiState(),
            onEmailChange = {},
            onPasswordChange = {},
            onSignIn = {},
            onSignUpClick = {},
            onErrorShown = {}
        )
    }
}

@Preview(showBackground = true, name = "Login · con error")
@Composable
private fun LoginScreenErrorPreview() {
    NutriAppTheme {
        LoginScreen(
            state = LoginUiState(
                email = "julia@ejemplo.com",
                password = "123",
                errorMessage = "La contraseña debe tener al menos 6 caracteres"
            ),
            onEmailChange = {},
            onPasswordChange = {},
            onSignIn = {},
            onSignUpClick = {},
            onErrorShown = {}
        )
    }
}
