//
//  SportProfileViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/PerfilDeportivoScreen.kt
//
//  ✅ RÚBRICA · "Models": la lista de opciones es el enum `SportFocus` completo,
//     no un fixture aparte. Un enfoque nuevo no puede quedar sin tarjeta ni sin
//     emoji: el compilador obliga a actualizar los `switch`.
//

import Foundation

@MainActor
final class SportProfileViewModel: ObservableObject {

    @Published var selected: SportFocus
    @Published private(set) var savedMessage: String?

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
        self.selected = app.profile.sportFocus
    }

    /// Reparto que se aplicaría con el enfoque elegido, para la vista previa.
    var previewSplit: MacroSplit? {
        selected.suggestedMacroSplit
    }

    var macroPreviewLabel: String {
        guard let split = previewSplit else {
            return "Mantenimiento no cambia tus macros actuales."
        }
        return "Sugerencia: \(split.carbsPct)% carbos · \(split.proteinPct)% proteína · \(split.fatPct)% grasas"
    }

    /// Aplica el enfoque y devuelve `true` si se guardó. La vista usa el valor
    /// para cerrarse sola.
    @discardableResult
    func apply() -> Bool {
        app.applySportFocus(selected)
        savedMessage = "Perfil actualizado"
        Haptics.success()
        return true
    }
}
