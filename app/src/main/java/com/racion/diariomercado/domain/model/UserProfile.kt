package com.racion.diariomercado.domain.model

/**
 * The minimal user record. Deliberately tiny: everything else the user configures (goals,
 * sport focus, weight) lives in its own document so a write to one does not clobber the other.
 */
data class UserProfile(
    val userId: String,
    val displayName: String = "",
    val sportFocus: SportFocus = SportFocus.MANTENIMIENTO,
    val currentWeightKg: Float = 68f
)

/**
 * Training focus picked during onboarding. It tunes the suggested kcal/macro split.
 *
 * [title] and [description] are Spanish because they are rendered verbatim on the
 * "Perfil deportivo" screen. Persist [name], never the strings — copy edits must not require
 * a data migration.
 *
 * [emoji] is the same reasoning as `FoodProduct.emoji`: it is the visual identity of the
 * option, not a theme concern. It lives here rather than in a `when (focus)` block in the
 * screen so that a new option cannot be added without its icon, and so the enum stays the
 * single exhaustive list.
 */
enum class SportFocus(
    val emoji: String,
    val title: String,
    val description: String
) {
    FUTBOL("⚽", "Fútbol", "Carga de carbos en días de partido"),
    RUNNING("🏃", "Running", "Enfoque en resistencia y recuperación"),
    FUERZA("🏋", "Fuerza", "Más proteína, superávit moderado"),
    CICLISMO("🚴", "Ciclismo", "Energía sostenida, carbos altos"),
    PERDIDA_PESO("🔥", "Pérdida de peso", "Déficit controlado y gradual"),
    MANTENIMIENTO("🌿", "Mantenimiento", "Balance general, sin objetivo específico");

    /**
     * Suggested macro split for this focus. `null` means "keep whatever the user already set",
     * which is the correct behaviour for [MANTENIMIENTO] — it means "no specific goal".
     */
    val suggestedMacroSplit: MacroSplit?
        get() = when (this) {
            FUTBOL -> MacroSplit(55, 20, 25)
            RUNNING -> MacroSplit(50, 20, 30)
            FUERZA -> MacroSplit(35, 30, 35)
            CICLISMO -> MacroSplit(55, 15, 30)
            PERDIDA_PESO -> MacroSplit(40, 30, 30)
            MANTENIMIENTO -> null
        }
}
