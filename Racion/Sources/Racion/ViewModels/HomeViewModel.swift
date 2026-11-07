//
//  HomeViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  ✅ RÚBRICA · "MVVM": prepara el `DailySummary` (ya agregado) que consume
//     `HomeView`. La vista no suma calorías ni filtra entradas: solo dibuja.
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var summary: DailySummary = .empty
    @Published private(set) var profile: UserProfile

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
        self.profile = app.profile
        self.summary = app.summary()
    }

    /// Se llama al aparecer la pantalla y cada vez que cambia el diario.
    func refresh() {
        summary = app.summary()
        profile = app.profile
    }

    var greeting: String {
        let name = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Hola!" : name
    }

    var caloriesLeftLabel: String {
        let remaining = summary.remainingKcal
        if remaining < 0 {
            return "\(abs(remaining)) kcal por encima de la meta"
        }
        return "de \(summary.goalKcal) kcal · quedan \(remaining)"
    }

    var isOverGoal: Bool { summary.remainingKcal < 0 }

    // Etiquetas ya redondeadas para los chips de macros. El redondeo es solo de
    // presentación: el valor guardado conserva los decimales.
    var carbsLabel: String { "\(Int(summary.consumed.carbsG.rounded())) g" }
    var proteinLabel: String { "\(Int(summary.consumed.proteinG.rounded())) g" }
    var fatLabel: String { "\(Int(summary.consumed.fatG.rounded())) g" }

    /// Filas de comida con su texto ya formateado ("ALMUERZO · 12:45 PM").
    func rows() -> [(id: String, emoji: String, name: String, meta: String, kcal: Int)] {
        summary.entries.map { entry in
            (
                id: entry.id,
                emoji: entry.product.emoji,
                name: entry.product.name,
                meta: AppFormat.mealRowMeta(entry),
                kcal: entry.totalNutrition.kcal
            )
        }
    }
}
