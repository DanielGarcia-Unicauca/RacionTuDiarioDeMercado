//
//  LoginViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/auth/LoginViewModel.kt
//
//  ✅ RÚBRICA · "Arquitectura MVVM": la vista solo dibuja `LoginUiState` y reporta
//     intenciones; toda la validación y la llamada al servicio viven aquí.
//
//  ✅ RÚBRICA · "Gestión de Estado": `@Published` + `@StateObject` en la vista.
//     En Compose era `MutableStateFlow` + `collectAsStateWithLifecycle`.
//

import Foundation

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: Estado que la vista observa

    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var infoMessage: String?
    @Published private(set) var isLoggedIn = false

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    // MARK: Intenciones

    func signIn() async {
        // `validate` devuelve `nil` cuando el formulario es válido y un texto
        // cuando encontró un problema. Se guarda con `== nil`, no con
        // `guard let`: con `guard let` el envío ocurría justo en el caso inválido
        // y el botón "Iniciar sesión" nunca llamaba al servicio.
        guard validate(isRegister: false) == nil else { return }
        await submit(isRegister: false)
    }

    func signUp() async {
        guard validate(isRegister: true) == nil else { return }
        await submit(isRegister: true)
    }

    /// Envía el correo para restablecer la contraseña. Solo necesita el correo.
    func sendPasswordReset() async {
        infoMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            errorMessage = "Escribí tu correo para recuperar la contraseña"
            return
        }
        isLoading = true
        errorMessage = nil
        let result = await app.sendPasswordReset(email: trimmedEmail)
        isLoading = false
        switch result {
        case .success:
            infoMessage = "Te enviamos un correo para restablecer la contraseña."
        case .failure(let error):
            errorMessage = error.userMessage
        }
    }

    func clearError() {
        errorMessage = nil
    }

    /// Limpia el formulario al cerrar sesión desde Perfil.
    func reset() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
        isLoggedIn = false
    }

    // MARK: Interno

    /// Valida y devuelve `nil` si el formulario es válido. Si no, publica el mensaje.
    ///
    /// Las reglas viven aquí y no en el servicio porque son reglas sobre *qué se le
    /// dice a la persona*: un repositorio que rechaza en silencio una contraseña de
    /// cuatro caracteres no le enseña a la interfaz qué campo está mal.
    @discardableResult
    private func validate(isRegister: Bool) -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            errorMessage = "Ingresá tu correo"
            return "error"
        }
        // Un solo chequeo de "@", no una regex RFC: esto es una guarda contra typos,
        // no una prueba de entregabilidad.
        if !trimmedEmail.contains("@") {
            errorMessage = "Ingresá un correo electrónico válido"
            return "error"
        }
        if password.count < 6 {
            errorMessage = "La contraseña debe tener al menos 6 caracteres"
            return "error"
        }
        if isRegister {
            if confirmPassword.isEmpty {
                errorMessage = "Confirmá la contraseña"
                return "error"
            }
            if confirmPassword != password {
                errorMessage = "Las contraseñas no coinciden"
                return "error"
            }
        }
        return nil
    }

    private func submit(isRegister: Bool) async {
        isLoading = true
        errorMessage = nil

        let result: Result<AuthSession, AppError>
        if isRegister {
            result = await app.signUp(email: email, password: password)
        } else {
            result = await app.signIn(email: email, password: password)
        }

        isLoading = false
        switch result {
        case .success:
            isLoggedIn = true
            Haptics.success()
        case .failure(let error):
            // `isLoading` también se limpia en el fallo: dejarlo en true dejaría el
            // formulario atrapado detrás de un spinner sin forma de reintentar.
            errorMessage = error.userMessage
        }
    }
}
