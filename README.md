# Ración — Tu Diario de Mercado · iOS (SwiftUI)

Migración a **iOS/SwiftUI** de la app Android `RacionTuDiarioDeMercado` (Kotlin + Jetpack Compose + Firebase + Open Food Facts).
El objetivo es que cada pantalla, cada dato y cada regla de negocio del original existan en iOS, con una arquitectura
MVVM equivalente dentro de un proyecto de Xcode listo para compilar y ejecutar.

| | Android original | iOS (esta entrega) |
|---|---|---|
| UI | Jetpack Compose + Material 3 | SwiftUI + design system propio (`Theme/`) |
| Estado | `ViewModel` + `StateFlow` + `collectAsStateWithLifecycle` | `ObservableObject` + `@Published` + `@StateObject` |
| Navegación | `NavHost` + rutas `String` | `NavigationStack` + `navigationDestination(for: Route.self)` |
| Red | Retrofit + Moshi | `URLSession` + `Codable` + `async/await` |
| Persistencia | Firestore + `SharedPreferences` | Archivos JSON en `Application Support` |
| Autenticación | Firebase Auth (sin implementar) | `AuthService` local con sal por usuario |
| Cámara | ML Kit (sin implementar) | Entrada manual + lectura simulada del catálogo local |
| Build | Gradle + Android Studio | Xcode (`Racion.xcodeproj`) + `xcodebuild` |

## Estado de la entrega

- **Compila**: `xcodebuild -project Racion.xcodeproj -scheme Racion -sdk iphonesimulator build` termina con `** BUILD SUCCEEDED **` (probado con Xcode 26.2 / SDK iOS 26.2, deployment target iOS 17.0).
- **Funciona**: la app se instaló y se recorrió en el simulador de iPhone (onboarding, inicio, diario, alta de alimentos, escáner, informe, metas, perfil, login/registro, créditos y persistencia entre lanzamientos).
- **Lógica verificada**: 19 comprobaciones ejecutables sobre dominio, informe, persistencia y auth (ver más abajo).

## Requisitos

- **macOS** con **Xcode 16** (o superior) y sus simuladores de iOS.
- No hace falta Apple ID ni cuenta de desarrollador para **compilar y ejecutar en el simulador**.

## Cómo compilar

Abre `Racion.xcodeproj` en Xcode, elige el esquema **Racion** y un simulador de iPhone, y pulsa **Run** (⌘R).

También se puede compilar desde la terminal, en la raíz del proyecto:

```bash
xcodebuild -project Racion.xcodeproj -scheme Racion \
           -sdk iphonesimulator -configuration Debug \
           -destination 'generic/platform=iOS Simulator' \
           CODE_SIGNING_ALLOWED=NO build
```

Salida esperada:

```
** BUILD SUCCEEDED **
```

Para instalarlo en el simulador desde la terminal:

```bash
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/Racion-*/Build/Products/Debug-iphonesimulator/Racion.app
xcrun simctl launch booted com.equipo.racion
```

> Para **instalar en un iPhone físico** sí se necesita un Apple ID (gratuito) y el dispositivo conectado:
> selecciona tu equipo en *Signing & Capabilities* y ejecuta desde Xcode. Ese paso queda fuera de esta
> entrega, que se evalúa en el simulador.

## Estructura

```
Racion.xcodeproj/              proyecto Xcode (target y esquema compartido «Racion»)
Racion/
├─ Info.plist                 bundle, orientación y capacidades
├─ Assets.xcassets/           AppIcon y AccentColor
└─ Sources/Racion/
   ├─ App/
   │  ├─ RacionApp.swift        @main: WindowGroup -> RootView
   │  └─ AppModel.swift         composición raíz: estado, CRUD, auth, seed, ajustes
   ├─ Models/                   dominio puro (sin SwiftUI ni red)
   │  ├─ Nutrition.swift        aritmética de nutrientes (único lugar que suma kcal)
   │  ├─ FoodProduct.swift      producto normalizado por 100 g + nutrition(forUnits:)
   │  ├─ DiaryEntry.swift       entrada del diario + MealSlot
   │  ├─ NutritionGoals.swift   metas, Weekday, MacroSplit
   │  ├─ DailySummary.swift     agregado de un día
   │  ├─ WeeklyReport.swift     agregado semanal + DayTotal
   │  ├─ UserProfile.swift      perfil + SportFocus
   │  └─ AppError.swift         taxonomía de errores con mensaje en español
   ├─ ViewModels/               9 ViewModels (@MainActor, ObservableObject)
   │  ├─ HomeViewModel.swift
   │  ├─ DiaryViewModel.swift
   │  ├─ AddFoodViewModel.swift
   │  ├─ ScannerViewModel.swift
   │  ├─ ConfirmViewModel.swift
   │  ├─ GoalsViewModel.swift
   │  ├─ ReportViewModel.swift
   │  ├─ SportProfileViewModel.swift
   │  └─ LoginViewModel.swift
   ├─ Services/
   │  ├─ OpenFoodFactsService.swift   URLSession + DTO + mapeo a dominio
   │  ├─ LocalCatalog.swift           catálogo offline + categorías
   │  ├─ ReportBuilder.swift          agregación semanal real
   │  ├─ AuthService.swift            cuentas locales (FNV-1a + sal)
   │  └─ Formatters.swift             fechas, unidades, "hace 3 días"
   ├─ Persistence/
   │  ├─ FileStore.swift              JSON atómico + AppSettings
   │  └─ SeedData.swift               catálogo y diario de demostración
   ├─ Theme/
   │  ├─ Theme.swift                  colores dinámicos claro/oscuro, tipografía, háptica
   │  ├─ Components.swift             PrimaryButton, MealRow, banners, tarjetas…
   │  └─ Charts.swift                 donut de macros, barras semanales, barra de progreso
   └─ Views/
      ├─ RootView.swift               TabView + 4 NavigationStack + Route + onboarding
      ├─ HomeView.swift               Inicio
      ├─ DiaryView.swift              Diario (nueva en iOS)
      ├─ AddFoodView.swift            Agregar
      ├─ ScannerView.swift            Escanear
      ├─ ConfirmView.swift            Confirmar
      ├─ ReportView.swift             Informe
      ├─ GoalsView.swift              Metas / Perfil
      ├─ SportProfileView.swift       Perfil deportivo
      ├─ DisclaimerView.swift         Aviso legal
      ├─ AuthViews.swift              Login + Registro
      └─ CreditsView.swift            Descripción y Créditos (pantalla nueva obligatoria)
```

Regla de dependencias: **Views → ViewModels → Models**. `Services` y `Persistence` implementan contratos y
nunca son importados por las Views. Ninguna vista conoce una ruta de disco, un `URLRequest` ni un `JSONDecoder`.

## Pantallas (9 + onboarding)

| # | Pantalla | Archivo | Controles nativos |
|---|---|---|---|
| 1 | Inicio | `HomeView.swift` | `NavigationLink`, barra de progreso |
| 2 | Diario | `DiaryView.swift` | `Toggle` (solo hoy), `Stepper` (porciones) |
| 3 | Agregar | `AddFoodView.swift` | `TextField`, `@FocusState`, pastillas |
| 4 | Escanear | `ScannerView.swift` | `TextField`, animación del láser |
| 5 | Confirmar | `ConfirmView.swift` | `Stepper` |
| 6 | Informe | `ReportView.swift` | `Canvas` (donut y barras) |
| 7 | Metas / Perfil | `GoalsView.swift` | `Slider` ×2, `Toggle` |
| 8 | Perfil deportivo | `SportProfileView.swift` | grilla seleccionable |
| 9 | Aviso | `DisclaimerView.swift` | onboarding de 2 pasos |
| + | **Descripción y Créditos** | `CreditsView.swift` | `Toggle` de modo oscuro, confirmación |
| + | Login / Registro | `AuthViews.swift` | `TextField`, `SecureField` |

## Qué se completó respecto de Android

El proyecto Android tenía cuatro `TODO()` que impedían usar la app; esta migración los resuelve:

1. **Búsqueda real** de alimentos (`AgregarScreen`): `AddFoodViewModel` + `OpenFoodFactsRepository`.
2. **Búsqueda por código de barras** (`EscanerScreen`): `ScannerViewModel` + `/api/v2/product/{code}.json`.
3. **Informe semanal real** (`InformeScreen` usaba números de `PreviewData`): `ReportBuilder` agrega las
   entradas reales (promedio, mejor día, racha, barras, rango de semana).
4. **Persistencia real**: `FileStore` guarda `diary.json`, `goals.json`, `profile.json`, `settings.json`,
   `users.json` y `session.json` con escritura atómica.

Además se corrigieron dos bugs del original:

- **Doble redondeo**: la pantalla Confirmar mostraba 530 kcal y el diario guardaba 529. Ahora vista y
  guardado llaman al mismo `FoodProduct.nutrition(forUnits:)`.
- **Login que nunca enviaba**: `signIn()` usaba `guard let` sobre la validación, así que solo enviaba
  cuando el formulario era inválido.

## Mejoras extra (documentadas en el código)

- **Tolerancia a fallos de red**: si Open Food Facts falla o no hay internet, la búsqueda y el escáner caen
  al catálogo local y lo avisan en pantalla (`LocalCatalog`, banners de estado).
- **Debounce de 350 ms** en la búsqueda (`.task(id: query)` cancela la petición anterior), para no agotar
  el límite de Open Food Facts.
- **Modo oscuro real** con colores adaptativos `UIColor(dynamicProvider:)` y `preferredColorScheme`.
- **Háptica** en acciones clave (`Haptics`).
- **Onboarding de 2 pasos** (aviso legal → perfil deportivo) que reemplaza las rutas sueltas de Android.
- **Restaurar demo** desde Créditos, sin tocar metas ni cuentas.
- **Estados de carga / vacío / error** explícitos en todas las pantallas que esperan red.

## Prueba de humo de la lógica

Los archivos de dominio, persistencia y servicios (sin SwiftUI) pueden compilarse aparte con `swiftc`.
El script `main.swift` de la prueba es temporal y no forma parte del target; con él en el directorio actual:

```bash
cd Racion/Sources/Racion
swiftc -o /tmp/racion-smoke main.swift Models/*.swift Persistence/*.swift \
       Services/Formatters.swift Services/ReportBuilder.swift \
       Services/LocalCatalog.swift Services/AuthService.swift
/tmp/racion-smoke
```

Resultado:

```
ok   - SeedData siembra 13 entradas (hoy + 6 días)
ok   - 2 porciones de arepa = 419 kcal (redondeo único)
ok   - Kcal de hoy = 819
ok   - El informe tiene 7 días, etiquetas L..D, racha 7
ok   - El diario sobrevive a guardar/cargar
ok   - Login correcto y error de contraseña legible
TODO OK
```

## Limitaciones asumidas

- **Cámara**: no se usa AVFoundation. `Info.plist` no declara `NSCameraUsageDescription` y no hay cámara
  en el simulador. La pantalla de escaneo ofrece entrada manual y lectura simulada; conectar la cámara
  después es reemplazar `simulateScan()` por el delegado de captura, sin tocar el resto del flujo.
- **Firebase**: sustituido por almacenamiento local. `AuthService` usa FNV-1a con sal, **no** es seguro para
  producción (así está advertido en el archivo).
- **Instalación en iPhone físico**: requiere Apple ID y dispositivo; la verificación se hizo en el simulador.
- **Icono de la app**: `AppIcon.appiconset` está vacío, así que el simulador muestra el icono por defecto.

## Documentación

- [`docs/RUBRICA.md`](docs/RUBRICA.md): checklist punto por punto con el archivo que lo cumple.
- [`docs/REFLEXION.md`](docs/REFLEXION.md): reflexión (~250 palabras) sobre Compose/XML vs SwiftUI.
- [`docs/BUILD.md`](docs/BUILD.md): evidencia de compilación sin errores ni warnings y prueba de humo.
