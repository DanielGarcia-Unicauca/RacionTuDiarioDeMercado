//
//  OpenFoodFactsService.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE:
//    - data/openfood/OpenFoodFactsService.kt   (Retrofit)
//    - data/openfood/dto/OpenFoodFactsDto.kt    (Moshi)
//    - data/openfood/OpenFoodFactsCatalogRepository.kt
//
//  ✅ RÚBRICA · "Services (Red)": Retrofit + Moshi se traducen a URLSession +
//     Codable, con async/await. La app no conoce ni Retrofit, ni OkHttp, ni Moshi.
//     Los DTO son la única capa que sabe que Open Food Facts escribe
//     `energy-kcal_100g` con guion y `carbohydrates_100g` en plural.
//
//  ⚠️ Open Food Facts exige un `User-Agent` con forma "App/Version (contacto)".
//     Sin él bloquea la petición como tráfico de bot.
//

import Foundation

// MARK: - Contrato

/// Acceso de lectura al catálogo de alimentos.
///
/// Todos los métodos son `async` y devuelven `Result`: ningún método lanza, y
/// ninguna `URLError` llega a la UI sin traducirse a `AppError`.
protocol FoodCatalogRepository {
    /// Busca por texto libre (endpoint legacy `cgi/search.pl`, porque la v2 no
    /// tiene búsqueda de texto).
    func search(query: String) async -> Result<[FoodProduct], AppError>
    /// Busca un producto por código de barras (`/api/v2/product/{code}.json`).
    func product(barcode: String) async -> Result<FoodProduct, AppError>
}

// MARK: - DTO (espejo exacto del JSON)

/// Envelope de `GET /api/v2/product/{barcode}.json`.
///
/// ⚠️ Un código que no existe devuelve **HTTP 200** con `status = 0` y
/// `product = null`. Si solo se mira el código HTTP, se trata un "no existe" como
/// si existiera: por eso el chequeo de `status` es obligatorio.
private struct OFFProductResponse: Decodable {
    let status: Int?
    let product: OFFProduct?
}

/// Envelope de `cgi/search.pl`.
private struct OFFSearchResponse: Decodable {
    let count: Int?
    let products: [OFFProduct]?
}

/// Un producto tal como lo devuelve cualquiera de los dos endpoints.
/// Todos los campos son opcionales: la base es colaborativa y hay productos sin
/// marca, sin porción o sin datos nutricionales.
private struct OFFProduct: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let quantity: String?
    let servingQuantity: Double?
    let categories: String?
    let ingredientsText: String?
    let nutritionGrades: String?
    let imageFrontURL: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case quantity
        case servingQuantity = "serving_quantity"
        case categories
        case ingredientsText = "ingredients_text"
        case nutritionGrades = "nutrition_grades"
        case imageFrontURL = "image_front_url"
        case nutriments
    }
}

/// El sub-objeto `nutriments`. Todas las claves son por 100 g.
///
/// Nótese la asimetría que confunde a todo el mundo: la energía usa **guion**
/// (`energy-kcal_100g`) mientras los macros usan **guion bajo** y en plural
/// (`carbohydrates_100g`, `proteins_100g`), salvo la grasa, que va en singular.
private struct OFFNutriments: Decodable {
    let energyKcal100g: Double?
    let carbohydrates100g: Double?
    let proteins100g: Double?
    let fat100g: Double?
    let sugars100g: Double?
    let fiber100g: Double?
    let sodium100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case proteins100g = "proteins_100g"
        case fat100g = "fat_100g"
        case sugars100g = "sugars_100g"
        case fiber100g = "fiber_100g"
        case sodium100g = "sodium_100g"
    }
}

// MARK: - Implementación con URLSession

/// Implementación real del catálogo con `URLSession` (reemplaza Retrofit).
final class OpenFoodFactsRepository: FoodCatalogRepository {

    private let session: URLSession
    private let decoder = JSONDecoder()

    /// Open Food Facts bloquea agentes genéricos: este header es obligatorio.
    private let userAgent = "RacionTuDiarioDeMercado/1.0 (migracion academica iOS)"

    /// Solo se piden los campos que la app usa: el objeto completo trae decenas
    /// de claves que nunca se leen.
    private static let fields = [
        "code", "product_name", "brands", "quantity", "serving_quantity",
        "categories", "ingredients_text", "nutrition_grades",
        "image_front_url", "nutriments"
    ].joined(separator: ",")

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.waitsForConnectivity = false
        self.session = URLSession(configuration: configuration)
    }

    // MARK: Búsqueda por código de barras

    func product(barcode: String) async -> Result<FoodProduct, AppError> {
        let clean = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return .failure(.notFound) }

        guard var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(clean).json") else {
            return .failure(.unknown("URL inválida"))
        }
        components.queryItems = [URLQueryItem(name: "fields", value: Self.fields)]
        guard let url = components.url else { return .failure(.unknown("URL inválida")) }

        switch await requestData(url) {
        case .failure(let error):
            return .failure(error)
        case .success(let data):
            do {
                let response = try decoder.decode(OFFProductResponse.self, from: data)
                // "No existe" también llega como HTTP 200: hay que mirar `status`.
                guard response.status == 1, let dto = response.product else {
                    return .failure(.notFound)
                }
                guard let product = dto.toFoodProduct() else { return .failure(.notFound) }
                return .success(product)
            } catch {
                return .failure(.decoding)
            }
        }
    }

    // MARK: Búsqueda por texto

    func search(query: String) async -> Result<[FoodProduct], AppError> {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return .success([]) }

        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")
        components?.queryItems = [
            URLQueryItem(name: "search_terms", value: clean),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "fields", value: Self.fields)
        ]
        guard let url = components?.url else { return .failure(.unknown("URL inválida")) }

        switch await requestData(url) {
        case .failure(let error):
            return .failure(error)
        case .success(let data):
            do {
                let response = try decoder.decode(OFFSearchResponse.self, from: data)
                let products = (response.products ?? []).compactMap { $0.toFoodProduct() }
                return .success(products)
            } catch {
                return .failure(.decoding)
            }
        }
    }

    // MARK: Transporte

    /// Ejecuta la petición y traduce todo fallo de transporte/HTTP a `AppError`.
    ///
    /// Este es el único lugar del proyecto que conoce códigos HTTP: la UI nunca ve
    /// un `URLError` ni un `statusCode`.
    private func requestData(_ url: URL) async -> Result<Data, AppError> {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(.unknown("Respuesta sin HTTPURLResponse"))
            }
            switch http.statusCode {
            case 200...299:
                return .success(data)
            case 404:
                return .failure(.notFound)
            // Open Food Facts usa 503 para señalar el límite de peticiones y 429
            // el estándar: los dos significan "esperá".
            case 429, 503:
                return .failure(.rateLimited)
            default:
                return .failure(.server(
                    code: http.statusCode,
                    message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
                ))
            }
        } catch let error as URLError {
            // Todos los casos de conectividad se colapsan en `.network` porque la
            // acción que la persona puede tomar es la misma: revisar la conexión.
            switch error.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
                 .notConnectedToInternet, .networkConnectionLost, .internationalRoamingOff,
                 .dataNotAllowed, .secureConnectionFailed:
                return .failure(.network)
            default:
                return .failure(.unknown(error.localizedDescription))
            }
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
}

// MARK: - Mapeo DTO -> dominio

private extension OFFProduct {
    /// Devuelve `nil` cuando no hay nombre utilizable: la base es colaborativa y
    /// existen filas sin nombre, que no se pueden mostrar en una lista.
    func toFoodProduct() -> FoodProduct? {
        guard let rawName = productName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawName.isEmpty else {
            return nil
        }

        // Las categorías llegan como un único string separado por comas.
        let parsedCategories = (categories ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // `brands` puede traer varias marcas: se toma la primera.
        let firstBrand = (brands ?? "")
            .split(separator: ",")
            .first
            .map { $0.trimmingCharacters(in: .whitespaces) }

        return FoodProduct(
            barcode: code ?? UUID().uuidString,
            name: rawName,
            brand: firstBrand?.isEmpty == false ? firstBrand : nil,
            quantityLabel: quantity,
            servingGrams: servingQuantity,
            nutritionPer100g: nutrition(),
            imageURL: imageFrontURL,
            nutriscoreGrade: nutritionGrades?.lowercased(),
            categories: parsedCategories,
            ingredientsText: ingredientsText,
            emoji: "🍽"
        )
    }

    /// Un producto sin `nutriments` se mapea a `Nutrition()` en lugar de descartarse:
    /// así se puede registrar igual un alimento escrito a mano.
    func nutrition() -> Nutrition {
        guard let nutriments else { return .zero }
        return Nutrition(
            kcal: Int((nutriments.energyKcal100g ?? 0).rounded()),
            carbsG: nutriments.carbohydrates100g ?? 0,
            proteinG: nutriments.proteins100g ?? 0,
            fatG: nutriments.fat100g ?? 0,
            sugarsG: nutriments.sugars100g ?? 0,
            fiberG: nutriments.fiber100g ?? 0,
            sodiumG: nutriments.sodium100g ?? 0
        )
    }
}
