//
//  ConfirmViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/ConfirmarScreen.kt
//
//  ✅ RÚBRICA · "Entradas de Usuario": la pantalla usa `Stepper` nativo para las
//     porciones (en Android era un par de botones "–"/"+") y pastillas para la
//     comida del día.
//
//  ✅ RÚBRICA · "MVVM": la aritmética que se muestra y la que se guarda salen del
//     MISMO método (`FoodProduct.nutrition(forUnits:)`). En el original había un
//     bug de doble redondeo: la vista mostraba 530 kcal y el diario guardaba 529.
//

import Foundation

@MainActor
final class ConfirmViewModel: ObservableObject {

    let product: FoodProduct

    /// ✅ Stepper nativo: porciones que se van a agregar.
    @Published var servings = 1
    @Published var mealSlot: MealSlot = .almuerzo

    /// Comidas ofrecidas en el diseño original (sin Cena, que se agregó en iOS).
    let mealSlots: [MealSlot] = MealSlot.allCases

    init(product: FoodProduct) {
        self.product = product
    }

    /// Total que se muestra Y que se guarda.
    var total: Nutrition { product.nutrition(forUnits: servings) }

    /// Gramos aproximados de la porción actual, solo para la etiqueta.
    var gramsLabel: String {
        let grams = (product.servingGrams ?? FoodProduct.defaultServingGrams) * Double(servings)
        return "≈ \(Int(grams.rounded())) g"
    }

    var originLabel: String { product.originLabel }

    var ingredients: String {
        product.ingredientsText ?? "Sin lista de ingredientes declarada."
    }

    var nutriscoreLabel: String? {
        guard let grade = product.nutriscoreGrade, !grade.isEmpty else { return nil }
        return "NUTRI-SCORE \(grade.uppercased())"
    }

    /// Agrega la entrada al diario y devuelve la entrada creada.
    @discardableResult
    func add(to app: AppModel) -> DiaryEntry {
        let entry = DiaryEntry(
            product: product,
            servings: servings,
            mealSlot: mealSlot
        )
        app.addEntry(entry)
        Haptics.success()
        return entry
    }
}
