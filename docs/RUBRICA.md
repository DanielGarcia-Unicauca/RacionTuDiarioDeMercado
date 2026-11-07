# Checklist de rúbrica

Cada punto de la rúbrica indicado con el archivo que lo cumple. Todos los comentarios del
código marcan el ítem con `✅ RÚBRICA · "..."`.

## 1. Arquitectura MVVM con módulos claros

**Estado: cumplido.**

`Racion.xcodeproj` documenta el target y `Racion/Sources/Racion/` materializa las cinco capas pedidas:

| Módulo | Carpeta | Responsabilidad |
|---|---|---|
| Views | `Racion/Sources/Racion/Views/` | Solo SwiftUI: dibujar y reportar intenciones |
| ViewModels | `Racion/Sources/Racion/ViewModels/` | Estado de pantalla + lógica de presentación |
| Models | `Racion/Sources/Racion/Models/` | Dominio puro, sin SwiftUI ni red |
| Services (Red) | `Racion/Sources/Racion/Services/` | `URLSession`, catálogo, informe, auth, formato |
| Persistence | `Racion/Sources/Racion/Persistence/` | JSON en disco + datos de demostración |

Evidencia de la separación:

- `Models/Nutrition.swift` no importa SwiftUI/UIKit; solo Foundation.
- Ninguna vista llama a `URLSession` ni a `FileStore`.
- `Views/HomeView.swift` consume `HomeViewModel`, que a su vez pide un `DailySummary` ya agregado.
- `Services/OpenFoodFactsService.swift` define el protocolo `FoodCatalogRepository`; `AppModel` lo inyecta.

## 2. Al menos 5 pantallas funcionales

**Estado: cumplido (9 pantallas + onboarding + login/registro).**

1. **Inicio** — `Views/HomeView.swift` (resumen del día, macros, comidas).
2. **Diario** — `Views/DiaryView.swift` (historial, filtro, edición de porciones, borrado).
3. **Agregar** — `Views/AddFoodView.swift` (búsqueda real en Open Food Facts + catálogo local).
4. **Escanear** — `Views/ScannerView.swift` (código manual, lectura simulada, recientes).
5. **Confirmar** — `Views/ConfirmView.swift` (porciones, comida, guardado).
6. **Informe** — `Views/ReportView.swift` (promedio, mejor día, racha, donut, barras).
7. **Metas / Perfil** — `Views/GoalsView.swift` (peso, kcal, días activos, recordatorios, cuenta).
8. **Perfil deportivo** — `Views/SportProfileView.swift` (enfoque y macros sugeridos).
9. **Aviso** — `Views/DisclaimerView.swift` (onboarding).
10. **Login / Registro** — `Views/AuthViews.swift`.

## 3. Pantalla nueva "Descripción y Créditos"

**Estado: cumplido.**

- Archivo: `Racion/Sources/Racion/Views/CreditsView.swift`.
- Muestra **nombre de la app**: "Ración — Tu Diario de Mercado".
- Muestra **nombre del equipo**: **Daniel Garcia** y **Julian Carvajal**.
- Describe la app, la tecnología, las fuentes de datos (Open Food Facts, ODbL) y las limitaciones.
- Se llega desde **Perfil → Descripción y créditos** (`GoalsView` → `NavigationLink(value: Route.credits)`)
  y desde el aviso de onboarding ("Ver política de uso y fuentes de datos").
- Incluye dos controles funcionales: `Toggle` de modo oscuro y restauración del diario de ejemplo.

## 4. Navegación con `NavigationStack` + `NavigationLink`

**Estado: cumplido.**

- `Views/RootView.swift`: `enum Route: Hashable` con todos los destinos y un `switch` exhaustivo en
  `navigationDestination(for: Route.self)`. Cada pestaña tiene su propio `NavigationStack`.
- `NavigationLink(value:)` en: `HomeView` (informe y FAB), `DiaryView` (agregar),
  `AddFoodView` (cada producto → confirmar), `GoalsView` (perfil deportivo, créditos, login),
  `LoginView` (registro).
- Ventaja documentada: las rutas son un enum tipado, no strings; agregar un caso sin destino no compila.

## 5. Controles nativos: `TextField`, `Toggle`, `Stepper`

**Estado: cumplido.**

| Control | Dónde | Nota |
|---|---|---|
| `TextField` | `AddFoodView.swift`, `ScannerView.swift`, `AuthViews.swift` | con `@FocusState`, teclado adecuado |
| `Toggle` | `DiaryView.swift` ("Solo hoy"), `GoalsView.swift` ("Recordatorios"), `CreditsView.swift` ("Modo oscuro") | persistidos donde corresponde |
| `Stepper` | `ConfirmView.swift` y `DiaryView.swift` (hoja de edición) | porciones, rango 1…20 |

## 6. Gestión de estado: `@State`, `@Binding`, `@StateObject`, `@ObservedObject`

**Estado: cumplido.**

| Propiedad | Uso concreto |
|---|---|
| `@State` | `RootView` (`showOnboarding`), `AddFoodView` (`searchFocused`), `ScannerView` (`laserProgress`, `barcodeFocused`), `OnboardingView` (`step`, `showPolicy`) |
| `@Binding` | `ScannerView.path`, `SportFocusPicker.selected`, `GoalSlider.value` |
| `@StateObject` | `RootView.app` (dueño del `AppModel`), y cada pantalla dueña de su ViewModel (`HomeView`, `DiaryView`, `AddFoodView`, `ScannerView`, `ConfirmView`, `GoalsView`, `ReportView`, `SportProfileView`, `LoginView`, `RegisterView`) |
| `@ObservedObject` | `DiaryEditSheet` recibe el `DiaryViewModel` que ya posee `DiaryView` (ver el comentario en `DiaryView.swift`) |
| `@EnvironmentObject` | `AppModel` inyectado con `.environmentObject(app)` en `RootView` |

## 7. Persistencia local aislada

**Estado: cumplido (archivos JSON; la rúbrica permite SwiftData o archivos).**

- `Racion/Sources/Racion/Persistence/FileStore.swift`: escritura **atómica**, carga tolerante a archivos
  ausentes/corruptos, directorio `Application Support/Racion/`.
- Archivos: `diary.json`, `goals.json`, `profile.json`, `settings.json`, `users.json`, `session.json`.
- Único punto de acceso: `AppModel` (`persistDiary`, `persistSettings`, `saveGoals`, …). Las Views y los
  ViewModels nunca ven una ruta de disco.
- Se sembró la demo una sola vez (`hasSeededDemoData`) y sobrevive a reinicios; se puede restaurar desde
  Créditos (`resetDemoData()`).

## 8. Capa de red: Retrofit → `URLSession`

**Estado: cumplido.**

- `Racion/Sources/Racion/Services/OpenFoodFactsService.swift`:
  - `protocol FoodCatalogRepository` con `search(query:)` y `product(barcode:)`.
  - DTO `Codable` espejo del JSON (`product_name`, `energy-kcal_100g`, `carbohydrates_100g`, …).
  - `URLSession` con timeout, `User-Agent` obligatorio y traducción de **todo** fallo a `AppError`
    (sin `URLError` ni códigos HTTP en la UI).
  - Detalle real de Open Food Facts: un código inexistente devuelve **HTTP 200 con `status = 0`**;
    se chequea `status`, no solo el código HTTP.
- Respaldo sin conexión: `Services/LocalCatalog.swift` + aviso en pantalla.
- Debounce de 350 ms en `AddFoodView` (`.task(id: query)`).

## 9. Mejora extra documentada

**Estado: cumplido (varias, todas comentadas en el código).**

1. **Informe semanal real** — `Services/ReportBuilder.swift` calcula promedio, mejor día, racha y
   barras desde las entradas; en Android eran literales de `PreviewData`.
2. **Tolerancia a fallos de red** — catálogo local + estados de carga/error/vacío.
3. **Modo oscuro** con colores adaptativos y `preferredColorScheme` (`Theme/Theme.swift`).
4. **Háptica** en guardados y selecciones (`Theme/Theme.swift`, `Haptics`).
5. **Rutas tipadas** con `enum Route` (imposible navegar a un destino inexistente).
6. **Restaurar demo** desde Créditos.

## 10. Documentación en español y reflexión

**Estado: cumplido.**

- Todos los archivos tienen cabecera explicando su equivalente Android.
- `docs/REFLEXION.md`: ~250 palabras comparando Compose/XML vs SwiftUI (experiencia, sintaxis, estado y arquitectura).
- `README.md`: arquitectura, compilación, pantallas, cambios y limitaciones.

## 11. Compilación

**Estado: verificado.**

```
$ xcodebuild -project Racion.xcodeproj -scheme Racion \
             -sdk iphonesimulator -configuration Debug \
             -destination 'generic/platform=iOS Simulator' \
             CODE_SIGNING_ALLOWED=NO build
** BUILD SUCCEEDED **
```

- Toolchain: Xcode 26.2 (SDK iOS 26.2, deployment target iOS 17.0) en macOS; sin Apple ID.
- La app se instaló y recorrió en el simulador iPhone 16 Pro (iOS 18.6): onboarding, diario, alta de
  alimentos, escáner, informe, metas, login/registro y persistencia entre lanzamientos.
- El proyecto compila en Swift 5 language mode para evitar el ruido de *strict concurrency* de Swift 6 en
  una base de código nueva; `async/await` y `@MainActor` se usan explícitamente.

Prueba de humo de la lógica (dominio + informe + persistencia + auth): **19/19 OK**,
incluido el redondeo único de porciones y la racha de 7 días.
