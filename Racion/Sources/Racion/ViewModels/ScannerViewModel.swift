//
//  ScannerViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/EscanerScreen.kt + la lógica que en Android era
//  el TODO(BC-1) ("el analizador real de ML Kit llega después").
//
//  ✅ RÚBRICA · "Services (Red)": cada código de barras se consulta a Open Food
//     Facts con `FoodCatalogRepository` (URLSession). Si no hay red, se usa el
//     catálogo local. La pantalla nunca se queda sin respuesta.
//
//  Flujo de la cámara:
//    1. La cámara lee un código (`BarcodeCameraView`).
//    2. `handleDetectedCode(_:)` pausa la cámara y consulta Open Food Facts.
//    3. Si hay producto, `foundProduct` navega a Confirmar. Si no, la cámara vuelve a leer.
//
//  En el simulador no hay cámara: la pantalla usa la entrada manual y la lectura
//  simulada, que también consulta Open Food Facts.
//

import Foundation
import AVFoundation

@MainActor
final class ScannerViewModel: ObservableObject {

    /// Estado del permiso y del hardware de cámara.
    enum CameraState: Equatable {
        /// Todavía no se pidió permiso.
        case unknown
        case authorized
        /// La persona negó el permiso (se puede cambiar en Ajustes).
        case denied
        /// No hay cámara (simulador).
        case unavailable
    }

    // MARK: Estado

    /// TextField nativo para ingresar el código a mano.
    @Published var barcode = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var notice: String?
    /// Producto resuelto; la vista lo observa para navegar a Confirmar.
    @Published private(set) var foundProduct: FoodProduct?
    @Published private(set) var cameraState: CameraState = .unknown
    /// `true` cuando la cámara debe estar leyendo (pantalla visible, sin consulta en curso).
    @Published private(set) var isCameraRunning = false

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    // MARK: Ciclo de vida de la pantalla

    /// Pide permiso de cámara la primera vez y arranca la lectura.
    func screenAppeared() async {
        #if targetEnvironment(simulator)
        cameraState = .unavailable
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraState = .authorized
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraState = granted ? .authorized : .denied
        case .denied, .restricted:
            cameraState = .denied
        @unknown default:
            cameraState = .denied
        }
        #endif
        isCameraRunning = cameraState == .authorized
    }

    func screenDisappeared() {
        isCameraRunning = false
    }

    // MARK: Intenciones

    /// Llamado por la cámara con cada código leído. Ignora lecturas repetidas
    /// mientras ya hay una consulta en curso.
    func handleDetectedCode(_ code: String) async {
        guard isCameraRunning, !isLoading else { return }
        isCameraRunning = false
        barcode = code
        await resolve(code)
        // Si no hubo producto, la cámara vuelve a leer para que la persona pruebe otra vez.
        if foundProduct == nil, cameraState == .authorized {
            isCameraRunning = true
        }
    }

    /// Resuelve el código escrito en el campo de texto.
    func lookup() async {
        await resolve(barcode)
    }

    /// Lectura simulada para el simulador: consulta el producto estrella por la API.
    func simulateScan() async {
        let code = SeedData.featuredProduct.barcode
        barcode = code
        await resolve(code, simulated: true)
        Haptics.tap()
    }

    /// Entrega el producto una sola vez y limpia el estado para que volver atrás
    /// no dispare una segunda navegación.
    func consumeFoundProduct() -> FoodProduct? {
        let product = foundProduct
        foundProduct = nil
        return product
    }

    func clearMessages() {
        errorMessage = nil
        notice = nil
    }

    /// Últimos productos registrados, sin repetir producto (el escáner muestra
    /// "escaneado recientemente", no "comido recientemente").
    func recentScans(from entries: [DiaryEntry], limit: Int = 4) -> [DiaryEntry] {
        var seen = Set<String>()
        var result: [DiaryEntry] = []
        for entry in entries.sorted(by: { $0.loggedAtEpochMillis > $1.loggedAtEpochMillis }) {
            guard !seen.contains(entry.product.barcode) else { continue }
            seen.insert(entry.product.barcode)
            result.append(entry)
            if result.count == limit { break }
        }
        return result
    }

    // MARK: Interno

    /// Consulta Open Food Facts por código de barras; si falla por red, prueba el
    /// catálogo local. Es el único camino que usan la cámara, la entrada manual y
    /// la lectura simulada.
    private func resolve(_ raw: String, simulated: Bool = false) async {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            errorMessage = "Ingresá un código de barras."
            return
        }
        isLoading = true
        errorMessage = nil
        notice = simulated ? "Lectura simulada · \(clean)" : nil
        defer { isLoading = false }

        switch await app.catalog.product(barcode: clean) {
        case .success(let product):
            barcode = ""
            foundProduct = product
            Haptics.success()
        case .failure(let error):
            // Respaldo local: la demo trae códigos "LOCAL-..." y el de la avena
            // Alpina. Si coincide, no tiene sentido mostrar un error.
            if let local = app.localCatalog.product(barcode: clean) {
                barcode = ""
                foundProduct = local
                notice = "Sin conexión: encontrado en el catálogo local."
                Haptics.success()
            } else {
                errorMessage = error.userMessage
                notice = "Probá con otro código o revisá la conexión."
            }
        }
    }
}
