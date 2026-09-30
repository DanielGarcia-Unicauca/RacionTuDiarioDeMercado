package com.racion.diariomercado.domain.model

/**
 * One logged food event: "I ate N servings of this product, at this meal slot, at this time".
 *
 * This is the unit of write in the diary. [totalNutrition] is stored denormalised on the entry
 * on purpose — see `FirestoreDiaryRepository` for why the daily aggregate is precomputed rather
 * than summed at read time.
 */
data class DiaryEntry(
    /** Stable id, generated client-side. Survives reinstalls only if it is not random. */
    val id: String,
    val product: FoodProduct,
    /** How many units of [product] were consumed. Always `>= 1`. */
    val servings: Int,
    val mealSlot: MealSlot,
    val loggedAtEpochMillis: Long,
    /** Nutrition for `servings` units, precomputed. `nutritionPer100g.scaled(...)` in practice. */
    val totalNutrition: Nutrition
)

/**
 * Which meal of the day an entry belongs to.
 *
 * [label] is Spanish on purpose: it is shown verbatim in the diary row meta line
 * ("ALMUERZO · 12:45 PM") and the app's UI language is Spanish. Storage/persistence code must
 * key off [name], never off [label].
 */
enum class MealSlot(val label: String) {
    DESAYUNO("Desayuno"),
    ALMUERZO("Almuerzo"),
    SNACK("Snack"),
    CENA("Cena")
}
