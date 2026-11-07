# Evidencia de compilación y pruebas

Todo lo siguiente se ejecutó en macOS con **Xcode 26.2** (SDK de iOS 26.2, deployment target **iOS 17.0**)
y el simulador **iPhone 16 Pro – iOS 18.6**, sin Apple ID ni cuenta de desarrollador.

## Compilación limpia

```bash
cd /Users/MAC16/Downloads/RacionTuDiarioDeMercado-Xcode
xcodebuild -project Racion.xcodeproj -scheme Racion \
           -sdk iphonesimulator -configuration Debug \
           -destination 'generic/platform=iOS Simulator' \
           CODE_SIGNING_ALLOWED=NO clean build
```

Salida:

```
...
** BUILD SUCCEEDED **
```

- `exit=0`
- **0 errores**. El único aviso es el benigno de metadatos de AppIntents (`Metadata extraction skipped. No
  AppIntents.framework dependency found.`), que no afecta a la app.
- `Info.plist` generado con `CFBundleIdentifier = com.equipo.racion`, `MinimumOSVersion = 17.0`,
  `CFBundleShortVersionString = 1.0`, `CFBundleDisplayName = Ración` y `UILaunchScreen` presente.

## Correcciones necesarias para que el proyecto compilara

El `.xcodeproj` heredado del entorno `xtool` no abría correctamente en Xcode. Se corrigieron tres cosas:

1. **Rutas de los fuentes**: todas las referencias apuntaban a `Sources/Racion/…` cuando los archivos están
   en `Racion/Sources/Racion/…`. Se reescribieron las 41 rutas del `project.pbxproj`.
2. **Identificadores inválidos**: dos IDs de objeto contenían `G`/`H`, que no son dígitos hexadecimales
   válidos (`AA00000000000000000000G0` y `…H0`); se sustituyeron por `…E1` y `…F1`.
3. **Deployment target**: se subió de iOS 16.0 a **iOS 17.0**, porque el código usa APIs de iOS 17
   (`onChange(of:initial:_:)`).

Además se añadió un **esquema compartido** en
`Racion.xcodeproj/xcshareddata/xcschemes/Racion.xcscheme`, para que `-scheme Racion` funcione en cualquier
copia del repositorio.

## Prueba en el simulador

La app se instaló y se recorrió de extremo a extremo en el simulador (UDID `12AFDBB3-2AAF-4C9B-9390-56C7B26EACE7`):

```bash
xcrun simctl install booted .../Build/Products/Debug-iphonesimulator/Racion.app
xcrun simctl launch booted com.equipo.racion
```

Comprobado visualmente (capturas + OCR) y por los archivos persistidos en el contenedor de la app:

- Onboarding (aviso legal → perfil deportivo) y pantalla de Inicio con kcal, macros y comidas.
- Diario: alta de alimento, `Stepper` de porciones y totales actualizados (1.049 kcal / 4 porciones).
- Redondeo único: 3 unidades del producto destacado = 794 kcal, idéntico en Confirmar y en el Diario.
- Escáner (lectura simulada) → Confirmar.
- Informe semanal: promedio 727, mejor día, racha 7 y rango `26 OCT–1 NOV`.
- Metas, perfil deportivo y Créditos (incluido el `Toggle` de modo oscuro).
- Registro, cierre de sesión y login con `demo@racion.co` / `secreto123`.
- Persistencia en `Application Support`: `diary.json`, `goals.json`, `profile.json`, `settings.json`,
  `users.json` y `session.json`. Tras relanzar se conservan el diario (1.049 kcal), el onboarding, la
  sesión y el modo oscuro.

## Prueba de humo de la lógica (sin SwiftUI)

Los módulos de dominio, persistencia y servicios se pueden compilar aparte con `swiftc` y ejecutar 19
comprobaciones. El `main.swift` de la prueba es temporal y no forma parte del target de la app:

```bash
cd Racion/Sources/Racion
swiftc -o /tmp/racion-smoke main.swift Models/*.swift Persistence/*.swift \
       Services/Formatters.swift Services/ReportBuilder.swift \
       Services/LocalCatalog.swift Services/AuthService.swift
/tmp/racion-smoke
```

```
ok   - SeedData siembra 13 entradas (hoy + 6 días)
ok   - Todas las entradas tienen kcal > 0
ok   - Las entradas vienen ordenadas
ok   - 2 porciones de arepa = 419 kcal (redondeo único: 233*1.8=419.4)
ok   - 1 porción de arepa = 210 kcal (233*0.9=209.7)
ok   - Hoy hay 3 comidas sembradas
ok   - Kcal de hoy = 819 (210 + 480 + 129)
ok   - El informe tiene 7 días
ok   - Etiquetas ISO L..D
ok   - Promedio diario > 0
ok   - Hay mejor día
ok   - Racha activa >= 1, obtenido: 7
ok   - Se resalta exactamente un día
ok   - Rango de semana con guion: 26 OCT–1 NOV
ok   - El diario sobrevive a guardar/cargar
ok   - El primer producto se conserva
ok   - El correo se normaliza a minúsculas
ok   - Login con la contraseña correcta
ok   - El error de contraseña es legible
TODO OK
```

## Qué no se pudo probar

- **Cámara**: `Info.plist` no declara `NSCameraUsageDescription` y el simulador no tiene cámara; el escáner
  usa entrada manual y lectura simulada (ver `ScannerView.swift`).
- **Red real**: la capa de red (`OpenFoodFactsService`) compila y tiene fallback al catálogo local, pero no se
  ejecutó contra Open Food Facts de forma automatizada; se validó por revisión de código y por el
  comportamiento de fallback en la app.
- **iPhone físico**: requiere Apple ID y dispositivo conectado; la verificación se hizo en el simulador.
