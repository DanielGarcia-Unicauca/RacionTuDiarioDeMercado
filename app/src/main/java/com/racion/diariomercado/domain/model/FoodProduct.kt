package com.racion.diariomercado.domain.model

/**
 * A food product as the app understands it, independent of where it came from.
 *
 * Right now the only production source is Open Food Facts, but this type deliberately
 * carries no trace of it: no `code`-vs-`barcode` ambiguity, no stringly-typed Nutriscore,
 * no null-heavy nutriments wrapper. The mapping DTO -> this type is the job of
 * `OpenFoodFactsCatalogRepository`.
 *
 * Nutrition is always stored **per 100 g** ([nutritionPer100g]) so that servings of any size
 * can be derived with [Nutrition.scaled]. That is the only normalisation that survives
 * products whose serving is "1 unit", "1 slice", "250 ml" or unstated.
 *
 * Note on [emoji]: the emoji is a genuine content concern (it is the visual stand-in for the
 * product photo inside a meal row), not a theme concern, so it lives on the model. The
 * `iconBg: Color?` that used to sit next to it in the screens did not — that is UI-only and
 * was removed.
 */
data class FoodProduct(
    /** EAN-13 / UPC-A barcode. Stable identity for a packaged product. */
    val barcode: String,
    val name: String,
    val brand: String? = null,
    /** Human readable size as printed on the pack, e.g. "500 g" or "1 L". */
    val quantityLabel: String? = null,
    /** Grams in one "unit"/serving when the producer declares it. `null` if not declared. */
    val servingGrams: Double? = null,
    val nutritionPer100g: Nutrition,
    val imageUrl: String? = null,
    /** "a".."e", normalised to lower case, or `null` when the product is ungraded. */
    val nutriscoreGrade: String? = null,
    /** Open Food Facts returns this as one comma-separated string; it is split here. */
    val categories: List<String> = emptyList(),
    val ingredientsText: String? = null,
    /** Visual stand-in for [imageUrl]. Defaults to a generic plate. */
    val emoji: String = "\uD83C\uDF7D"
) {
    /**
     * Nutrition for [grams] of this product.
     *
     * This **always returns a value** — there is no null path, and it does not care whether the
     * product declares a serving size. It simply projects the per-100 g data onto [grams]; a
     * caller that has no serving size of its own and wants a whole "unit" should use
     * [DEFAULT_SERVING_GRAMS] (or, better, [nutritionForUnits], which already applies that
     * fallback).
     */
    fun nutritionFor(grams: Double): Nutrition = nutritionPer100g.scaled(grams / 100.0)

    /**
     * Nutrition for [units] servings of this product, rounding exactly once.
     *
     * ## This is the ONLY correct way to price a multi-serving entry
     * [Nutrition.scaled] rounds [Nutrition.kcal] to an `Int` on every call, so the total must
     * be produced by a single `scaled()` over the unrounded gram count. Rounding the serving to
     * a whole number of grams first, or scaling once per unit and again by `units`, rounds
     * twice and the UI ends up showing a different number from the one that gets stored: on a
     * 294 kcal/100 g product with a 90 g serving, 2 units showed 530 kcal and stored 529.
     *
     * Both call sites — `ConfirmarScreen` (preview) and `AppNavigation` (persist) — must go
     * through here so the number the user sees is the number the diary keeps.
     */
    fun nutritionForUnits(units: Int): Nutrition =
        nutritionFor((servingGrams ?: DEFAULT_SERVING_GRAMS) * units)

    companion object {
        /**
         * Grams assumed for one "unit" of a product that declares no serving size.
         *
         * Open Food Facts is crowd-sourced and plenty of rows have no `serving_quantity`, so the
         * stepper still has to count *something*; 100 g is the only honest choice because it is
         * the basis [nutritionPer100g] is stored on. It lives here, on the model, because two
         * separate screens needed it and each had rolled its own private copy of the constant.
         */
        const val DEFAULT_SERVING_GRAMS = 100.0
    }
}
