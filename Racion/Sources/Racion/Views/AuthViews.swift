//
//  AuthViews.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/auth/LoginScreen.kt + RegisterScreen.kt
//
//  ✅ RÚBRICA · "Persistence" + "MVVM": el formulario es delgado; la validación y
//     la llamada a `AuthService` (Firebase Auth) viven en `LoginViewModel`.
//  ✅ RÚBRICA · "Entradas de Usuario": `TextField` y `SecureField` nativos.
//
//  Las cuentas se gestionan con Firebase Auth (correo y contraseña).
//

import SwiftUI

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm: LoginViewModel

    init(app: AppModel) {
        _vm = StateObject(wrappedValue: LoginViewModel(app: app))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Iniciar sesión")
                    .font(.appDisplay)
                    .foregroundStyle(Theme.onSurface)
                Text("Ingresá a tu cuenta para ver tu diario")
                    .font(.appBodyMedium)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 4)

                SectionLabel("CORREO ELECTRÓNICO")
                    .padding(.top, 28)

                TextField("vos@ejemplo.com", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .racionField()
                    .padding(.top, 8)
                    .disabled(vm.isLoading)

                SectionLabel("CONTRASEÑA")
                    .padding(.top, 16)

                SecureField("Mínimo 6 caracteres", text: $vm.password)
                    .textContentType(.password)
                    .racionField()
                    .padding(.top, 8)
                    .disabled(vm.isLoading)

                if let error = vm.errorMessage {
                    ErrorBanner(message: error) {
                        vm.clearError()
                    }
                    .padding(.top, 14)
                }

                if let info = vm.infoMessage {
                    Text(info)
                        .font(.appBodyMedium)
                        .foregroundStyle(Theme.primary)
                        .padding(.top, 14)
                }

                PrimaryButton(
                    title: "Iniciar sesión",
                    isLoading: vm.isLoading,
                    isEnabled: !vm.isLoading
                ) {
                    Task { await vm.signIn() }
                }
                .padding(.top, 26)

                Button {
                    Task { await vm.sendPasswordReset() }
                } label: {
                    Text("¿Olvidaste tu contraseña?")
                        .font(.appBodyMedium)
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)

                NavigationLink(value: Route.register) {
                    Text("¿No tenés cuenta? Crear cuenta")
                        .font(.appTitleMedium)
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 18)
                }
                .buttonStyle(.plain)

                Text("Tu diario se guarda en la nube y se sincroniza con tu cuenta. Sin conexión, los cambios se guardan en el dispositivo y se envían al volver a conectarte.")
                    .font(.appBodySmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 26)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Cuenta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        // La autenticación es un flujo modal fuera de las pestañas.
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: vm.isLoggedIn) { _, loggedIn in
            if loggedIn { dismiss() }
        }
        // Al volver del registro la sesión ya existe en `AppModel`: el login se
        // cierra solo para no dejar dos formularios apilados.
        .onAppear {
            if app.session != nil { dismiss() }
        }
        .task(id: vm.errorMessage) {
            guard let message = vm.errorMessage else { return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if vm.errorMessage == message {
                withAnimation { vm.clearError() }
            }
        }
    }
}

// MARK: - Registro

struct RegisterView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm: LoginViewModel

    init(app: AppModel) {
        _vm = StateObject(wrappedValue: LoginViewModel(app: app))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Crear cuenta")
                    .font(.appDisplay)
                    .foregroundStyle(Theme.onSurface)
                Text("Necesitás una cuenta para guardar tu diario")
                    .font(.appBodyMedium)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 4)

                SectionLabel("CORREO ELECTRÓNICO")
                    .padding(.top, 26)

                TextField("vos@ejemplo.com", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .racionField()
                    .padding(.top, 8)
                    .disabled(vm.isLoading)

                SectionLabel("CONTRASEÑA")
                    .padding(.top, 16)

                SecureField("Mínimo 6 caracteres", text: $vm.password)
                    .textContentType(.newPassword)
                    .racionField()
                    .padding(.top, 8)
                    .disabled(vm.isLoading)

                SectionLabel("CONFIRMÁ LA CONTRASEÑA")
                    .padding(.top, 16)

                SecureField("Repetí la contraseña", text: $vm.confirmPassword)
                    .textContentType(.newPassword)
                    .racionField()
                    .padding(.top, 8)
                    .disabled(vm.isLoading)

                if let error = vm.errorMessage {
                    ErrorBanner(message: error) {
                        vm.clearError()
                    }
                    .padding(.top, 14)
                }

                PrimaryButton(
                    title: "Crear cuenta",
                    isLoading: vm.isLoading,
                    isEnabled: !vm.isLoading
                ) {
                    Task { await vm.signUp() }
                }
                .padding(.top, 24)

                Button {
                    dismiss()
                } label: {
                    Text("Ya tengo una cuenta — Iniciar sesión")
                        .font(.appTitleMedium)
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 18)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Crear cuenta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: vm.isLoggedIn) { _, loggedIn in
            if loggedIn { dismiss() }
        }
        .task(id: vm.errorMessage) {
            guard let message = vm.errorMessage else { return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if vm.errorMessage == message {
                withAnimation { vm.clearError() }
            }
        }
    }
}
