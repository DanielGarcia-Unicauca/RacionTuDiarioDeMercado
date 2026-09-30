package com.racion.diariomercado.domain.model

/**
 * Immutable nutrition value object.
 *
 * All macro values are expressed in **grams** and [kcal] in kilocalories. This type is the
 * single source of truth for every arithmetic operation on nutrition data, so it lives in
 * the domain layer and depends on nothing (no Android, no Compose, no kotlinx).
 *
 * Design notes:
 * - It is a [data class] with `Double` macro fields and an `Int` energy field, so equality
 *   and `copy` work out of the box and every mutation produces a new instance.
 * - Every field defaults to `0`, which makes `Nutrition()` a safe "nothing consumed yet"
 *   value and lets callers omit fields they do not have data for.
 */
data class Nutrition(
    val kcal: Int = 0,
    val carbsG: Double = 0.0,
    val proteinG: Double = 0.0,
    val fatG: Double = 0.0,
    val sugarsG: Double = 0.0,
    val fiberG: Double = 0.0,
    val sodiumG: Double = 0.0
) {
    /**
     * Returns a copy where every value is multiplied by [factor].
     *
     * Used to project per-100 g data onto an arbitrary serving size (`factor = 1.5`) or onto
     * a number of servings (`factor = 2.0`).
     *
     * Energy is scaled and rounded to the nearest integer because calories are a count, not a
     * measurement: `265.4 kcal` is meaningless in a UI. Rounding is HALF_UP so the sum of the
     * rounded parts of a day is not systematically biased downwards.
     */
    fun scaled(factor: Double): Nutrition {
        if (factor == 1.0) return this
        return Nutrition(
            kcal = Math.round(kcal * factor).toInt(),
            carbsG = carbsG * factor,
            proteinG = proteinG * factor,
            fatG = fatG * factor,
            sugarsG = sugarsG * factor,
            fiberG = fiberG * factor,
            sodiumG = sodiumG * factor
        )
    }

    /**
     * Component-wise sum. This is the operator the daily running total is built with:
     * `today = today + entry.totalNutrition`.
     */
    operator fun plus(other: Nutrition): Nutrition = Nutrition(
        kcal = kcal + other.kcal,
        carbsG = carbsG + other.carbsG,
        proteinG = proteinG + other.proteinG,
        fatG = fatG + other.fatG,
        sugarsG = sugarsG + other.sugarsG,
        fiberG = fiberG + other.fiberG,
        sodiumG = sodiumG + other.sodiumG
    )
}
