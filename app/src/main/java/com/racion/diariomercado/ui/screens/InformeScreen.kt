package com.racion.diariomercado.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.racion.diariomercado.domain.model.DayTotal
import com.racion.diariomercado.domain.model.WeeklyReport
import com.racion.diariomercado.ui.components.*
import com.racion.diariomercado.ui.preview.PreviewData

/**
 * Pantalla 07 · Informe - Resumen semanal rediseñado: promedio diario,
 * mejor día, racha activa, distribución de macros (donut) y calorías por día (barras).
 *
 * The eleven former scalar parameters collapsed into a single [WeeklyReport]: they were
 * individually optional, so it was possible to render a header claiming 1671 kcal/day next
 * to bars that averaged 1626.
 *
 * The aggregate numbers ([WeeklyReport.averageKcalPerDay], [WeeklyReport.bestDayLabel],
 * [WeeklyReport.goalKcal]) are now derived from [WeeklyReport.days] and so cannot contradict the
 * bars. Two fields are still NOT derived from anything: [WeeklyReport.macroSplit] and
 * [WeeklyReport.activeStreakDays] are bare literals in `PreviewData`, because the day totals
 * carry no per-day macro data and no history to count a streak from. Until
 * `DiaryRepository.observeWeek` computes them, the donut and the streak widget render
 * decorative numbers — the screen is not yet "nothing left to disagree about".
 */
@Composable
fun InformeScreen(
    report: WeeklyReport = PreviewData.weeklyReport,
    onNavigate: (NavDestination) -> Unit = {}
) {
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
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Resumen semanal",
                    style = MaterialTheme.typography.headlineLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(report.weekRangeLabel, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }

            Spacer(Modifier.height(16.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                SummaryPill(
                    "${report.averageKcalPerDay}",
                    "PROMEDIO/DÍA",
                    MaterialTheme.colorScheme.inverseSurface,
                    MaterialTheme.colorScheme.inverseOnSurface,
                    Modifier.weight(1f)
                )
                SummaryPill(
                    report.bestDayLabel ?: "—",
                    "MEJOR DÍA",
                    MaterialTheme.colorScheme.primaryContainer,
                    MaterialTheme.colorScheme.primary,
                    Modifier.weight(1f)
                )
                SummaryPill(
                    "${report.activeStreakDays}",
                    "RACHA\nACTIVA",
                    MaterialTheme.colorScheme.tertiaryContainer,
                    MaterialTheme.colorScheme.tertiary,
                    Modifier.weight(1f)
                )
            }

            Spacer(Modifier.height(24.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                DonutChart(
                    carbsPct = report.macroSplit.carbsPct,
                    proteinPct = report.macroSplit.proteinPct,
                    fatPct = report.macroSplit.fatPct,
                    centerValue = "${report.averageKcalPerDay}",
                    centerLabel = "kcal/día",
                    modifier = Modifier.size(140.dp)
                )
                Spacer(Modifier.width(20.dp))
                Column {
                    LegendRow("Carbos ${report.macroSplit.carbsPct}%", MaterialTheme.colorScheme.primary)
                    Spacer(Modifier.height(8.dp))
                    LegendRow("Proteína ${report.macroSplit.proteinPct}%", MaterialTheme.colorScheme.secondary)
                    Spacer(Modifier.height(8.dp))
                    LegendRow("Grasas ${report.macroSplit.fatPct}%", MaterialTheme.colorScheme.tertiary)
                }
            }

            Spacer(Modifier.height(28.dp))

            SectionLabel("CALORÍAS POR DÍA")
            Spacer(Modifier.height(12.dp))
            WeeklyBarChart(days = report.days, goalKcal = report.goalKcal, modifier = Modifier.fillMaxWidth().height(160.dp))
        }
    }
}

@Composable
private fun SummaryPill(value: String, label: String, bg: Color, fg: Color, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(MaterialTheme.shapes.large)
            .background(bg)
            .padding(vertical = 14.dp, horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(value, style = MaterialTheme.typography.headlineMedium, color = fg)
        Spacer(Modifier.height(4.dp))
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = fg,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
    }
}

@Composable
private fun LegendRow(text: String, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            Modifier
                .size(10.dp)
                .clip(CircleShape)
                .background(color)
        )
        Spacer(Modifier.width(8.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface)
    }
}

/** Donut de macros dibujado a mano con Canvas. */
@Composable
private fun DonutChart(
    carbsPct: Int,
    proteinPct: Int,
    fatPct: Int,
    centerValue: String,
    centerLabel: String,
    modifier: Modifier = Modifier
) {
    // Los colores se leen fuera del bloque draw (DrawScope no es composable).
    val primary = MaterialTheme.colorScheme.primary
    val secondary = MaterialTheme.colorScheme.secondary
    val tertiary = MaterialTheme.colorScheme.tertiary
    Box(modifier, contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val strokeWidth = size.minDimension * 0.16f
            val diameter = size.minDimension - strokeWidth
            val topLeft = androidx.compose.ui.geometry.Offset(
                (size.width - diameter) / 2f,
                (size.height - diameter) / 2f
            )
            val arcSize = Size(diameter, diameter)
            var startAngle = -90f

            val segments = listOf(
                carbsPct to primary,
                proteinPct to secondary,
                fatPct to tertiary
            )
            segments.forEach { (pct, color) ->
                // `MacroSplit` is documented as NOT validated to sum to 100, and a real
                // repository that computes rounded percentages genuinely produces 101. A
                // negative sweep would draw backwards and rotate every later segment with it,
                // so each percentage is clamped independently and the running angle is clamped
                // too. This is a display guard only; it does not renormalise the split.
                val sweep = 360f * (pct.coerceIn(0, 100) / 100f)
                drawArc(
                    color = color,
                    startAngle = startAngle.coerceIn(-360f, 360f),
                    sweepAngle = sweep,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Butt)
                )
                startAngle = (startAngle + sweep).coerceIn(-360f, 360f)
            }
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(centerValue, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onSurface)
            Text(centerLabel, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

/**
 * Gráfico de barras de calorías por día.
 *
 * Draws one bar per day, height proportional to that day's kcal against the tallest day, with
 * the highlighted day in the primary colour. It does **not** draw a goal line — the previous
 * KDoc claimed a dotted meta line that was never implemented. [goalKcal] only sets the scale
 * floor, so the goal is legible as "taller than every bar" but is not drawn.
 */
@Composable
private fun WeeklyBarChart(days: List<DayTotal>, goalKcal: Int, modifier: Modifier = Modifier) {
    // coerceAtLeast(1), not just coerceAtLeast(goalKcal): an empty week with a zero goal would
    // leave maxKcal at 0, and 0/0 is NaN — which coerceIn returns unchanged, handing fillMaxHeight
    // a NaN instead of a clamped fraction.
    val maxKcal = (days.maxOfOrNull { it.kcal } ?: goalKcal).coerceAtLeast(goalKcal).coerceAtLeast(1)
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        days.forEach { day ->
            Column(
                modifier = Modifier.weight(1f),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                val heightFraction = day.kcal / maxKcal.toFloat()
                Box(
                    Modifier
                        .fillMaxWidth()
                        .fillMaxHeight(0.85f),
                    contentAlignment = Alignment.BottomCenter
                ) {
                    Box(
                        Modifier
                            .fillMaxWidth(0.6f)
                            .fillMaxHeight(heightFraction.coerceIn(0.05f, 1f))
                            .clip(RoundedCornerShape(6.dp))
                            .background(
                                if (day.isHighlighted) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.surfaceContainerHighest
                            )
                    )
                }
                Spacer(Modifier.height(6.dp))
                Text(day.label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
