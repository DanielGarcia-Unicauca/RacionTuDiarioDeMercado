//
//  Nutrition.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: domain/model/Nutrition.kt
//
//  ✅ RÚBRICA · "Models": capa de dominio pura. Este archivo no importa SwiftUI,
//     ni UIKit, ni nada de red. Solo Swift puro + Foundation. Es lo que permite
//     testear la aritmética nutricional sin levantar la interfaz.
//
//  Todo va en gramos salvo `kcal`, que son kilocalorías. Es el único lugar donde
//  vive la aritmética de nutrientes, así la pantalla de Inicio no puede contradecir
//  al resumen semanal.
//

import Foundation

/// Valor nutricional inmutable.
///
/// En Kotlin era un `data class` con `copy()` y `plus`. En Swift el equivalente es
/// un `struct` (semántica de valor) con `mutating`/métodos que devuelven copias.
/// Codable se sintetiza automáticamente: eso es lo que permite guardar el diario
/// completo como JSON en el módulo de persistencia.
struct Nutrition: Codable, Hashable {
    var kcal: Int = 0
    var carbsG: Double = 0
    var proteinG: Double = 0
    var fatG: Double = 0
    var sugarsG: Double = 0
    var fiberG: Double = 0
    var sodiumG: Double = 0

    /// Valor neutro: sirve como semilla del `reduce` que calcula el total del día.
    static let zero = Nutrition()

    /// Multiplica todos los valores por `factor`.
    ///
    /// Se usa para proyectar los datos "por 100 g" sobre una porción arbitraria
    /// (`factor = 1.5`) o sobre N unidades (`factor = 2.0`).
    ///
    /// Las kcal se redondean una sola vez, al final, porque las calorías son un
    /// conteo y `265.4 kcal` no significa nada en pantalla. Se redondea "half up"
    /// para que la suma de las partes no quede sesgada hacia abajo.
    func scaled(_ factor: Double) -> Nutrition {
        if factor == 1 { return self }
        return Nutrition(
            kcal: Int((Double(kcal) * factor).rounded()),
            carbsG: carbsG * factor,
            proteinG: proteinG * factor,
            fatG: fatG * factor,
            sugarsG: sugarsG * factor,
            fiberG: fiberG * factor,
            sodiumG: sodiumG * factor
        )
    }
}

/// Suma componente a componente.
///
/// En Kotlin era el `operator fun plus`. En Swift se declara igual con `static func +`
/// y así el total del día se escribe exactamente igual que en el original:
/// `total = total + entry.totalNutrition`.
func + (lhs: Nutrition, rhs: Nutrition) -> Nutrition {
    Nutrition(
        kcal: lhs.kcal + rhs.kcal,
        carbsG: lhs.carbsG + rhs.carbsG,
        proteinG: lhs.proteinG + rhs.proteinG,
        fatG: lhs.fatG + rhs.fatG,
        sugarsG: lhs.sugarsG + rhs.sugarsG,
        fiberG: lhs.fiberG + rhs.fiberG,
        sodiumG: lhs.sodiumG + rhs.sodiumG
    )
}

extension Nutrition {
    /// Suma un arreglo de valores nutricionales. Reemplaza al `fold(Nutrition()) { ... }`
    /// de Kotlin, que en Swift se escribe `reduce(.zero, +)`.
    static func total(of values: [Nutrition]) -> Nutrition {
        values.reduce(.zero, +)
    }
}
