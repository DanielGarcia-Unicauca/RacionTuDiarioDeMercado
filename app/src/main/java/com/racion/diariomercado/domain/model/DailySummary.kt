package com.racion.diariomercado.domain.model

/**
 * Everything the "Inicio" screen needs for one calendar day, already aggregated.
 *
 * [consumed] is the running total maintained server-side in the `days/{yyyy-MM-dd}` document
 * (see `FirestoreDiaryRepository`), not a client-side fold over [entries] — that is what makes
 * the screen render in one read instead of N+1.
 *
 * ## The server document mirrors this type exactly
 * ```
 * days/{yyyy-MM-dd} -> { kcal, carbsG, proteinG, fatG,
 *                       sugarsG, fiberG, sodiumG,
 *                       entryCount, updatedAt }
 * ```
 * All **seven** [Nutrition] fields are stored, because [consumed] is a `Nutrition` and a missing
 * field would deserialise to `0.0` — indistinguishable from "the user consumed none of it".
 * `entryCount` is a read-only reconciliation counter maintained by the repository; it is
 * deliberately **not** part of this model, since nothing in the UI reads it and a value that can
 * drift from the entries should not be loaded into a domain object.
 */
data class DailySummary(
    /** Pre-formatted for the screen, e.g. "Mié 25 Ago". */
    val dateLabel: String,
    val consumed: Nutrition,
    val goalKcal: Int,
    val entries: List<DiaryEntry>
) {
    /**
     * Calories left for the day. Negative once the goal is exceeded, which the UI renders as
     * an over-budget state rather than clamping to zero — hiding the overshoot is a lie.
     */
    val remainingKcal: Int get() = goalKcal - consumed.kcal
}
