//
//  CloudStore.swift
//  Racion · Tu Diario de Mercado
//
//  Persistencia en la nube (Cloud Firestore) para usuarios con sesión iniciada.
//
//  Estructura en Firestore (todo bajo el uid del usuario autenticado):
//    users/{uid}/entries/{entryId}   → una entrada del diario (DiaryEntry)
//    users/{uid}/meta/goals          → metas nutricionales (NutritionGoals)
//    users/{uid}/meta/profile        → perfil de usuario (UserProfile)
//
//  Las reglas que lo protegen están en `firestore.rules` (raíz del proyecto).
//
//  Los modelos se convierten a diccionarios con `JSONEncoder`/`JSONDecoder`, así se
//  reutilizan los mismos `Codable` que usa `FileStore` y no depende de
//  `FirebaseFirestoreSwift` (que cambió de paquete entre versiones del SDK).
//
//  Offline: Firestore guarda los cambios en caché local y los envía al recuperar la
//  conexión. Por eso `apply…` no espera a que el servidor confirme sin conexión.
//

import Foundation
import FirebaseFirestore

final class CloudStore {

    /// Límite de Firestore por lote de escritura: 500 operaciones.
    private static let batchLimit = 400

    /// Se crea al primer uso (no en `init`) para no tocar Firestore antes de
    /// `FirebaseApp.configure()`.
    private lazy var db = Firestore.firestore()

    // MARK: - Lecturas

    func fetchEntries(uid: String) async throws -> [DiaryEntry] {
        let snapshot = try await db.collection(Path.entries(uid)).getDocuments()
        return try snapshot.documents.map { try Self.decode(DiaryEntry.self, from: $0.data()) }
    }

    func fetchGoals(uid: String) async throws -> NutritionGoals? {
        let snapshot = try await db.document(Path.goals(uid)).getDocument()
        guard let data = snapshot.data() else { return nil }
        return try Self.decode(NutritionGoals.self, from: data)
    }

    func fetchProfile(uid: String) async throws -> UserProfile? {
        let snapshot = try await db.document(Path.profile(uid)).getDocument()
        guard let data = snapshot.data() else { return nil }
        return try Self.decode(UserProfile.self, from: data)
    }

    // MARK: - Escrituras

    /// Aplica altas/cambios y borrados del diario en lotes. Solo se envía lo que cambió.
    func applyEntryChanges(uid: String, upserts: [DiaryEntry], deletes: [String]) async throws {
        var operations: [WriteOperation] = []
        for entry in upserts {
            let reference = db.collection(Path.entries(uid)).document(entry.id)
            operations.append(WriteOperation(reference: reference, data: try Self.encode(entry)))
        }
        for id in deletes {
            let reference = db.collection(Path.entries(uid)).document(id)
            operations.append(WriteOperation(reference: reference, data: nil))
        }
        try await commitInBatches(operations)
    }

    /// Guarda metas y perfil juntos (son dos documentos pequeños).
    func saveMeta(uid: String, goals: NutritionGoals, profile: UserProfile) async throws {
        let batch = db.batch()
        batch.setData(try Self.encode(goals), forDocument: db.document(Path.goals(uid)))
        batch.setData(try Self.encode(profile), forDocument: db.document(Path.profile(uid)))
        try await batch.commit()
    }

    // MARK: - Lotes

    /// Una escritura: `data == nil` significa borrar el documento.
    private struct WriteOperation {
        let reference: DocumentReference
        let data: [String: Any]?
    }

    private func commitInBatches(_ operations: [WriteOperation]) async throws {
        var start = 0
        while start < operations.count {
            let end = min(start + Self.batchLimit, operations.count)
            let batch = db.batch()
            for operation in operations[start..<end] {
                if let data = operation.data {
                    batch.setData(data, forDocument: operation.reference)
                } else {
                    batch.deleteDocument(operation.reference)
                }
            }
            try await batch.commit()
            start = end
        }
    }

    // MARK: - Conversión Codable <-> Firestore

    private static func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.decoding
        }
        return dictionary
    }

    private static func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(type, from: data)
    }

    // MARK: - Rutas

    private enum Path {
        static func entries(_ uid: String) -> String { "users/\(uid)/entries" }
        static func goals(_ uid: String) -> String { "users/\(uid)/meta/goals" }
        static func profile(_ uid: String) -> String { "users/\(uid)/meta/profile" }
    }
}
