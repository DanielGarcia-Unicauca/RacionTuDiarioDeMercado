//
//  AddFoodViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/AgregarScreen.kt + la lógica de búsqueda que en
//  Android nunca llegó a implementarse (OFF-3 era un TODO).
//
//  ✅ RÚBRICA · "Services (Red)": consume `FoodCatalogRepository` (URLSession).
//  ✅ RÚBRICA · "Funcionalidad extra": debounce de 350 ms, estados de carga y
//     respaldo automático al catálogo local cuando no hay red.
//
//  La búsqueda de Open Food Facts limita a ~10 peticiones por minuto, así que
//  buscar en cada tecla agotaría la cuota en una sola frase. La vista dispara
//  `reload()` desde `.task(id: query)`; SwiftUI cancela la tarea anterior y solo
//  la última tecla llega a la red.
//

import Foundation

@MainActor
final class AddFoodViewModel: ObservableObject {

    // MARK: Estado de la vista

    @Published var query = ""
    @Published private(set) var selectedCategory = AddFoodCategory.allLabel
    @Published private(set) var results: [FoodProduct] = []
    @Published private(set) var isLoading = false
    @Published private(set) var notice: String?
    @Published private(set) var errorMessage: String?

    /// Resultado "crudo" de la última búsqueda, antes del filtro de categoría.
    /// Se conserva para que cambiar de categoría no vuelva a gastar una petición.
    private var baseResults: [FoodProduct] = []

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
        self.baseResults = app.localCatalog.all
        self.results = app.localCatalog.all
    }

    var categories: [String] { AddFoodCategory.names }

    var isEmpty: Bool { !isLoading && results.isEmpty }

    // MARK: Intenciones

    /// Cambia el filtro y re-filtra en memoria (sin red).
    func select(category: String) {
        selectedCategory = category
        applyCategoryFilter()
        Haptics.tap()
    }

    /// Búsqueda con debounce. La vista la llama desde `.task(id: query)`.
    func reload() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        notice = nil
        errorMessage = nil

        // Sin texto no se consulta la red: se muestra el catálogo local completo
        // (instantáneo y sin gastar cuota).
        guard !term.isEmpty else {
            baseResults = app.localCatalog.search(query: "", category: nil)
            applyCategoryFilter()
            return
        }

        isLoading = true
        defer { isLoading = false }

        switch await app.catalog.search(query: term) {
        case .success(let list) where !list.isEmpty:
            baseResults = list
            applyCategoryFilter()
            notice = "Resultados en vivo de Open Food Facts."
        case .success:
            baseResults = app.localCatalog.search(query: term, category: nil)
            applyCategoryFilter()
            notice = "Sin resultados en línea: mostrando el catálogo local."
        case .failure(let error):
            // El fallo de red no deja la pantalla vacía: se cae al catálogo curado.
            baseResults = app.localCatalog.search(query: term, category: nil)
            applyCategoryFilter()
            errorMessage = error.userMessage
            notice = "Mostrando el catálogo local."
        }
    }

    // MARK: Interno

    private func applyCategoryFilter() {
        guard selectedCategory != AddFoodCategory.allLabel else {
            results = baseResults
            return
        }
        results = baseResults.filter { product in
            product.categories.contains {
                $0.caseInsensitiveCompare(selectedCategory) == .orderedSame
            }
        }
    }
}
