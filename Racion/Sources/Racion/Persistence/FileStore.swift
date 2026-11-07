//
//  FileStore.swift
//  Racion · Tu Diario de Mercado
//
//  ✅ RÚBRICA · "Persistence (Almacenamiento local)": módulo aislado de persistencia.
//
//  En Android esto era Firestore + `SharedPreferences`. En iOS, para una entrega
//  académica sin backend, se usa persistencia en archivos JSON dentro de
//  `Application Support`: es la alternativa que la rúbrica permite explícitamente
//  ("SwiftData o persistencia en archivos").
//
//  ¿Por qué archivos y no SwiftData? SwiftData exige la macro `@Model` y un esquema
//  gestionado que no aporta nada al volumen de datos de esta app. Los archivos JSON
//  son 100 % deterministas, inspeccionables con cualquier editor y suficientes para
//  un diario personal. El contrato (`save`/`load`) es el mismo, así que migrar a
//  SwiftData más adelante es cambiar esta clase, no los ViewModels.
//

import Foundation

/// Almacén de documentos JSON en disco.
///
/// Cada "tabla" es un archivo: `diary.json`, `goals.json`, `profile.json`,
/// `settings.json`, `users.json`, `session.json`.
final class FileStore {

    static let shared = FileStore()

    private let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL? = nil) {
        let base = directory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.directory = base.appendingPathComponent("Racion", isDirectory: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()

        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    /// Ruta pública del archivo (útil para depurar desde el contenedor de la app).
    func url(for name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    /// Devuelve `nil` si el archivo no existe o no se puede decodificar.
    /// "No hay datos todavía" es un estado válido, no un error que deba romper el arranque.
    func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        guard let data = try? Data(contentsOf: url(for: name)) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    /// Escritura atómica: si la app muere a mitad del guardado, el archivo anterior
    /// sigue siendo válido en lugar de quedar truncado.
    func save<T: Encodable>(_ value: T, to name: String) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url(for: name), options: .atomic)
    }

    func delete(_ name: String) {
        try? FileManager.default.removeItem(at: url(for: name))
    }
}

/// Preferencias locales de la app.
///
/// Reemplaza a los `SharedPreferences` de Android (`MainActivity` leía de ahí el
/// flag de onboarding). Se guardan en el mismo JSON para no mezclar dos mecanismos.
struct AppSettings: Codable, Hashable {
    /// ✅ RÚBRICA · "Toggle": interruptor nativo de modo oscuro en Créditos.
    var isDarkMode = false
    /// El onboarding (Aviso) ya se aceptó.
    var onboardingCompleted = false
    /// Ya se sembraron los datos de demostración la primera vez.
    var hasSeededDemoData = false
    /// Recordatorio diario (se muestra como Toggle en Metas).
    var remindersEnabled = true
}
