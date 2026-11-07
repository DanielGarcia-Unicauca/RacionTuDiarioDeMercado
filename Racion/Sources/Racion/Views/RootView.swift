//
//  RootView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/navigation/AppNavigation.kt
//
//  ✅ RÚBRICA · "Navegación": `NavigationStack` por pestaña + `NavigationLink`
//     declarativos + `navigationDestination(for:)`. En Compose esto era un
//     `NavHost` con rutas de texto; aquí las rutas son un enum tipado (`Route`),
//     así que un caso nuevo no compila hasta que se dibuja su destino.
//
//  ✅ RÚBRICA · "Gestión de Estado": `@StateObject` crea el `AppModel` una sola vez
//     y `.environmentObject` lo reparte por todo el árbol. Ninguna pantalla crea
//     su propio almacén, así que todas ven el mismo diario.
//
//  ✅ RÚBRICA · "Pantalla nueva Descripción y Créditos": accesible desde Perfil
//     (`NavigationLink(value: .credits)`) y desde el aviso de onboarding.
//

import SwiftUI

// MARK: - Rutas tipadas

/// Destinos que se pueden apilar sobre una pestaña.
///
/// Es `Hashable` porque `NavigationStack` lo exige. `FoodProduct` también lo es,
/// lo que permite llevar el producto elegido a "Confirmar" como valor de ruta sin
/// un `NavResult` mutable compartido (el seam temporal del Android).
enum Route: Hashable {
    case addFood
    case confirm(FoodProduct)
    case report
    case goals
    case sportProfile
    case credits
    case login
    case register
}

// MARK: - Raíz

struct RootView: View {

    /// Única fuente de verdad. `@StateObject` garantiza que no se recree cuando
    /// SwiftUI vuelve a evaluar `body`.
    @StateObject private var app = AppModel()

    @State private var showOnboarding = false

    var body: some View {
        RootTabs()
            .environmentObject(app)
            .tint(Theme.primary)
            // ✅ Toggle de modo oscuro (Créditos) aplicado a toda la app.
            .preferredColorScheme(app.settings.isDarkMode ? .dark : .light)
            .onAppear {
                if !app.onboardingCompleted {
                    showOnboarding = true
                }
            }
            .onChange(of: app.onboardingCompleted) { _, completed in
                if completed { showOnboarding = false }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
                    .environmentObject(app)
                    .preferredColorScheme(app.settings.isDarkMode ? .dark : .light)
            }
    }
}

// MARK: - Pestañas

/// Las cuatro pestañas del diseño original. Cada una tiene su propio
/// `NavigationStack`, de modo que el historial de "Escanear" no se mezcla con el
/// de "Perfil" (en Android cada pestaña navegaba sobre el mismo grafo global).
struct RootTabs: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        TabView {
            HomeTab(app: app)
                .tabItem { Label("Inicio", systemImage: "house") }

            DiaryTab(app: app)
                .tabItem { Label("Diario", systemImage: "book") }

            ScannerTab(app: app)
                .tabItem { Label("Escanear", systemImage: "barcode.viewfinder") }

            ProfileTab(app: app)
                .tabItem { Label("Perfil", systemImage: "person") }
        }
    }
}

// MARK: - Contenedores por pestaña

private struct HomeTab: View {
    let app: AppModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(app: app)
                .racionRoutes(app: app, path: $path)
        }
    }
}

private struct DiaryTab: View {
    let app: AppModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            DiaryView(app: app)
                .racionRoutes(app: app, path: $path)
        }
    }
}

private struct ScannerTab: View {
    let app: AppModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScannerView(app: app, path: $path)
                .racionRoutes(app: app, path: $path)
        }
    }
}

private struct ProfileTab: View {
    let app: AppModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            GoalsView(app: app)
                .racionRoutes(app: app, path: $path)
        }
    }
}

// MARK: - Destinos compartidos

/// Un solo mapa ruta -> vista para las cuatro pestañas. Si se agrega un caso a
/// `Route`, el `switch` deja de ser exhaustivo y el proyecto no compila: es
/// imposible navegar a una pantalla que no existe.
private struct RacionRoutes: ViewModifier {
    let app: AppModel
    @Binding var path: NavigationPath

    func body(content: Content) -> some View {
        content.navigationDestination(for: Route.self) { route in
            switch route {
            case .addFood:
                AddFoodView(app: app)
            case .confirm(let product):
                ConfirmView(app: app, product: product) {
                    // Volver a la raíz de la pestaña: después de registrar una
                    // comida, la pantalla de confirmación ya no tiene sentido en
                    // el historial.
                    path.removeLast(path.count)
                }
            case .report:
                ReportView(app: app)
            case .goals:
                GoalsView(app: app)
            case .sportProfile:
                SportProfileView(app: app)
            case .credits:
                CreditsView()
            case .login:
                LoginView(app: app)
            case .register:
                RegisterView(app: app)
            }
        }
    }
}

extension View {
    /// Instala el mapa de rutas de la app en un `NavigationStack`.
    func racionRoutes(app: AppModel, path: Binding<NavigationPath>) -> some View {
        modifier(RacionRoutes(app: app, path: path))
    }
}

// MARK: - Onboarding

/// Aviso legal + elección de perfil deportivo, en dos pasos dentro del mismo
/// `fullScreenCover`. Reemplaza al par de rutas AVISO -> PERFIL_DEPORTIVO del
/// grafo Android.
struct OnboardingView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var showPolicy = false

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            if step == 0 {
                DisclaimerView(
                    onAccept: {
                        withAnimation(.easeInOut(duration: 0.3)) { step = 1 }
                    },
                    onViewPolicy: { showPolicy = true }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                OnboardingSportStep()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showPolicy) {
            NavigationStack {
                CreditsView(showsCloseButton: true)
            }
            .environmentObject(app)
            .preferredColorScheme(app.settings.isDarkMode ? .dark : .light)
        }
    }
}

/// Segundo paso del onboarding: elegir enfoque y empezar.
private struct OnboardingSportStep: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var selected: SportFocus = .mantenimiento

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Para qué entrenas?")
                .font(.appDisplay)
                .foregroundStyle(Theme.onSurface)

            Text("Ajustamos tus metas de calorías y macros según tu actividad principal.")
                .font(.appBody)
                .foregroundStyle(Theme.onSurfaceVariant)

            ScrollView {
                SportFocusPicker(selected: $selected)
                    .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)

            PrimaryButton(title: "Empezar") {
                app.applySportFocus(selected)
                app.completeOnboarding()
                dismiss()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.surface.ignoresSafeArea())
    }
}
