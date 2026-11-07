//
//  AuthService.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: data/firebase/FirebaseAuthRepository.kt.
//
//  Autenticación con Firebase Auth (correo + contraseña). Firebase guarda la sesión
//  en el Keychain y la restaura al abrir la app; `observeSession` avisa de cada cambio
//  (arranque, inicio de sesión, cierre de sesión).
//
//  Requisito: `GoogleService-Info.plist` (bundle `com.equipo.racion`) dentro de la
//  carpeta `Racion/` y configurado con `FirebaseApp.configure()` en `RacionApp`.
//

import Foundation
import FirebaseAuth
import FirebaseCore

/// Sesión activa (equivalente a `AuthState.Authenticated` de Android).
struct AuthSession: Codable, Hashable {
    let userId: String
    let email: String
}

final class AuthService {

    /// `false` si falta `GoogleService-Info.plist`: en ese caso la app sigue funcionando
    /// en modo invitado (datos solo en el dispositivo) en lugar de cerrarse.
    static var isConfigured: Bool { FirebaseApp.app() != nil }

    // MARK: - Sesión

    /// Llama a `onChange` con la sesión actual y con cada cambio posterior.
    /// Devuelve el handle que hay que pasar a `stopObserving` al cerrar.
    func observeSession(_ onChange: @escaping (AuthSession?) -> Void) -> AuthStateDidChangeListenerHandle? {
        guard Self.isConfigured else {
            onChange(nil)
            return nil
        }
        return Auth.auth().addStateDidChangeListener { _, user in
            let session = user.map { AuthSession(userId: $0.uid, email: $0.email ?? "") }
            // Firebase no garantiza el hilo del callback: se vuelve al hilo principal.
            Task { @MainActor in onChange(session) }
        }
    }

    func stopObserving(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }

    // MARK: - Operaciones

    func signIn(email: String, password: String) async throws -> AuthSession {
        try requireConfigured()
        do {
            let result = try await Auth.auth().signIn(withEmail: normalize(email), password: password)
            return Self.session(from: result.user)
        } catch {
            throw Self.map(error)
        }
    }

    func signUp(email: String, password: String) async throws -> AuthSession {
        try requireConfigured()
        do {
            let result = try await Auth.auth().createUser(withEmail: normalize(email), password: password)
            return Self.session(from: result.user)
        } catch {
            throw Self.map(error)
        }
    }

    /// Envía el correo para restablecer la contraseña.
    func sendPasswordReset(email: String) async throws {
        try requireConfigured()
        do {
            try await Auth.auth().sendPasswordReset(withEmail: normalize(email))
        } catch {
            throw Self.map(error)
        }
    }

    func signOut() throws {
        try requireConfigured()
        do {
            try Auth.auth().signOut()
        } catch {
            throw Self.map(error)
        }
    }

    // MARK: - Interno

    private func requireConfigured() throws {
        guard Self.isConfigured else {
            throw AppError.unknown("Firebase no está configurado: falta GoogleService-Info.plist.")
        }
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func session(from user: User) -> AuthSession {
        AuthSession(userId: user.uid, email: user.email ?? "")
    }

    /// Traduce los errores de Firebase Auth a `AppError` con un mensaje en español.
    static func map(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(error.localizedDescription)
        }
        switch code {
        case .invalidEmail:
            return .unauthorized("El correo no tiene un formato válido.")
        case .wrongPassword, .invalidCredential:
            return .unauthorized("Correo o contraseña incorrectos.")
        case .userNotFound:
            return .unauthorized("No existe una cuenta con ese correo.")
        case .emailAlreadyInUse:
            return .unauthorized("Ya existe una cuenta con ese correo.")
        case .weakPassword:
            return .unauthorized("La contraseña es demasiado débil (mínimo 6 caracteres).")
        case .userDisabled:
            return .unauthorized("Esta cuenta fue deshabilitada.")
        case .networkError:
            return .network
        case .tooManyRequests:
            return .rateLimited
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
