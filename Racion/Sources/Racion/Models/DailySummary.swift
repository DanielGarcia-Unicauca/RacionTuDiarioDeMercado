//
//  DailySummary.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: domain/model/DailySummary.kt
//
//  ✅ RÚBRICA · "Models": todo lo que la pantalla "Inicio" necesita de un día, ya
//     agregado. El ViewModel la construye una sola vez; la vista no suma nada.
//

import Foundation

struct DailySummary: Hashable {
    /// Texto ya formateado para pantalla, p. ej. "Mié 26 Ago".
    let dateLabel: String
    let consumed: Nutrition
    let goalKcal: Int
    let entries: [DiaryEntry]

    /// Calorías que quedan del día. Puede ser negativo: ocultar el exceso sería mentir,
    /// así que la UI lo muestra en rojo en lugar de recortarlo a cero.
    var remainingKcal: Int { goalKcal - consumed.kcal }

    /// Progreso 0...1 (recortado solo para dibujar la barra).
    var progress: Double {
        guard goalKcal > 0 else { return 0 }
        return min(Double(consumed.kcal) / Double(goalKcal), 1)
    }

    /// Entradas agrupadas por comida, en el orden natural del día.
    var entriesBySlot: [(slot: MealSlot, entries: [DiaryEntry])] {
        MealSlot.allCases.compactMap { slot in
            let filtered = entries.filter { $0.mealSlot == slot }
            return filtered.isEmpty ? nil : (slot, filtered)
        }
    }

    static let empty = DailySummary(
        dateLabel: "",
        consumed: .zero,
        goalKcal: NutritionGoals.default.kcalPerDay,
        entries: []
    )
}
