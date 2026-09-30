package com.racion.diariomercado.domain.model

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Arithmetic contract for [Nutrition] and for the serving maths built on top of it.
 *
 * ## Why these numbers are hardcoded instead of imported
 * The fixture values below are copies of `ui.preview.PreviewData`. A test in the `domain`
 * package must NOT import from `ui.preview` — that would make the domain tests depend on a
 * screenshot fixture, so editing a demo number could break a test about calories. The literals
 * are duplicated on purpose: this file asserts the arithmetic, `PreviewData` asserts the
 * presentation, and the two are expected to be updated together. If a value here ever drifts
 * from `PreviewData`, `PreviewDataConsumedTotalsMatchTheDocumentedFold` is the test that should
 * be read.
 */
class NutritionTest {

    // ---------------------------------------------------------------------------------------
    // Fixtures (copies of ui.preview.PreviewData)
    // ---------------------------------------------------------------------------------------

    /** `PreviewData.featuredProduct`: 294 kcal/100 g, 90 g serving. */
    private val featuredProduct = FoodProduct(
        barcode = "LOCAL-AREPAQUESO",
        name = "Arepa de choclo con queso",
        servingGrams = 90.0,
        nutritionPer100g = Nutrition(
            kcal = 294,
            carbsG = 31.0,
            proteinG = 10.0,
            fatG = 12.0
        )
    )

    private val arepaChoclo = FoodProduct(
        barcode = "LOCAL-AREPACHOCLO",
        name = "Arepa de choclo",
        servingGrams = 90.0,
        nutritionPer100g = Nutrition(kcal = 233, carbsG = 33.0, proteinG = 10.0, fatG = 12.0)
    )

    private val sancocho = FoodProduct(
        barcode = "LOCAL-SANCOCHOGALLINA",
        name = "Sancocho de gallina",
        servingGrams = 400.0,
        nutritionPer100g = Nutrition(kcal = 120, carbsG = 12.0, proteinG = 12.0, fatG = 3.0)
    )

    private val jugoMango = FoodProduct(
        barcode = "LOCAL-JUGOMANGOBICHE",
        name = "Jugo de mango biche",
        servingGrams = 330.0,
        nutritionPer100g = Nutrition(kcal = 39, carbsG = 9.0, proteinG = 0.4, fatG = 0.1, sugarsG = 8.5)
    )

    /** A product with all seven fields populated, so no scaling assertion can be a no-op. */
    private val fullNutrition = Nutrition(
        kcal = 100,
        carbsG = 10.0,
        proteinG = 5.0,
        fatG = 2.0,
        sugarsG = 4.0,
        fiberG = 3.0,
        sodiumG = 0.5
    )

    // ---------------------------------------------------------------------------------------
    // scaled
    // ---------------------------------------------------------------------------------------

    @Test
    fun scaledMultipliesAllSevenFields() {
        val scaled = fullNutrition.scaled(2.0)

        assertEquals(200, scaled.kcal)
        assertEquals(20.0, scaled.carbsG, 0.0)
        assertEquals(10.0, scaled.proteinG, 0.0)
        assertEquals(4.0, scaled.fatG, 0.0)
        assertEquals(8.0, scaled.sugarsG, 0.0)
        assertEquals(6.0, scaled.fiberG, 0.0)
        assertEquals(1.0, scaled.sodiumG, 0.0)
    }

    @Test
    fun scaledKeepsMacroPrecisionAndRoundsKcalHalfUp() {
        val scaled = fullNutrition.scaled(0.9)

        // Macros stay fractional: the UI rounds them for display, the model does not.
        assertEquals(9.0, scaled.carbsG, 0.0)
        assertEquals(4.5, scaled.proteinG, 0.0)
        assertEquals(1.8, scaled.fatG, 1e-9)
        assertEquals(3.6, scaled.sugarsG, 1e-9)
        assertEquals(2.7, scaled.fiberG, 1e-9)
        assertEquals(0.45, scaled.sodiumG, 1e-9)
        // 100 * 0.9 = 90 exactly.
        assertEquals(90, scaled.kcal)
    }

    @Test
    fun scaledRoundsKcalHalfUpNotTruncate() {
        // 5 * 0.5 = 2.5 -> 3 with Math.round, 2 if the implementation truncated.
        assertEquals(3, Nutrition(kcal = 5).scaled(0.5).kcal)
        // 7 * 0.5 = 3.5 -> 4.
        assertEquals(4, Nutrition(kcal = 7).scaled(0.5).kcal)
    }

    @Test
    fun scaledByOneReturnsTheSameInstance() {
        assertEquals(fullNutrition, fullNutrition.scaled(1.0))
    }

    // ---------------------------------------------------------------------------------------
    // plus
    // ---------------------------------------------------------------------------------------

    @Test
    fun plusSumsAllSevenFields() {
        val other = Nutrition(
            kcal = 50,
            carbsG = 1.0,
            proteinG = 2.0,
            fatG = 0.5,
            sugarsG = 6.0,
            fiberG = 7.0,
            sodiumG = 0.25
        )

        val sum = fullNutrition + other

        assertEquals(150, sum.kcal)
        assertEquals(11.0, sum.carbsG, 0.0)
        assertEquals(7.0, sum.proteinG, 0.0)
        assertEquals(2.5, sum.fatG, 1e-9)
        assertEquals(10.0, sum.sugarsG, 0.0)
        assertEquals(10.0, sum.fiberG, 0.0)
        assertEquals(0.75, sum.sodiumG, 1e-9)
    }

    @Test
    fun plusAgainstTheDefaultValueIsIdentity() {
        assertEquals(fullNutrition, fullNutrition + Nutrition())
    }

    @Test
    fun plusIsCommutative() {
        val other = Nutrition(
            kcal = 7,
            carbsG = 1.5,
            proteinG = 2.5,
            fatG = 0.25,
            sugarsG = 1.0,
            fiberG = 1.0,
            sodiumG = 0.75
        )

        assertEquals(fullNutrition + other, other + fullNutrition)
    }

    // ---------------------------------------------------------------------------------------
    // nutritionFor / nutritionForUnits (the double-rounding bug)
    // ---------------------------------------------------------------------------------------

    @Test
    fun nutritionForUnitsMatchesNutritionForOnTheUnroundedServing() {
        // The regression: ConfirmarScreen previewed `nutritionFor(90).scaled(2.0)` = 530 kcal
        // while AppNavigation stored `nutritionFor(90 * 2)` = 529 kcal. One canonical method,
        // one number.
        assertEquals(
            featuredProduct.nutritionFor(90.0 * 2),
            featuredProduct.nutritionForUnits(2)
        )
        assertEquals(529, featuredProduct.nutritionForUnits(2).kcal)
    }

    @Test
    fun nutritionForUnitsRoundsExactlyOnceAtEveryUnitCount() {
        // These are the values that used to disagree between the preview and the stored entry.
        assertEquals(265, featuredProduct.nutritionForUnits(1).kcal)
        assertEquals(529, featuredProduct.nutritionForUnits(2).kcal)
        assertEquals(1323, featuredProduct.nutritionForUnits(5).kcal)
    }

    @Test
    fun nutritionForUnitsKeepsFractionalMacrosAtTwoUnits() {
        val twoUnits = featuredProduct.nutritionForUnits(2)

        assertEquals(31.0 * 1.8, twoUnits.carbsG, 1e-9)
        assertEquals(10.0 * 1.8, twoUnits.proteinG, 1e-9)
        assertEquals(12.0 * 1.8, twoUnits.fatG, 1e-9)
    }

    @Test
    fun nutritionForUnitsFallsBackToTheDefaultServingWhenNoneIsDeclared() {
        val noServing = featuredProduct.copy(servingGrams = null)

        assertEquals(100.0, FoodProduct.DEFAULT_SERVING_GRAMS, 0.0)
        assertEquals(noServing.nutritionFor(100.0 * 2), noServing.nutritionForUnits(2))
        assertEquals(588, noServing.nutritionForUnits(2).kcal)
    }

    @Test
    fun nutritionForAlwaysReturnsAValueAndNeverNull() {
        // The KDoc used to promise a nullable return for a non-null type. Guard the real
        // contract: no serving size declared, still a usable Nutrition.
        val noServing = featuredProduct.copy(servingGrams = null)
        val result = noServing.nutritionFor(FoodProduct.DEFAULT_SERVING_GRAMS)

        assertEquals(294, result.kcal)
    }

    // ---------------------------------------------------------------------------------------
    // PreviewData fixtures
    // ---------------------------------------------------------------------------------------

    @Test
    fun previewMealsProduceTheirDocumentedKcalAtOneServing() {
        assertEquals(210, arepaChoclo.nutritionForUnits(1).kcal)
        assertEquals(480, sancocho.nutritionForUnits(1).kcal)
        assertEquals(129, jugoMango.nutritionForUnits(1).kcal)
    }

    @Test
    fun previewConsumedTotalsMatchTheDocumentedFold() {
        // Mirrors PreviewData.consumed: the three meals folded with the same `plus` operator.
        val arepaEntry = arepaChoclo.nutritionFor(90.0)
        val sancochoEntry = sancocho.nutritionFor(400.0)
        val jugoEntry = jugoMango.nutritionFor(330.0)

        val consumed = listOf(arepaEntry, sancochoEntry, jugoEntry)
            .fold(Nutrition()) { acc, entry -> acc + entry }

        assertEquals(819, consumed.kcal)
        assertEquals(33.0 * 0.9 + 12.0 * 4.0 + 9.0 * 3.3, consumed.carbsG, 1e-9)
        assertEquals(10.0 * 0.9 + 12.0 * 4.0 + 0.4 * 3.3, consumed.proteinG, 1e-9)
        assertEquals(12.0 * 0.9 + 3.0 * 4.0 + 0.1 * 3.3, consumed.fatG, 1e-9)
        // Only jugoMango declares sugars (8.5/100 g over a 330 g glass). fiberG and sodiumG are
        // unset on all three meals and must sum to exactly zero rather than pick up a default.
        assertEquals(8.5 * 3.3, consumed.sugarsG, 1e-9)
        assertEquals(0.0, consumed.fiberG, 0.0)
        assertEquals(0.0, consumed.sodiumG, 0.0)
    }
}
