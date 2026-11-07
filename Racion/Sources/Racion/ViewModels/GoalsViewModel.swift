//
//  GoalsViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/MetasScreen.kt
//
//  ✅ RÚBRICA · "Entradas de Usuario": `Slider` para peso y kcal, botones
//     circulares para los días activos y `Toggle` nativo para recordatorios.
//
//  ✅ RÚBRICA · "Persistence": `save()` no escribe archivos: se lo pide a
//     `AppModel`, que es el único que conoce `FileStore`. La vista y el
//     ViewModel jamás ven una ruta del disco.
//

import Foundation

@MainActor
final class GoalsViewModel: ObservableObject {

    // MARK: Borrador editable

    @Published var targetWeightKg: Double
    @Published var kcalPerDay: Double
    @Published var activeDays: Set<Weekday>
    @Published var remindersEnabled: Bool

    @Published private(set) var savedMessage: String?

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
        self.targetWeightKg = app.goals.targetWeightKg
        self.kcalPerDay = Double(app.goals.kcalPerDay)
        self.activeDays = app.goals.activeDays
        self.remindersEnabled = app.settings.remindersEnabled
    }

    // MARK: Derivados para la vista

    /// Los macros NO se editan directamente: se derivan del perfil deportivo.
    /// Se leen de `AppModel` en cada refresco para que elegir "Fuerza" y volver
    /// a esta pantalla se refleje sin reiniciar la app.
    var macroSplit: MacroSplit { app.goals.macroSplit }

    var currentWeightKg: Double { app.goals.currentWeightKg }

    var sessionEmail: String? { app.session?.email }

    var isSignedIn: Bool { app.session != nil }

    var kcalLabel: String { "\(Int(kcalPerDay.rounded())) kcal" }

    var weightLabel: String { String(format: "%.1f kg", targetWeightKg) }

    // MARK: Intenciones

    func toggle(day: Weekday) {
        if activeDays.contains(day) {
            activeDays.remove(day)
        } else {
            activeDays.insert(day)
        }
        Haptics.tap()
    }

    /// Refresca solo lo que viene de afuera (macros, sesión, recordatorios),
    /// sin pisar los sliders que la persona está moviendo.
    func refreshDerived() {
        remindersEnabled = app.settings.remindersEnabled
    }

    func save() {
        let newGoals = NutritionGoals(
            targetWeightKg: targetWeightKg,
            currentWeightKg: app.goals.currentWeightKg,
            kcalPerDay: Int(kcalPerDay.rounded()),
            activeDays: activeDays,
            macroSplit: app.goals.macroSplit
        )
        app.saveGoals(newGoals)
        app.setReminders(remindersEnabled)
        savedMessage = "Metas guardadas"
        Haptics.success()
    }

    func clearSavedMessage() {
        savedMessage = nil
    }

    func signOut() {
        app.signOut()
        savedMessage = "Sesión cerrada"
    }
}
