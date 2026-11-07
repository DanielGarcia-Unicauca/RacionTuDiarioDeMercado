//
//  LocalCatalog.swift
//  Racion · Tu Diario de Mercado
//
//  NUEVO EN iOS (no existía en Android).
//
//  ✅ RÚBRICA · "Funcionalidad extra": tolerancia a fallos de red. Si Open Food
//     Facts no responde (sin internet, límite de peticiones, avión), la búsqueda
//     cae en este catálogo curado y la pantalla avisa "mostrando catálogo local"
//     en lugar de quedarse vacía o mostrar un error sin salida.
//

import Foundation

/// Catálogo offline con los platos típicos del proyecto.
///
/// Es el mismo conjunto de datos que usa el sembrado inicial (`SeedData`), así que
/// lo que se ve en la demo es exactamente lo que se puede buscar sin conexión.
final class LocalCatalog {

    private let products: [FoodProduct]

    init(products: [FoodProduct] = SeedData.products) {
        self.products = products
    }

    /// Búsqueda sincrónica (en memoria, no hay nada que esperar).
    func search(query: String, category: String?) -> [FoodProduct] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return products.filter { product in
            let matchesCategory = category == nil
                || category == AddFoodCategory.allLabel
                || product.categories.contains(where: { $0.caseInsensitiveCompare(category ?? "") == .orderedSame })
            guard matchesCategory else { return false }
            guard !term.isEmpty else { return true }
            return product.name.lowercased().contains(term)
                || (product.brand ?? "").lowercased().contains(term)
                || product.categories.contains(where: { $0.lowercased().contains(term) })
        }
    }

    func product(barcode: String) -> FoodProduct? {
        products.first { $0.barcode == barcode.trimmingCharacters(in: .whitespaces) }
    }

    var all: [FoodProduct] { products }
}

/// Categorías de la pantalla "Agregar". La primera es el filtro "Todos".
enum AddFoodCategory {
    static let allLabel = "Todos"
    static let names = [allLabel, "Almuerzo", "Frituras", "Sopas", "Bebidas"]
}
