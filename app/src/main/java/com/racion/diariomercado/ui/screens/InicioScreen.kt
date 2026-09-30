package com.racion.diariomercado.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.racion.diariomercado.domain.model.DiaryEntry
import com.racion.diariomercado.domain.model.Nutrition
import com.racion.diariomercado.ui.components.*
import com.racion.diariomercado.ui.preview.PreviewData
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.math.roundToInt

/**
 * Pantalla 01 · Inicio - Resumen del día.
 * Muestra kcal consumidas vs meta, macros y la lista de comidas del día.
 *
 * Data plumbing note: the macro chips are DERIVED from [consumed] instead of taking their own
 * parameters. They used to be separate `carbsG`/`proteinG`/`fatG` arguments, which let the
 * header and the underlying numbers disagree silently — there was nothing stopping the caller
 * from passing 1340 kcal next to 0 g of protein.
 *
 * The chips round with `roundToInt()`, not `toInt()`. [com.racion.diariomercado.domain.model.Nutrition.scaled]
 * already rounds HALF_UP on the way in; truncating at the UI boundary threw that away and showed
 * 27 g where the arithmetic says 28 g.
 *
 * [meals] and [consumed] must describe the same list. The caller is responsible for folding
 * `consumed` over exactly the entries it passes here, in whatever order it likes to render.
 */
@Composable
fun InicioScreen(
    meals: List<DiaryEntry> = PreviewData.meals,
    consumed: Nutrition = PreviewData.consumed,
    goalKcal: Int = PreviewData.goals.kcalPerDay,
    userName: String = PreviewData.profile.displayName,
    dateLabel: String = PreviewData.todaySummary.dateLabel,
    onAddMeal: () -> Unit = {},
    onOpenReport: () -> Unit = {},
    onNavigate: (NavDestination) -> Unit = {}
) {
    Scaffold(
        containerColor = MaterialTheme.colorScheme.surface,
        bottomBar = { AppBottomBar(selected = NavDestination.Inicio, onSelect = onNavigate) },
        floatingActionButton = { OrangeFab(onClick = onAddMeal) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 20.dp),
            contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp)
        ) {
            item {
                Text(userName, style = MaterialTheme.typography.displayLarge, color = MaterialTheme.colorScheme.onSurface)
                Text(
                    dateLabel.uppercase(),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.height(24.dp))
            }

            item {
                Column(
                    modifier = Modifier.fillMaxWidth().clickable(onClick = onOpenReport),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        "${consumed.kcal}",
                        style = MaterialTheme.typography.displayLarge.copy(fontSize = 48.sp),
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        "de $goalKcal kcal",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Spacer(Modifier.height(24.dp))
            }

            item {
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    MacroStat(label = "CARBOS", value = "${consumed.carbsG.roundToInt()}g", color = MaterialTheme.colorScheme.primary, modifier = Modifier.weight(1f))
                    MacroStat(label = "PROTEÍNA", value = "${consumed.proteinG.roundToInt()}g", color = MaterialTheme.colorScheme.secondary, modifier = Modifier.weight(1f))
                    MacroStat(label = "GRASAS", value = "${consumed.fatG.roundToInt()}g", color = MaterialTheme.colorScheme.tertiary, modifier = Modifier.weight(1f))
                }
                Spacer(Modifier.height(28.dp))
            }

            item {
                Text(
                    "Lo de hoy",
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(Modifier.height(12.dp))
            }

            items(meals) { meal ->
                MealRow(
                    emoji = meal.product.emoji,
                    name = meal.product.name,
                    meta = mealRowMeta(meal),
                    kcal = meal.totalNutrition.kcal
                )
                Spacer(Modifier.height(16.dp))
            }
        }
    }
}

/**
 * Second line of a meal row: "ALMUERZO · 12:45 PM".
 *
 * Built from the domain model instead of stored as a pre-formatted string so the meal slot and
 * the timestamp stay queryable/sortable in Firestore.
 */
private val mealTimeFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("h:mm a")

internal fun mealRowMeta(entry: DiaryEntry): String {
    val time = Instant.ofEpochMilli(entry.loggedAtEpochMillis)
        .atZone(ZoneId.systemDefault())
        .format(mealTimeFormatter)
    return "${entry.mealSlot.label.uppercase()} · $time"
}
