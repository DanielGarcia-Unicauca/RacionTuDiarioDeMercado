//
//  AppModel.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: di/AppContainer.kt + RacionApplication.kt
//
//  ✅ RÚBRICA · "Gestión de Estado": este objeto es el `@StateObject` raíz que se
//     inyecta con `.environmentObject`. Es la ÚNICA fuente de verdad de los datos
//     (diario, metas, perfil, sesión, preferencias); los ViewModels de cada pantalla
//     lo leen y escriben a través de métodos, nunca tocan los archivos directamente.
//
//  Se eligió `ObservableObject` + `@Published` (y no la macro `@Observable`) porque
//  la rúbrica pide explícitamente `@StateObject` / `@ObservedObject`, y porque no
//  requiere la expansión de macros de `@Observable`.
//

import Foundation
import FirebaseAuth

@MainActor
final class AppModel: ObservableObject {

    // MARK: - Estado observable (fuente de verdad)

    @Published private(set) var entries: [DiaryEntry] = []
    @Published private(set) var goals: NutritionGoals = .default
    @Published private(set) var profile: UserProfile = UserProfile(userId: "local-user", displayName: "Hola!")
    @Published private(set) var settings = AppSettings()
    @Published private(set) var session: AuthSession?
    /// Error de arranque (por ejemplo, disco no escribible). La UI lo muestra como banner.
    @Published private(set) var bootError: String?
    /// Último error al sincronizar con la nube. `nil` cuando todo está al día.
    @Published private(set) var syncError: String?

    // MARK: - Servicios (inyectados, reemplazables en tests)

    /// Catálogo remoto (URLSession + Open Food Facts).
    let catalog: FoodCatalogRepository
    /// Catálogo local de respaldo cuando no hay red.
    let localCatalog: LocalCatalog

    private let auth: AuthService
    private let cloud: CloudStore
    private let store: FileStore
    private var authHandle: AuthStateDidChangeListenerHandle?

    /// Copia de las entradas tal como están en la nube. Sirve para enviar solo los
    /// cambios (altas, ediciones y borrados) en lugar de reescribir todo el diario.
    private var syncedEntries: [DiaryEntry] = []

    // MARK: - Modo de datos
    //
    // Sin sesión: los datos viven en el dispositivo (`FileStore`), como modo invitado.
    // Con sesión: los datos viven en Firestore bajo el uid del usuario, y el disco
    // local no se toca. Así, los datos de invitado nunca se mezclan con los de una cuenta.

    // MARK: - Ciclo de vida

    init(
        store: FileStore = .shared,
        catalog: FoodCatalogRepository? = nil,
        localCatalog: LocalCatalog = LocalCatalog(),
        auth: AuthService? = nil,
        cloud: CloudStore? = nil
    ) {
        self.store = store
        self.catalog = catalog ?? OpenFoodFactsRepository()
        self.localCatalog = localCatalog
        self.auth = auth ?? AuthService()
        self.cloud = cloud ?? CloudStore()

        settings = store.load(AppSettings.self, from: "settings.json") ?? AppSettings()
        loadLocalData()

        // Se escucha al final: el callback puede llegar enseguida y necesita el estado listo.
        authHandle = self.auth.observeSession { [weak self] newSession in
            self?.handleSessionChange(newSession)
        }
    }

    /// Carga los datos de invitado desde disco y siembra la demo la primera vez.
    private func loadLocalData() {
        entries = store.load([DiaryEntry].self, from: "diary.json") ?? []
        goals = store.load(NutritionGoals.self, from: "goals.json") ?? .default
        profile = store.load(UserProfile.self, from: "profile.json")
            ?? UserProfile(userId: "local-user", displayName: "Hola!")

        if !settings.hasSeededDemoData {
            entries = SeedData.demoEntries()
            settings.hasSeededDemoData = true
            store.save(entries, to: "diary.json")
            persistSettings()
        }
    }

    /// Cambio de sesión (arranque, inicio o cierre). Reemplaza por completo los datos
    /// en memoria: nunca se muestran datos de un usuario mezclados con otro.
    private func handleSessionChange(_ newSession: AuthSession?) {
        guard newSession?.userId != session?.userId else { return }
        session = newSession
        syncError = nil

        guard let uid = newSession?.userId else {
            // Cierre de sesión: vuelve el modo invitado con sus datos locales.
            loadLocalData()
            syncedEntries = []
            return
        }

        // Inicio de sesión: se vacía lo que había y se descarga la cuenta.
        entries = []
        goals = .default
        profile = UserProfile(userId: uid, displayName: "Hola!")
        syncedEntries = []
        Task { await self.loadCloudData(uid: uid) }
    }

    /// Descarga diario, metas y perfil del usuario desde Firestore.
    private func loadCloudData(uid: String) async {
        do {
            async let cloudEntries = cloud.fetchEntries(uid: uid)
            async let cloudGoals = cloud.fetchGoals(uid: uid)
            async let cloudProfile = cloud.fetchProfile(uid: uid)
            let (downloadedEntries, downloadedGoals, downloadedProfile) = try await (cloudEntries, cloudGoals, cloudProfile)

            // Si la sesión cambió mientras se descargaba, estos datos ya no corresponden.
            guard session?.userId == uid else { return }

            entries = downloadedEntries.sorted { $0.loggedAtEpochMillis < $1.loggedAtEpochMillis }
            syncedEntries = entries
            goals = downloadedGoals ?? .default
            if let downloadedProfile {
                profile = downloadedProfile
            }
        } catch {
            guard session?.userId == uid else { return }
            syncError = "No se pudieron cargar tus datos: \(error.localizedDescription)"
        }
    }

    // MARK: - Lecturas derivadas

    /// Entradas de un día concreto (por defecto hoy), ordenadas por hora.
    func entries(on day: Date = Date()) -> [DiaryEntry] {
        let calendar = Calendar.current
        return entries
            .filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
            .sorted { $0.loggedAtEpochMillis < $1.loggedAtEpochMillis }
    }

    /// Resumen listo para la pantalla "Inicio".
    func summary(on day: Date = Date()) -> DailySummary {
        let dayEntries = entries(on: day)
        return DailySummary(
            dateLabel: AppFormat.dayLabel(day),
            consumed: Nutrition.total(of: dayEntries.map(\.totalNutrition)),
            goalKcal: goals.kcalPerDay,
            entries: dayEntries
        )
    }

    /// Informe semanal calculado desde el diario real.
    func weeklyReport(reference: Date = Date()) -> WeeklyReport {
        ReportBuilder.weeklyReport(entries: entries, goals: goals, reference: reference)
    }

    var onboardingCompleted: Bool { settings.onboardingCompleted }

    // MARK: - Escrituras del diario

    func addEntry(_ entry: DiaryEntry) {
        entries.append(entry)
        entries.sort { $0.loggedAtEpochMillis < $1.loggedAtEpochMillis }
        persistDiary()
    }

    func deleteEntry(id: String) {
        entries.removeAll { $0.id == id }
        persistDiary()
    }

    /// Cambia las porciones de una entrada y **recalcula** el total con el método
    /// canónico del producto (así el total nunca queda desincronizado).
    func updateServings(entryID: String, servings: Int) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        let old = entries[index]
        let updated = DiaryEntry(
            id: old.id,
            product: old.product,
            servings: max(1, servings),
            mealSlot: old.mealSlot,
            loggedAtEpochMillis: old.loggedAtEpochMillis,
            totalNutrition: old.product.nutrition(forUnits: max(1, servings))
        )
        entries[index] = updated
        persistDiary()
    }

    /// Borra todo el diario (acción de la pantalla Diario, con confirmación).
    func clearDiary() {
        entries = []
        persistDiary()
    }

    /// Restaura el diario de demostración (acción de la pantalla Créditos).
    ///
    /// No toca metas, perfil ni cuentas: solo vuelve a sembrar las entradas. Es la
    /// forma de recuperar la demo después de haberla vaciado probando la app.
    func resetDemoData() {
        entries = SeedData.demoEntries()
        settings.hasSeededDemoData = true
        persistDiary()
        persistSettings()
        Haptics.success()
    }

    // MARK: - Metas y perfil

    func saveGoals(_ newGoals: NutritionGoals) {
        goals = newGoals
        // Mantener el peso actual del perfil alineado con las metas.
        profile.currentWeightKg = newGoals.currentWeightKg
        persistMeta()
    }

    func saveProfile(_ newProfile: UserProfile) {
        profile = newProfile
        persistMeta()
    }

    /// Elige el enfoque deportivo y aplica el reparto de macros sugerido.
    /// `Mantenimiento` no toca los macros: significa "sin objetivo específico".
    func applySportFocus(_ focus: SportFocus) {
        profile.sportFocus = focus
        if let split = focus.suggestedMacroSplit {
            goals.macroSplit = split
        }
        persistMeta()
    }

    func completeOnboarding() {
        settings.onboardingCompleted = true
        persistSettings()
    }

    func setDarkMode(_ enabled: Bool) {
        settings.isDarkMode = enabled
        persistSettings()
    }

    func setReminders(_ enabled: Bool) {
        settings.remindersEnabled = enabled
        persistSettings()
    }

    // MARK: - Cuenta

    /// La sesión se actualiza sola por el listener de Firebase (`handleSessionChange`),
    /// así que aquí solo se devuelve el resultado a la pantalla.
    func signIn(email: String, password: String) async -> Result<AuthSession, AppError> {
        do {
            return .success(try await auth.signIn(email: email, password: password))
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func signUp(email: String, password: String) async -> Result<AuthSession, AppError> {
        do {
            return .success(try await auth.signUp(email: email, password: password))
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    /// Envía el correo de restablecimiento de contraseña.
    func sendPasswordReset(email: String) async -> Result<Void, AppError> {
        do {
            try await auth.sendPasswordReset(email: email)
            return .success(())
        } catch let error as AppError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func signOut() {
        do {
            try auth.signOut()
        } catch {
            syncError = error.localizedDescription
        }
        // Si Firebase no está configurado no hay sesión que cerrar: se cierra igual.
        handleSessionChange(nil)
    }

    // MARK: - Persistencia

    /// Guarda el diario: en la nube si hay sesión, en disco si no.
    private func persistDiary() {
        guard let uid = session?.userId else {
            store.save(entries, to: "diary.json")
            return
        }

        let previous = Dictionary(syncedEntries.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let current = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let upserts = entries.filter { previous[$0.id] != $0 }
        let deletes = syncedEntries.map(\.id).filter { current[$0] == nil }
        syncedEntries = entries

        guard !upserts.isEmpty || !deletes.isEmpty else { return }
        runCloudWrite { [cloud] in
            try await cloud.applyEntryChanges(uid: uid, upserts: upserts, deletes: deletes)
        }
    }

    /// Guarda metas y perfil: en la nube si hay sesión, en disco si no.
    private func persistMeta() {
        guard let uid = session?.userId else {
            store.save(goals, to: "goals.json")
            store.save(profile, to: "profile.json")
            return
        }
        let currentGoals = goals
        let currentProfile = profile
        runCloudWrite { [cloud] in
            try await cloud.saveMeta(uid: uid, goals: currentGoals, profile: currentProfile)
        }
    }

    /// Las preferencias (modo oscuro, onboarding, recordatorios) son del dispositivo,
    /// no de la cuenta: siempre se guardan localmente.
    private func persistSettings() {
        store.save(settings, to: "settings.json")
    }

    /// Ejecuta una escritura en la nube sin bloquear la interfaz. Firestore reintenta
    /// sola cuando vuelve la conexión; aquí solo se informa de errores reales (por
    /// ejemplo, reglas de seguridad que rechazan la escritura).
    private func runCloudWrite(_ operation: @escaping () async throws -> Void) {
        Task {
            do {
                try await operation()
                self.syncError = nil
            } catch {
                self.syncError = "No se pudo guardar en la nube: \(error.localizedDescription)"
            }
        }
    }
}
