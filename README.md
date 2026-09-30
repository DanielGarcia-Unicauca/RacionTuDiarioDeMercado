# 🥗 Ración — Tu Diario de Mercado

App Android (Kotlin + Jetpack Compose) para llevar el registro diario de tu alimentación: escaneá el código de barras de lo que compraste en el mercado, sumalo a tu diario, y seguí el balance entre lo que consumiste y tus metas.

## ✨ Funcionalidades

- **Inicio** · Resumen del día: calorías consumidas vs. meta, macros (carbohidratos, proteínas, grasas) y la lista de comidas del día.
- **Escáner** · Lector de código de barras con marco de escaneo y láser animado. Podés ingresar el código manualmente si la cámara no lee.
- **Manual** · Agregá alimentos a mano si no están etiquetados (entrada manual de código).
- **Confirmar** · Revisá y confirmá el alimento antes de sumarlo a tu diario.
- **Informe** · Resumen semanal: promedio diario de kcal, tu mejor día, racha activa, distribución de macros (donut) y calorías por día (barras).
- **Metas (Perfil)** · Definí y ajustá tus objetivos diarios de consumo.
- **Perfil deportivo** · Configurá tu perfil de deportista al dar de alta la app.
- **Aviso** · Pantalla de aviso/consentimiento al primer inicio (onboarding).

## 🛠️ Stack

- **Lenguaje:** Kotlin
- **UI:** Jetpack Compose + Material 3 (Material You)
- **Navegación:** Navigation Compose
- **Gradle:** Kotlin DSL con version catalog (`libs.versions.toml`)
- **minSdk:** 30 · **targetSdk / compileSdk:** 37

## 📦 Requisitos

- Android Studio (última versión estable) con SDK 37
- JDK 17+
- Gradle (wrapper incluido)

## 🚀 Cómo correrlo

1. Cloná el repo:

   ```bash
   git clone https://github.com/INOTJuannnka/RacionTuDiarioDeMercado.git
   ```

2. Abrí la carpeta en Android Studio.
3. Esperá que Gradle sincronice.
4. Corré la configuración `app` en un emulador o dispositivo con Android 11 (API 30) o superior.

## 🏗️ Estructura

El paquete de la app es `com.racion.diariomercado`. La capa de datos todavía no está conectada:
las pantallas se alimentan de `ui/preview/PreviewData` y corren completas sin backend.

```
app/src/main/java/com/racion/diariomercado/
├─ MainActivity.kt        # Activity + punto de entrada
├─ RacionApplication.kt   # Application:dueña del contenedor de dependencias
├─ core/                  # AppResult / AppError (taxonomía de fallos)
├─ di/                    # AppContainer: DI manual (sin Hilt)
├─ domain/
│  ├─ model/              # Nutrition, FoodProduct, DiaryEntry, DailySummary, WeeklyReport,
│  │                      #   NutritionGoals, UserProfile + enums (MealSlot, DayOfWeek, SportFocus)
│  └─ repository/         # Interfaces: FoodCatalog, Diary, Goals, Profile
├─ data/                  # Implementaciones (TODOs marcados)
│  ├─ openfood/           # Retrofit service, DTOs Moshi, repositorio del catálogo
│  │  └─ dto/
│  └─ firebase/           # Los tres repositorios de Firestore
└─ ui/
   ├─ components/         # AppComponents: MealRow, MacroStat, OptionPill, DarkStatCard, etc.
   ├─ navigation/         # AppNavigation y rutas
   ├─ preview/            # PreviewData: todos los datos fake centralizados
   ├─ screens/            # Pantallas: Inicio, Agregar, Escaner, Confirmar, Informe, Metas,
   │                      #   PerfilDeportivo, Aviso
   └─ theme/              # Color, Theme y Tipografía

docs/
├─ ROADMAP.md             # Checklist por fases (FF-N / OFF-N / BC-N / ST-N / Q-N)
└─ INTEGRATION.md         # Referencia verificada de Open Food Facts y Firestore
```

**Regla de dependencia:** `ui` → `domain` → nada. `data` implementa `domain` y conoce `domain`.
Ningún archivo de `domain/` importa Compose, Android ni `kotlinx`. Los repositorios son
`internal`: nadie fuera de `data/` sabe que existe Open Food Facts o Firestore.

## 🗺️ Estado del proyecto / Próximos pasos

La app es, hoy, **UI + tema + navegación funcionando sobre datos fake**. La capa de datos está
declarada como interfaces y esqueletos, pero los métodos son `TODO(...)`: no hay red ni
persistencia todavía. Es intencional — la prioridad era que el modelo de dominio y los seams
quedaran correctos antes de conectar un backend.

Para seguir:

1. **[`docs/ROADMAP.md`](docs/ROADMAP.md)** — el checklist ordenado por fases. Empezá por la
   Fase 2 (Firebase) o la Fase 3 (Open Food Facts); cada tarea tiene un ID (`FF-N`, `OFF-N`)
   que podés buscar con `grep` en los `TODO` del código.
2. **[`docs/INTEGRATION.md`](docs/INTEGRATION.md)** — la referencia externa verificada
   (endpoints de Open Food Facts, límites de tasa, nombres exactos de los campos `nutriments`,
   límites y trampas de Firestore). Está para que nadie tenga que volver a deducirla.

Lo primero que falla si se saltea, y conviene saber de antemano:

- **Open Food Facts bloquea requests sin `User-Agent` válido** (`AppName/Version (contact)`).
  Sin eso la API devuelve 403/503 y no hay resultados.
- **Un producto inexistente devuelve HTTP 200**, con `status: 0` y `product: null`. Hay que
  mirar el body, no solo el código HTTP.
- **La búsqueda de texto libre solo existe en el endpoint v1** (`cgi/search.pl`); la v2 no la
  soporta. Y está prohibido el search-as-you-type: el límite es de 10 requests/minuto.

Decisiones abiertas (Firestore vs Realtime Database, auth anónimo vs cuentas reales, Hilt o no,
cachear OFF) están en la sección **Decisions to make** del roadmap.

## 📄 Licencia

Código fuente: © 2025 INOTJuannnka. Todos los derechos reservados. Proyecto personal, sin
licencia abierta.

**Datos de terceros:** los datos de productos provienen de
[Open Food Facts](https://world.openfoodfacts.org) y están bajo
[ODbL](https://opendatacommons.org/licenses/odbl/1-0/); las imágenes de productos bajo CC-BY-SA.
Atribución a Open Food Facts obligatoria. Ver `docs/INTEGRATION.md`.

