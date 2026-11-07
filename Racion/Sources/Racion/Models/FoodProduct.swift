//
//  FoodProduct.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: domain/model/FoodProduct.kt
//
//  ✅ RÚBRICA · "Models": el producto no sabe si vino de Open Food Facts, de un
//     código de barras o del catálogo local. El DTO de red se mapea a este tipo en
//     Services/OpenFoodFactsService.swift, y ninguna pantalla conoce el JSON.
//

import Foundation

/// Un alimento tal como lo entiende la app.
///
/// La nutrición se guarda SIEMPRE por 100 g (`nutritionPer100g`). Esa es la única
/// normalización que sobrevive a productos cuya porción es "1 unidad", "1 rebanada",
/// "250 ml" o simplemente no está declarada.
struct FoodProduct: Codable, Hashable, Identifiable {
    /// EAN-13 / UPC-A. Identidad estable del producto envasado.
    let barcode: String
    let name: String
    var brand: String? = nil
    /// Tamaño legible tal como viene impreso: "500 g", "1 L".
    var quantityLabel: String? = nil
    /// Gramos de una "unidad"/porción cuando el fabricante lo declara.
    var servingGrams: Double? = nil
    let nutritionPer100g: Nutrition
    var imageURL: String? = nil
    /// "a"..."e" en minúsculas, o `nil` si el producto no tiene Nutri-Score.
    var nutriscoreGrade: String? = nil
    /// Open Food Facts devuelve las categorías como un string separado por comas;
    /// aquí ya llegan separadas.
    var categories: [String] = []
    var ingredientsText: String? = nil
    /// Sustituto visual de la foto del producto dentro de una fila del diario.
    var emoji: String = "🍽"

    /// `Identifiable` para poder usar `ForEach(products)` sin escribir `id:`.
    /// La identidad es el código de barras: es estable entre lanzamientos.
    var id: String { barcode }

    /// Gramos asumidos para una "unidad" cuando el fabricante no declara porción.
    ///
    /// 100 g es la única elección honesta porque es la base sobre la que ya está
    /// guardada `nutritionPer100g`.
    static let defaultServingGrams: Double = 100

    /// Nutrición para `grams` gramos de este producto. Nunca falla.
    func nutrition(forGrams grams: Double) -> Nutrition {
        nutritionPer100g.scaled(grams / 100)
    }

    /// Nutrición para `units` porciones, redondeando UNA sola vez.
    ///
    /// ⚠️ Es el único método correcto para una entrada de varias unidades.
    /// Si se redondea la porción a gramos enteros y después se multiplica por las
    /// unidades, se redondea dos veces y la pantalla muestra un número distinto al
    /// que se guarda (en Android pasaba: 530 kcal mostradas vs. 529 guardadas).
    /// Tanto la vista "Confirmar" como el guardado llaman aquí.
    func nutrition(forUnits units: Int) -> Nutrition {
        nutrition(forGrams: (servingGrams ?? Self.defaultServingGrams) * Double(units))
    }

    /// Etiqueta de origen: marca si existe; si no, categorías; si no, un texto honesto.
    var originLabel: String {
        if let brand, !brand.trimmingCharacters(in: .whitespaces).isEmpty {
            return brand
        }
        if !categories.isEmpty {
            return categories.joined(separator: " · ")
        }
        return "Sin origen declarado"
    }
}
