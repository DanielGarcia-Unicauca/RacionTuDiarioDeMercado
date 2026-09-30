package com.racion.diariomercado.ui.preview

import com.racion.diariomercado.domain.model.DailySummary
import com.racion.diariomercado.domain.model.DayOfWeek
import com.racion.diariomercado.domain.model.DayTotal
import com.racion.diariomercado.domain.model.DiaryEntry
import com.racion.diariomercado.domain.model.FoodProduct
import com.racion.diariomercado.domain.model.MacroSplit
import com.racion.diariomercado.domain.model.MealSlot
import com.racion.diariomercado.domain.model.Nutrition
import com.racion.diariomercado.domain.model.NutritionGoals
import com.racion.diariomercado.domain.model.SportFocus
import com.racion.diariomercado.domain.model.UserProfile
import com.racion.diariomercado.domain.model.WeeklyReport
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/**
 * Every piece of fake data the app renders, in one place.
 *
 * This exists so the whole UI can be developed, reviewed and screenshotted with **zero backend**:
 * `AppNavigation` feeds these values into the screens, so the app is fully interactive (add a
 * meal, change the stepper, edit goals) before a single repository is implemented.
 *
 * ## Why this file matters more than it looks
 * Before this existed, each screen carried its own `defaultMeals()`, `defaultResults()`,
 * `defaultDays()`, `defaultFocuses()` private fixture, plus hardcoded numbers in the *parameter
 * defaults* of the same function. That produced two failure modes:
 * - **Drift.** `InicioScreen` showed `kcalConsumed = 1340` next to a meal list summing to 820.
 *   Two sources of truth for one fact, one of them always wrong.
 * - **Duplication.** Tapping "Bandeja paisa" in Agregar and confirming it rendered a different
 *   product than the row, because both were literals.
 *
 * Everything below is therefore *derived* from the same product list, so the numbers cannot
 * disagree with each other any more.
 *
 * ## About the synthetic barcodes
 * Several fixtures are regional Colombian dishes (sancocho, patacón) that Open Food Facts does
 * not carry. They get obviously-fake `LOCAL-*` barcodes so the type stays honest. Real scans
 * produce real EAN-13 codes; a `LOCAL-` prefix is the marker for "not from the catalog".
 *
 * ## Timezone note
 * [loggedAtEpochMillis] is derived from a fixed local date/time via [ZoneId.systemDefault], so
 * the "7:20 AM" style labels the screens render shift with the device timezone. That is
 * correct behaviour for real data and acceptable for a fixture; the dates never change.
 *
 * ## The one deliberate exception to "frozen"
 * Almost every timestamp here is derived from [demoDate] and is therefore frozen, which is what
 * keeps screenshots stable. [recentScans] is the exception: it is anchored to [Instant.now]
 * because "Escaner" renders a *relative* label from it, and a frozen date decays into
 * "Hace 1 mes" under a header that claims "ESCANEADO RECIENTEMENTE". See that property for the
 * full trade-off.
 */
internal object PreviewData {

    // ---------------------------------------------------------------------------------------
    // Products
    // ---------------------------------------------------------------------------------------

    private val arepaChoclo = FoodProduct(
        barcode = "LOCAL-AREPACHOCLO",
        name = "Arepa de choclo",
        brand = "Típico · Región andina",
        quantityLabel = "1 unidad (90 g)",
        servingGrams = 90.0,
        nutritionPer100g = Nutrition(
            kcal = 233,
            carbsG = 33.0,
            proteinG = 10.0,
            fatG = 12.0
        ),
        categories = listOf("Almuerzo", "Bebidas"),
        emoji = "\uD83E\uDD5D"
    )

    private val empanada = FoodProduct(
        barcode = "LOCAL-EMPANADACARNE",
        name = "Empanada de carne",
        brand = "Típico · Tolima",
        quantityLabel = "1 unidad (120 g)",
        servingGrams = 120.0,
        nutritionPer100g = Nutrition(
            kcal = 192,
            carbsG = 22.0,
            proteinG = 9.0,
            fatG = 9.0
        ),
        categories = listOf("Frituras"),
        emoji = "\uD83E\uDD5F"
    )

    private val bandejaPaisa = FoodProduct(
        barcode = "LOCAL-BANDEJAPAISA",
        name = "Bandeja paisa",
        brand = "Típico · Antioquia",
        quantityLabel = "1 porción (450 g)",
        servingGrams = 450.0,
        nutritionPer100g = Nutrition(
            kcal = 191,
            carbsG = 16.0,
            proteinG = 12.0,
            fatG = 12.0
        ),
        categories = listOf("Almuerzo"),
        emoji = "\uD83C\uDF5B"
    )

    private val patacon = FoodProduct(
        barcode = "LOCAL-PATACONHOGAO",
        name = "Patacón con hogao",
        brand = "Típico · Pacífico",
        quantityLabel = "1 porción (220 g)",
        servingGrams = 220.0,
        nutritionPer100g = Nutrition(
            kcal = 141,
            carbsG = 21.0,
            proteinG = 3.0,
            fatG = 5.0
        ),
        categories = listOf("Frituras"),
        emoji = "\uD83C\uDF60"
    )

    private val avena = FoodProduct(
        barcode = "7801234567890",
        name = "Avena Alpina 200ml",
        brand = "Alpina",
        quantityLabel = "200 ml",
        servingGrams = 200.0,
        nutritionPer100g = Nutrition(
            kcal = 70,
            carbsG = 10.0,
            proteinG = 2.5,
            fatG = 1.8,
            sugarsG = 8.0,
            fiberG = 0.8,
            sodiumG = 0.06
        ),
        nutriscoreGrade = "c",
        categories = listOf("Bebidas", "Lácteos"),
        emoji = "\uD83C\uDF5E"
    )

    /** The product the "Confirmar" screen renders. Rich enough to exercise every field. */
    val featuredProduct: FoodProduct = FoodProduct(
        barcode = "LOCAL-AREPAQUESO",
        name = "Arepa de choclo con queso",
        brand = "Típico · Región andina",
        quantityLabel = "1 unidad (90 g)",
        servingGrams = 90.0,
        nutritionPer100g = Nutrition(
            kcal = 294,
            carbsG = 31.0,
            proteinG = 10.0,
            fatG = 12.0
        ),
        ingredientsText = "Masa de maíz tierno asada, rellena con queso campesino.",
        nutriscoreGrade = "d",
        categories = listOf("Almuerzo", "Bebidas"),
        emoji = "\uD83E\uDD5D"
    )

    /** Results list for the "Agregar" screen. */
    val searchResults: List<FoodProduct> = listOf(arepaChoclo, empanada, bandejaPaisa, patacon)

    /** Category tabs for the "Agregar" screen. */
    val categories: List<String> = listOf("Almuerzo", "Frituras", "Sopas", "Bebidas")

    // ---------------------------------------------------------------------------------------
    // Diary
    // ---------------------------------------------------------------------------------------

    /**
     * The frozen "today" every diary fixture hangs off.
     *
     * Wednesday 26 Aug 2026, chosen on purpose: it is the middle of the Monday-start week
     * 24–30 Aug that [weeklyReport] labels, so the day-of-week shown in [todaySummary.dateLabel]
     * ("Mié") and the week range rendered on "Informe" describe the same week. The previous value
     * was Tuesday 25 Aug while claiming to be Wednesday, and the week label said 19–25 Aug for a
     * range that did not start on a Monday — two dates that each contradicted the other.
     */
    private val demoDate: LocalDate = LocalDate.of(2026, 8, 26)

    private fun at(hour: Int, minute: Int): Long =
        demoDate.atTime(hour, minute).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()

    private val sancocho = FoodProduct(
        barcode = "LOCAL-SANCOCHOGALLINA",
        name = "Sancocho de gallina",
        brand = "Típico · Región andina",
        quantityLabel = "1 plato (400 g)",
        servingGrams = 400.0,
        nutritionPer100g = Nutrition(kcal = 120, carbsG = 12.0, proteinG = 12.0, fatG = 3.0),
        categories = listOf("Sopas"),
        emoji = "\uD83C\uDF72"
    )

    private val jugoMango = FoodProduct(
        barcode = "LOCAL-JUGOMANGOBICHE",
        name = "Jugo de mango biche",
        brand = "Típico · Región andina",
        quantityLabel = "1 vaso (330 ml)",
        servingGrams = 330.0,
        nutritionPer100g = Nutrition(kcal = 39, carbsG = 9.0, proteinG = 0.4, fatG = 0.1, sugarsG = 8.5),
        categories = listOf("Bebidas"),
        emoji = "\uD83E\uDD6D"
    )

    /** The three meals the "Inicio" screen lists. */
    val meals: List<DiaryEntry> = listOf(
        DiaryEntry(
            id = "entry-arepa",
            product = arepaChoclo,
            servings = 1,
            mealSlot = MealSlot.DESAYUNO,
            loggedAtEpochMillis = at(7, 20),
            totalNutrition = arepaChoclo.nutritionFor(90.0)
        ),
        DiaryEntry(
            id = "entry-sancocho",
            product = sancocho,
            servings = 1,
            mealSlot = MealSlot.ALMUERZO,
            loggedAtEpochMillis = at(12, 45),
            totalNutrition = sancocho.nutritionFor(400.0)
        ),
        DiaryEntry(
            id = "entry-jugo",
            product = jugoMango,
            servings = 1,
            mealSlot = MealSlot.SNACK,
            loggedAtEpochMillis = at(15, 10),
            totalNutrition = jugoMango.nutritionFor(330.0)
        )
    )

    /**
     * Derived from [meals] with the same `plus` operator the real repository uses, so the
     * header can never contradict the list. (The previous hardcoded header said 1340 kcal
     * while its own three rows summed to 820.)
     */
    val consumed: Nutrition = meals.fold(Nutrition()) { acc, entry -> acc + entry.totalNutrition }

    val todaySummary: DailySummary = DailySummary(
        dateLabel = "Mié 26 Ago",
        consumed = consumed,
        goalKcal = NutritionGoals().kcalPerDay,
        entries = meals
    )

    /**
     * Scan history for the "Escanear" sheet.
     *
     * This is the ONE fixture in this file deliberately **not** pinned to [demoDate].
     * `EscanerScreen` renders each row with a relative label computed from the real timestamp
     * ("Hoy" / "Ayer" / "Hace 3 días" / "Hace 1 mes"), so a fixed calendar date silently rots:
     * a scan dated `demoDate - 2 days` read as "Hace 2 días" the day the fixture was written and
     * reads as "Hace 1 mes" a month later, directly under a header that says
     * "ESCANEADO RECIENTEMENTE". Anchoring to [Instant.now] makes the fixture age with real
     * time, so the label it renders is always true.
     *
     * The trade-off is the opposite of [demoDate]: the diary entries are frozen for screenshot
     * stability, while this row trades stability for truthfulness. Nothing else reads these
     * timestamps, so there is no drift to reconcile.
     */
    val recentScans: List<DiaryEntry> = listOf(
        DiaryEntry(
            id = "entry-avena",
            product = avena,
            servings = 1,
            mealSlot = MealSlot.DESAYUNO,
            loggedAtEpochMillis = Instant.now().minus(2, ChronoUnit.DAYS).toEpochMilli(),
            totalNutrition = avena.nutritionFor(200.0)
        )
    )

    // ---------------------------------------------------------------------------------------
    // Report
    // ---------------------------------------------------------------------------------------

    val weekDays: List<DayTotal> = listOf(
        DayTotal("L", 1500),
        DayTotal("M", 1600),
        DayTotal("X", 1550),
        DayTotal("J", 1700),
        DayTotal("V", 1900, isHighlighted = true),
        DayTotal("S", 1650),
        DayTotal("D", 1480)
    )

    // ---------------------------------------------------------------------------------------
    // The two fields below are NOT derived from any data. Do not "fix" them by deriving them.
    // ---------------------------------------------------------------------------------------
    //
    // `weeklyReport.macroSplit` (45/30/25) and `weeklyReport.activeStreakDays` (5) are bare
    // literals that exist only so the donut and the streak widget have something to render.
    // `weekDays` carries per-day *calories* and nothing else — there is no macro data per day
    // and no history to count a streak from — so neither value could be computed even in
    // principle from anything in this file.
    //
    // They are also allowed to disagree with the rest of the file: `macroSplit` here is
    // (45, 30, 25) while `goals.macroSplit` below is (45, 25, 30), because one is a past-week
    // report and the other is a forward-looking target. That is a defensible reading, but it is
    // a reading, not a derivation.
    //
    // A real `DiaryRepository.observeWeek` must compute both. Until it does, these two fields are
    // the only numbers on the "Informe" screen that no computation in the codebase can contradict
    // — everything else on that screen is derived from [weekDays].

    val weeklyReport: WeeklyReport = WeeklyReport(
        // Monday-start week containing demoDate: Mon 24 Aug -> Sun 30 Aug. This matches the
        // "L M X J V S D" order of [weekDays] and the "Mié 26 Ago" header on "Inicio".
        weekRangeLabel = "24–30 AGO",
        averageKcalPerDay = weekDays.map { it.kcal }.average().toInt(),
        bestDayLabel = weekDays.maxByOrNull { it.kcal }?.label,
        // NOT derived from [weekDays] or from anything else — see the block comment below.
        activeStreakDays = 5,
        // NOT derived from [weekDays] or from anything else — see the block comment below.
        macroSplit = MacroSplit(45, 30, 25),
        days = weekDays,
        goalKcal = NutritionGoals().kcalPerDay
    )

    // ---------------------------------------------------------------------------------------
    // Goals and profile
    // ---------------------------------------------------------------------------------------

    val goals: NutritionGoals = NutritionGoals(
        targetWeightKg = 63f,
        currentWeightKg = 68f,
        kcalPerDay = 1900,
        // Set EXPLICITLY, and deliberately not the `NutritionGoals()` default of
        // `DayOfWeek.entries.toSet()`. Omitting it lit all seven chips; the "Metas" screen has
        // defaulted to Monday–Friday since before the parameter refactor, so the five-day
        // selection below is the pre-refactor default preserved on purpose, and dropping the
        // argument would be a silent behaviour change rather than a cleanup.
        activeDays = setOf(
            DayOfWeek.MONDAY,
            DayOfWeek.TUESDAY,
            DayOfWeek.WEDNESDAY,
            DayOfWeek.THURSDAY,
            DayOfWeek.FRIDAY
        ),
        macroSplit = MacroSplit(45, 25, 30)
    )

    val profile: UserProfile = UserProfile(
        userId = "preview-user",
        displayName = "Hola!",
        sportFocus = SportFocus.RUNNING,
        currentWeightKg = 68f
    )
}
