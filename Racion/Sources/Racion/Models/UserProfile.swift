//
//  UserProfile.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: domain/model/UserProfile.kt
//
//  ✅ RÚBRICA · "Models": el perfil es mínimo a propósito. Las metas viven en su
//     propio archivo de persistencia, así guardar una no pisa la otra.
//

import Foundation

struct UserProfile: Codable, Hashable {
    var userId: String
    var displayName: String = ""
    var sportFocus: SportFocus = .mantenimiento
    var currentWeightKg: Double = 68

    static let demo = UserProfile(
        userId: "local-user",
        displayName: "Daniel",
        sportFocus: .running,
        currentWeightKg: 68
    )
}

/// Enfoque de entrenamiento elegido en el onboarding; ajusta las metas sugeridas.
///
/// `title` y `description` están en español porque se muestran tal cual en la
/// pantalla "Perfil deportivo". Se persiste el `rawValue`, nunca los textos.
enum SportFocus: String, Codable, CaseIterable, Identifiable, Hashable {
    case futbol, running, fuerza, ciclismo, perdidaPeso, mantenimiento

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .futbol: return "⚽️"
        case .running: return "🏃"
        case .fuerza: return "🏋️"
        case .ciclismo: return "🚴"
        case .perdidaPeso: return "🔥"
        case .mantenimiento: return "🌿"
        }
    }

    var title: String {
        switch self {
        case .futbol: return "Fútbol"
        case .running: return "Running"
        case .fuerza: return "Fuerza"
        case .ciclismo: return "Ciclismo"
        case .perdidaPeso: return "Pérdida de peso"
        case .mantenimiento: return "Mantenimiento"
        }
    }

    var detail: String {
        switch self {
        case .futbol: return "Carga de carbos en días de partido"
        case .running: return "Enfoque en resistencia y recuperación"
        case .fuerza: return "Más proteína, superávit moderado"
        case .ciclismo: return "Energía sostenida, carbos altos"
        case .perdidaPeso: return "Déficit controlado y gradual"
        case .mantenimiento: return "Balance general, sin objetivo específico"
        }
    }

    /// Reparto de macros sugerido. `nil` = "mantené lo que el usuario ya tenía",
    /// que es el comportamiento correcto para Mantenimiento.
    var suggestedMacroSplit: MacroSplit? {
        switch self {
        case .futbol: return MacroSplit(carbsPct: 55, proteinPct: 20, fatPct: 25)
        case .running: return MacroSplit(carbsPct: 50, proteinPct: 20, fatPct: 30)
        case .fuerza: return MacroSplit(carbsPct: 35, proteinPct: 30, fatPct: 35)
        case .ciclismo: return MacroSplit(carbsPct: 55, proteinPct: 15, fatPct: 30)
        case .perdidaPeso: return MacroSplit(carbsPct: 40, proteinPct: 30, fatPct: 30)
        case .mantenimiento: return nil
        }
    }
}
