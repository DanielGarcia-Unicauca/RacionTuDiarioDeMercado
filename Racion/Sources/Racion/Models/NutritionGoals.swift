//
//  NutritionGoals.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: domain/model/NutritionGoals.kt
//
//  ✅ RÚBRICA · "Models": los límites de los controles (slider, stepper) viven aquí,
//     no en la pantalla. Así la UI no puede ofrecer un peso que el dominio considere
//     inválido.
//

import Foundation

/// Objetivos del usuario, editables desde la pantalla "Metas".
struct NutritionGoals: Codable, Hashable {
    var targetWeightKg: Double = 63
    var currentWeightKg: Double = 68
    var kcalPerDay: Int = 1900
    /// Días ISO en los que la persona entrena.
    var activeDays: Set<Weekday> = Set(Weekday.allCases)
    var macroSplit: MacroSplit = MacroSplit(carbsPct: 45, proteinPct: 25, fatPct: 30)

    /// Rango válido del slider de peso (kg).
    static let weightRange: ClosedRange<Double> = 55...80
    /// Rango válido del stepper/slider de energía (kcal).
    static let kcalRange: ClosedRange<Int> = 1400...2600
    /// Valores por defecto la primera vez que se abre la app.
    static let `default` = NutritionGoals()
}

/// Días de la semana con su etiqueta de una letra en español.
///
/// En Kotlin este enum "ensombrecía" a `java.time.DayOfWeek` a propósito. En Swift no
/// existe ese choque porque `Calendar` trabaja con números (`weekday`), así que se
/// llama `Weekday` para no confundir a quien venga del original.
enum Weekday: String, Codable, CaseIterable, Identifiable, Hashable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: String { rawValue }

    /// Lunes, Martes, Miércoles, Jueves, Viernes, Sábado, Domingo -> L M X J V S D
    var short: String {
        switch self {
        case .monday: return "L"
        case .tuesday: return "M"
        case .wednesday: return "X"
        case .thursday: return "J"
        case .friday: return "V"
        case .saturday: return "S"
        case .sunday: return "D"
        }
    }

    var long: String {
        switch self {
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
        case .saturday: return "Sábado"
        case .sunday: return "Domingo"
        }
    }

    /// `Calendar.component(.weekday)` usa 1 = domingo ... 7 = sábado.
    init?(calendarWeekday: Int) {
        switch calendarWeekday {
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        case 1: self = .sunday
        default: return nil
        }
    }
}

/// Distribución de macros en porcentajes enteros. No se valida que sumen 100:
/// un repositorio real que redondea porcentajes produce 101 con frecuencia.
struct MacroSplit: Codable, Hashable {
    var carbsPct: Int
    var proteinPct: Int
    var fatPct: Int
}
