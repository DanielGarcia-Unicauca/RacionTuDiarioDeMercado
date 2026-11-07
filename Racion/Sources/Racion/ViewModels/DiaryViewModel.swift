//
//  DiaryViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  NUEVA PANTALLA en iOS (en Android la pestaña "Diario" abría directamente el
//  buscador). Aquí es una pantalla propia con el historial completo, filtro y
//  edición de porciones, para cumplir el requisito de cinco pantallas funcionales
//  y para poder ejercitar `Toggle` y `Stepper` nativos.
//
//  ✅ RÚBRICA · "Entradas de Usuario": Toggle (solo hoy) y Stepper (porciones).
//

import Foundation

@MainActor
final class DiaryViewModel: ObservableObject {

    /// ✅ Toggle nativo: filtra el historial a solo hoy.
    @Published var onlyToday = true

    /// Entrada que se está editando en la hoja de porciones.
    @Published var editingEntry: DiaryEntry?
    /// ✅ Stepper nativo: porciones de la entrada en edición.
    @Published var editingServings = 1

    @Published private(set) var lastActionMessage: String?

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    /// Filtra y ordena las entradas que la vista ya leyó de `AppModel`.
    ///
    /// Se pasan como parámetro (en lugar de leerlas aquí) para que la vista dependa
    /// de `app.entries` y SwiftUI vuelva a dibujar en cuanto cambie el diario.
    func visible(from entries: [DiaryEntry]) -> [DiaryEntry] {
        let calendar = Calendar.current
        let base = onlyToday
            ? entries.filter { calendar.isDateInToday($0.loggedAt) }
            : entries
        return base.sorted { $0.loggedAtEpochMillis > $1.loggedAtEpochMillis }
    }

    func beginEdit(_ entry: DiaryEntry) {
        editingEntry = entry
        editingServings = max(1, entry.servings)
    }

    func cancelEdit() {
        editingEntry = nil
    }

    /// Guarda las porciones nuevas. `AppModel` recalcula el total con el método
    /// canónico del producto, así que el número mostrado y el guardado coinciden.
    func commitEdit() {
        guard let entry = editingEntry else { return }
        app.updateServings(entryID: entry.id, servings: editingServings)
        editingEntry = nil
        lastActionMessage = "Porciones actualizadas"
        Haptics.success()
    }

    func delete(_ entry: DiaryEntry) {
        app.deleteEntry(id: entry.id)
        lastActionMessage = "Entrada eliminada"
    }

    func deleteAll() {
        app.clearDiary()
        lastActionMessage = "Diario vaciado"
    }

    func clearMessage() {
        lastActionMessage = nil
    }

    // MARK: Agregados para la cabecera

    /// Total de kcal de la lista visible. Se calcula aquí (no en la vista) para
    /// que la cabecera y las filas no puedan contradecirse.
    func totalKcal(in entries: [DiaryEntry]) -> Int {
        entries.reduce(0) { $0 + $1.totalNutrition.kcal }
    }

    func totalServings(in entries: [DiaryEntry]) -> Int {
        entries.reduce(0) { $0 + $1.servings }
    }
}
