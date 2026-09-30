package com.racion.diariomercado.domain.model

/**
 * The user's targets, editable from the "Metas" screen.
 *
 * The slider bounds live in the companion object rather than at the call site so the UI
 * cannot drift away from what the domain considers a valid range.
 */
data class NutritionGoals(
    val targetWeightKg: Float = 63f,
    val currentWeightKg: Float = 68f,
    val kcalPerDay: Int = 1900,
    /** ISO weekdays the user trains on. Drives the weekly active-day row. */
    val activeDays: Set<DayOfWeek> = DayOfWeek.entries.toSet(),
    val macroSplit: MacroSplit = MacroSplit(45, 25, 30)
) {
    companion object {
        /** Slider bounds for target weight, in kilograms. */
        val WEIGHT_RANGE_KG = 55f..80f

        /** Slider bounds for the daily energy goal, in kcal. */
        val KCAL_RANGE = 1400..2600
    }
}

/**
 * ISO weekdays with their single-letter Spanish labels.
 *
 * WARNING — name clash: this [DayOfWeek] deliberately shadows `java.time.DayOfWeek` and
 * `DayOfWeek.MONDAY` in this package is NOT the JDK one. That is intentional: the UI shows
 * one-letter Spanish labels and needs a domain type that carries them, while the persistence
 * layer needs the JDK's ordering/`LocalDate` conversion. Keep the two apart:
 * - In `domain/`, import this type by default.
 * - Anywhere that also needs the JDK type, use an import alias
 *   (`import java.time.DayOfWeek as JavaDayOfWeek`) rather than re-declaring the name.
 *
 * [short] labels follow the Spanish convention used in the existing design: Lunes, Martes,
 * Miércoles, Jueves, Viernes, Sábado, Domingo -> L, M, X, J, V, S, D.
 */
enum class DayOfWeek(val short: String) {
    MONDAY("L"),
    TUESDAY("M"),
    WEDNESDAY("X"),
    THURSDAY("J"),
    FRIDAY("V"),
    SATURDAY("S"),
    SUNDAY("D")
}
