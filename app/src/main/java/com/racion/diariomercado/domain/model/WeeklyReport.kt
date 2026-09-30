package com.racion.diariomercado.domain.model

/**
 * Everything the "Informe" screen needs for one ISO week, already aggregated.
 *
 * [bestDayLabel] and [activeStreakDays] are `null`/`0` respectively when the week has no
 * logged data, so the screen must tolerate an empty week without special-casing null.
 */
data class WeeklyReport(
    /** Pre-formatted range, e.g. "19–25 AGO". */
    val weekRangeLabel: String,
    val averageKcalPerDay: Int,
    /** Single-letter label of the highest-calorie day, or `null` for an empty week. */
    val bestDayLabel: String?,
    /** Consecutive days with at least one entry, counting back from the most recent one. */
    val activeStreakDays: Int,
    val macroSplit: MacroSplit,
    /** Always 7 entries, one per ISO weekday, in Monday..Sunday order. */
    val days: List<DayTotal>,
    val goalKcal: Int
)

/** One bar in the weekly chart. */
data class DayTotal(
    /** Single-letter weekday label ("L", "M", ...), matching [DayOfWeek.short]. */
    val label: String,
    val kcal: Int,
    /** Marks the best day of the week so the chart can tint it with the primary colour. */
    val isHighlighted: Boolean = false
)

/** Macro distribution as whole percentages. Not validated to sum to 100. */
data class MacroSplit(
    val carbsPct: Int,
    val proteinPct: Int,
    val fatPct: Int
)
