//
//  SeedData.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/preview/PreviewData.kt
//
//  En Android, `PreviewData` alimentaba las pantallas porque la capa de datos eran
//  TODOs. Aquí su función es distinta y más honesta: **sembrar el almacenamiento
//  local** la primera vez que se abre la app, para que la demo tenga contenido real
//  y persistente (se puede borrar, editar y sobrevive a reiniciar la app).
//
//  Los productos son los mismos platos del proyecto original: arepa de choclo,
//  empanada, bandeja paisa, patacón, avena Alpina, sancocho y jugo de mango biche.
//

import Foundation

enum SeedData {

    // MARK: - Productos

    static let arepaChoclo = FoodProduct(
        barcode: "LOCAL-AREPACHOCLO",
        name: "Arepa de choclo",
        brand: "Típico · Región andina",
        quantityLabel: "1 unidad (90 g)",
        servingGrams: 90,
        nutritionPer100g: Nutrition(kcal: 233, carbsG: 33, proteinG: 10, fatG: 12),
        categories: ["Almuerzo", "Bebidas"],
        emoji: "🌽"
    )

    static let empanada = FoodProduct(
        barcode: "LOCAL-EMPANADACARNE",
        name: "Empanada de carne",
        brand: "Típico · Tolima",
        quantityLabel: "1 unidad (120 g)",
        servingGrams: 120,
        nutritionPer100g: Nutrition(kcal: 192, carbsG: 22, proteinG: 9, fatG: 9),
        categories: ["Frituras"],
        emoji: "🥟"
    )

    static let bandejaPaisa = FoodProduct(
        barcode: "LOCAL-BANDEJAPAISA",
        name: "Bandeja paisa",
        brand: "Típico · Antioquia",
        quantityLabel: "1 porción (450 g)",
        servingGrams: 450,
        nutritionPer100g: Nutrition(kcal: 191, carbsG: 16, proteinG: 12, fatG: 12),
        categories: ["Almuerzo"],
        emoji: "🍛"
    )

    static let patacon = FoodProduct(
        barcode: "LOCAL-PATACONHOGAO",
        name: "Patacón con hogao",
        brand: "Típico · Pacífico",
        quantityLabel: "1 porción (220 g)",
        servingGrams: 220,
        nutritionPer100g: Nutrition(kcal: 141, carbsG: 21, proteinG: 3, fatG: 5),
        categories: ["Frituras"],
        emoji: "🍠"
    )

    static let avena = FoodProduct(
        barcode: "7801234567890",
        name: "Avena Alpina 200 ml",
        brand: "Alpina",
        quantityLabel: "200 ml",
        servingGrams: 200,
        nutritionPer100g: Nutrition(kcal: 70, carbsG: 10, proteinG: 2.5, fatG: 1.8, sugarsG: 8, fiberG: 0.8, sodiumG: 0.06),
        nutriscoreGrade: "c",
        categories: ["Bebidas", "Lácteos"],
        emoji: "🍞"
    )

    static let sancocho = FoodProduct(
        barcode: "LOCAL-SANCOCHOGALLINA",
        name: "Sancocho de gallina",
        brand: "Típico · Región andina",
        quantityLabel: "1 plato (400 g)",
        servingGrams: 400,
        nutritionPer100g: Nutrition(kcal: 120, carbsG: 12, proteinG: 12, fatG: 3),
        categories: ["Sopas"],
        emoji: "🍲"
    )

    static let jugoMango = FoodProduct(
        barcode: "LOCAL-JUGOMANGOBICHE",
        name: "Jugo de mango biche",
        brand: "Típico · Región andina",
        quantityLabel: "1 vaso (330 ml)",
        servingGrams: 330,
        nutritionPer100g: Nutrition(kcal: 39, carbsG: 9, proteinG: 0.4, fatG: 0.1, sugarsG: 8.5),
        categories: ["Bebidas"],
        emoji: "🥭"
    )

    /// El producto que abre la pantalla "Confirmar" desde el escáner simulado.
    /// Es el único con lista de ingredientes y Nutri-Score, para ejercitar todos
    /// los campos del diseño.
    static let featuredProduct = FoodProduct(
        barcode: "LOCAL-AREPAQUESO",
        name: "Arepa de choclo con queso",
        brand: "Típico · Región andina",
        quantityLabel: "1 unidad (90 g)",
        servingGrams: 90,
        nutritionPer100g: Nutrition(kcal: 294, carbsG: 31, proteinG: 10, fatG: 12),
        nutriscoreGrade: "d",
        categories: ["Almuerzo", "Bebidas"],
        ingredientsText: "Masa de maíz tierno asada, rellena con queso campesino.",
        emoji: "🌽"
    )

    /// Catálogo local completo (búsqueda sin conexión).
    static let products: [FoodProduct] = [
        featuredProduct, arepaChoclo, empanada, bandejaPaisa,
        patacon, avena, sancocho, jugoMango
    ]

    // MARK: - Diario de ejemplo

    /// Genera las entradas iniciales.
    ///
    /// Hoy quedan las tres comidas del diseño original (arepa 7:20, sancocho 12:45,
    /// jugo 15:10) y los seis días previos se rellenan para que el Informe semanal
    /// tenga datos que graficar de verdad.
    static func demoEntries(reference: Date = Date()) -> [DiaryEntry] {
        let calendar = ReportBuilder.isoCalendar
        let today = calendar.startOfDay(for: reference)

        func stamp(daysAgo: Int, hour: Int, minute: Int) -> Int64 {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
            return Int64(date.timeIntervalSince1970 * 1000)
        }

        var entries: [DiaryEntry] = []

        // Hoy
        entries.append(DiaryEntry(product: arepaChoclo, servings: 1, mealSlot: .desayuno, loggedAtEpochMillis: stamp(daysAgo: 0, hour: 7, minute: 20)))
        entries.append(DiaryEntry(product: sancocho, servings: 1, mealSlot: .almuerzo, loggedAtEpochMillis: stamp(daysAgo: 0, hour: 12, minute: 45)))
        entries.append(DiaryEntry(product: jugoMango, servings: 1, mealSlot: .snack, loggedAtEpochMillis: stamp(daysAgo: 0, hour: 15, minute: 10)))

        // Historial de la semana (para el informe)
        entries.append(DiaryEntry(product: avena, servings: 1, mealSlot: .desayuno, loggedAtEpochMillis: stamp(daysAgo: 1, hour: 7, minute: 5)))
        entries.append(DiaryEntry(product: bandejaPaisa, servings: 1, mealSlot: .almuerzo, loggedAtEpochMillis: stamp(daysAgo: 1, hour: 13, minute: 0)))
        entries.append(DiaryEntry(product: sancocho, servings: 1, mealSlot: .almuerzo, loggedAtEpochMillis: stamp(daysAgo: 2, hour: 12, minute: 30)))
        entries.append(DiaryEntry(product: jugoMango, servings: 1, mealSlot: .snack, loggedAtEpochMillis: stamp(daysAgo: 2, hour: 16, minute: 0)))
        entries.append(DiaryEntry(product: arepaChoclo, servings: 1, mealSlot: .desayuno, loggedAtEpochMillis: stamp(daysAgo: 3, hour: 7, minute: 40)))
        entries.append(DiaryEntry(product: empanada, servings: 2, mealSlot: .snack, loggedAtEpochMillis: stamp(daysAgo: 3, hour: 17, minute: 15)))
        entries.append(DiaryEntry(product: patacon, servings: 1, mealSlot: .almuerzo, loggedAtEpochMillis: stamp(daysAgo: 4, hour: 12, minute: 50)))
        entries.append(DiaryEntry(product: bandejaPaisa, servings: 1, mealSlot: .almuerzo, loggedAtEpochMillis: stamp(daysAgo: 5, hour: 13, minute: 10)))
        entries.append(DiaryEntry(product: jugoMango, servings: 1, mealSlot: .snack, loggedAtEpochMillis: stamp(daysAgo: 5, hour: 16, minute: 20)))
        entries.append(DiaryEntry(product: arepaChoclo, servings: 2, mealSlot: .desayuno, loggedAtEpochMillis: stamp(daysAgo: 6, hour: 8, minute: 0)))

        return entries.sorted { $0.loggedAtEpochMillis < $1.loggedAtEpochMillis }
    }
}
