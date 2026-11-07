//
//  WeeklyReport.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: domain/model/WeeklyReport.kt
//
//  ✅ RÚBRICA · "Models": el informe semanal es un modelo agregado. A diferencia del
//     original (que tenía estos números escritos a mano en PreviewData), aquí los
//     calcula `Services/ReportBuilder.swift` a partir de las entradas reales.
//

import Foundation

struct WeeklyReport: Hashable {
    /// Rango ya formateado, p. ej. "24–30 AGO".
    let weekRangeLabel: String
    let averageKcalPerDay: Int
    /// Etiqueta de una letra del día con más calorías, o `nil` si la semana está vacía.
    let bestDayLabel: String?
    /// Días consecutivos con al menos una entrada, contando hacia atrás desde hoy.
    let activeStreakDays: Int
    let macroSplit: MacroSplit
    /// Siempre 7 elementos, uno por día ISO, de lunes a domingo.
    let days: [DayTotal]
    let goalKcal: Int

    static let empty = WeeklyReport(
        weekRangeLabel: "",
        averageKcalPerDay: 0,
        bestDayLabel: nil,
        activeStreakDays: 0,
        macroSplit: MacroSplit(carbsPct: 0, proteinPct: 0, fatPct: 0),
        days: [],
        goalKcal: NutritionGoals.default.kcalPerDay
    )
}

/// Una barra del gráfico semanal.
struct DayTotal: Hashable, Identifiable {
    /// Etiqueta de una letra ("L", "M", ...).
    let label: String
    let kcal: Int
    /// Marca el mejor día para pintarlo con el color primario.
    var isHighlighted: Bool = false
    /// Fecha real del día, usada como identidad estable en el `ForEach`.
    let date: Date

    var id: Date { date }
}
