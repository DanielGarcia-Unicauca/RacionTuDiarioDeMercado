//
//  AppError.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: core/AppResult.kt
//
//  ✅ RÚBRICA · "Services (Red)": toda operación que puede fallar devuelve
//     `Result<T, AppError>`. Ningún `URLError` ni código HTTP escapa de la capa de
//     red: se traduce aquí para que la UI decida qué decirle a la persona.
//

import Foundation

/// Taxonomía de fallos que la interfaz debe distinguir.
enum AppError: Error, Equatable {
    /// Sin conexión, DNS o timeout. Reintentable.
    case network
    /// El recurso no existe. Open Food Facts lo señala con HTTP 200 + `status: 0`.
    case notFound
    /// HTTP 429 o el 503 de Open Food Facts. Reintentable tras una espera.
    case rateLimited
    /// Cualquier otra respuesta no exitosa.
    case server(code: Int?, message: String?)
    /// El JSON no tuvo la forma esperada.
    case decoding
    /// Credenciales inválidas (lo usa el almacén de cuentas local).
    case unauthorized(String)
    /// Fallo no mapeado. El detalle es para logs, nunca para el usuario.
    case unknown(String)

    /// Mensaje en español para mostrar en pantalla.
    ///
    /// Cada caso tiene su propia frase a propósito: un "algo salió mal" compartido no
    /// le dice a la persona si reintentar sirve o no, que es la única decisión que el
    /// mensaje debe informar.
    var userMessage: String {
        switch self {
        case .network:
            return "Sin conexión. Revisá tu internet e intentá de nuevo."
        case .notFound:
            return "No encontramos ese producto en el catálogo."
        case .rateLimited:
            return "Demasiadas consultas. Esperá un momento e intentá otra vez."
        case .server:
            return "El servidor no respondió bien. Intentá de nuevo."
        case .decoding:
            return "Recibimos datos que no pudimos interpretar."
        case .unauthorized(let message):
            return message
        case .unknown:
            return "Ocurrió un error inesperado. Intentá de nuevo."
        }
    }
}
