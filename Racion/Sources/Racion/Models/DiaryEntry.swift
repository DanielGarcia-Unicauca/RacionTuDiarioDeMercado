//
//  DiaryEntry.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: domain/model/DiaryEntry.kt
//
//  ✅ RÚBRICA · "Models": la entrada del diario es la unidad de escritura. Guarda
//     `totalNutrition` ya calculada (denormalizada) para que el resumen del día sea
//     una lectura directa y no una sumatoria de N documentos.
//

import Foundation

/// Un evento alimentario: "comí N porciones de este producto, en esta comida, a esta hora".
struct DiaryEntry: Codable, Hashable, Identifiable {
    /// Id estable generado en el cliente (UUID). Permite reintentar un guardado sin duplicar.
    let id: String
    let product: FoodProduct
    /// Cantidad de porciones consumidas. Siempre >= 1.
    let servings: Int
    let mealSlot: MealSlot
    /// Marca de tiempo en milisegundos desde 1970 (igual que en Android, para no
    /// cambiar el contrato de datos al migrar).
    let loggedAtEpochMillis: Int64
    /// Nutrición ya multiplicada por `servings`, calculada con `nutrition(forUnits:)`.
    let totalNutrition: Nutrition

    init(
        id: String = UUID().uuidString,
        product: FoodProduct,
        servings: Int,
        mealSlot: MealSlot,
        loggedAtEpochMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        totalNutrition: Nutrition? = nil
    ) {
        self.id = id
        self.product = product
        self.servings = servings
        self.mealSlot = mealSlot
        self.loggedAtEpochMillis = loggedAtEpochMillis
        // Si no se pasa el total, se deriva con el método canónico del producto.
        // Así es imposible guardar un total que no corresponda a las porciones.
        self.totalNutrition = totalNutrition ?? product.nutrition(forUnits: servings)
    }

    /// Fecha de consumo como `Date` (para agrupar y ordenar).
    var loggedAt: Date {
        Date(timeIntervalSince1970: Double(loggedAtEpochMillis) / 1000)
    }
}

/// A qué comida del día pertenece una entrada.
///
/// `label` está en español a propósito: se muestra tal cual en la fila del diario
/// ("ALMUERZO · 12:45"). La persistencia usa `rawValue`/`name`, nunca `label`.
enum MealSlot: String, Codable, CaseIterable, Identifiable, Hashable {
    case desayuno
    case almuerzo
    case snack
    case cena

    var id: String { rawValue }

    var label: String {
        switch self {
        case .desayuno: return "Desayuno"
        case .almuerzo: return "Almuerzo"
        case .snack: return "Snack"
        case .cena: return "Cena"
        }
    }

    var emoji: String {
        switch self {
        case .desayuno: return "☕️"
        case .almuerzo: return "🍲"
        case .snack: return "🍎"
        case .cena: return "🌙"
        }
    }
}
