package com.racion.diariomercado.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.racion.diariomercado.domain.model.FoodProduct
import com.racion.diariomercado.domain.model.MealSlot
import com.racion.diariomercado.ui.components.*
import com.racion.diariomercado.ui.preview.PreviewData
import kotlin.math.roundToInt

/**
 * Pantalla 04 · Confirmar - Ajustar porción y elegir horario antes de
 * agregar el alimento escaneado al diario.
 *
 * All the nutrition shown here is derived from [product] via [FoodProduct.nutritionForUnits];
 * nothing is hardcoded. That method rounds once, so the calories on this screen are exactly the
 * calories `AppNavigation` writes to the diary — the previous local re-derivation rounded the
 * serving size to a whole number of grams and then scaled again by `units`, so a 2-unit arepa
 * previewed 530 kcal and stored 529.
 *
 * The units stepper and the selected meal slot are genuine local UI state and stay in `remember`
 * — they are not persisted and are not the ViewModel's job yet (ST-1).
 */
@Composable
fun ConfirmarScreen(
    product: FoodProduct = PreviewData.featuredProduct,
    mealSlots: List<MealSlot> = listOf(MealSlot.DESAYUNO, MealSlot.ALMUERZO, MealSlot.SNACK),
    onAddToDiary: (units: Int, mealSlot: MealSlot) -> Unit = { _, _ -> },
    onNavigate: (NavDestination) -> Unit = {}
) {
    var units by remember { mutableStateOf(1) }
    var selectedSlot by remember { mutableStateOf(mealSlots.firstOrNull() ?: MealSlot.DESAYUNO) }

    // The headline number must be the number AppNavigation will store, so it comes from the one
    // canonical method rather than being re-derived here.
    val total = product.nutritionForUnits(units)
    // Rounding is display-only: the label says "≈ 90 g", and rounding the *label* is fine. It is
    // never fed back into the nutrition arithmetic.
    val gramsPerUnitLabel = (product.servingGrams ?: FoodProduct.DEFAULT_SERVING_GRAMS).roundToInt()

    Scaffold(
        containerColor = MaterialTheme.colorScheme.surface,
        bottomBar = { AppBottomBar(selected = NavDestination.Inicio, onSelect = onNavigate) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 20.dp, vertical = 16.dp)
        ) {
            AssistChip(
                onClick = {},
                label = { Text(originLabel(product).uppercase()) },
                colors = AssistChipDefaults.assistChipColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    labelColor = MaterialTheme.colorScheme.primary
                ),
                border = null
            )
            Spacer(Modifier.height(12.dp))
            Text(product.name, style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.onSurface)
            Spacer(Modifier.height(10.dp))
            Text(
                product.ingredientsText ?: "Sin lista de ingredientes declarada.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(Modifier.height(20.dp))

            // Selector de unidades
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(MaterialTheme.shapes.large)
                    .background(MaterialTheme.colorScheme.surfaceContainerHighest)
                    .padding(horizontal = 16.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                StepperButton(symbol = "–", onClick = { if (units > 1) units-- })
                Column(
                    Modifier.weight(1f),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        "$units unidad${if (units > 1) "es" else ""}",
                        style = MaterialTheme.typography.titleLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        "≈ ${gramsPerUnitLabel * units} g",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                StepperButton(symbol = "+", onClick = { units++ })
            }

            Spacer(Modifier.height(20.dp))

            DarkStatCard(
                value = "${total.kcal}",
                label = "CALORÍAS TOTALES",
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                    MiniStat("${total.carbsG.roundToInt()}g", "Carbos")
                    MiniStat("${total.proteinG.roundToInt()}g", "Proteína")
                    MiniStat("${total.fatG.roundToInt()}g", "Grasas")
                }
            }

            Spacer(Modifier.height(20.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                mealSlots.forEach { slot ->
                    OptionPill(
                        text = slot.label,
                        selected = slot == selectedSlot,
                        onClick = { selectedSlot = slot }
                    )
                }
            }

            Spacer(Modifier.weight(1f))

            PrimaryButton(text = "Agregar al diario", onClick = { onAddToDiary(units, selectedSlot) })
        }
    }
}

@Composable
private fun StepperButton(symbol: String, onClick: () -> Unit) {
    Box(
        Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.inverseSurface)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(symbol, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.inverseOnSurface)
    }
}

@Composable
private fun MiniStat(value: String, label: String) {
    Column {
        Text(
            value,
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
            color = MaterialTheme.colorScheme.inverseOnSurface
        )
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.inverseOnSurface.copy(alpha = 0.7f)
        )
    }
}
