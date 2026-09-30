package com.racion.diariomercado.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.racion.diariomercado.domain.model.SportFocus
import com.racion.diariomercado.ui.components.*
import com.racion.diariomercado.ui.preview.PreviewData

/**
 * Pantalla 05 · Perfil deportivo - Selección del enfoque de entrenamiento
 * que ajusta las metas de calorías y macros.
 *
 * The option list is now [SportFocus] itself: the enum is the exhaustive list, so a new focus
 * cannot be added to the model and forgotten in the UI. The screen used to hold a private
 * `defaultFocuses()` fixture and match the selection by Spanish *title* string, which meant a
 * copy edit silently broke the selection.
 */
@Composable
fun PerfilDeportivoScreen(
    initialSelection: SportFocus = PreviewData.profile.sportFocus,
    onContinue: (SportFocus) -> Unit = {},
    onNavigate: (NavDestination) -> Unit = {}
) {
    var selected by remember { mutableStateOf(initialSelection) }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.surface,
        bottomBar = { AppBottomBar(selected = NavDestination.Perfil, onSelect = onNavigate) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 20.dp, vertical = 16.dp)
        ) {
            Text(
                "¿Para qué entrenas?",
                style = MaterialTheme.typography.headlineLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(Modifier.height(6.dp))
            Text(
                "Ajustamos tus metas de calorías y macros según tu actividad principal.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(20.dp))

            val rows = SportFocus.entries.chunked(2)
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                rows.forEach { rowItems ->
                    Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                        rowItems.forEach { focus ->
                            FocusCard(
                                focus = focus,
                                selected = focus == selected,
                                onClick = { selected = focus },
                                modifier = Modifier.weight(1f)
                            )
                        }
                        if (rowItems.size < 2) Spacer(Modifier.weight(1f))
                    }
                }
            }

            Spacer(Modifier.weight(1f))

            PrimaryButton(
                text = "Continuar",
                onClick = { onContinue(selected) }
            )
        }
    }
}

@Composable
private fun FocusCard(
    focus: SportFocus,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(18.dp))
            .background(
                if (selected) MaterialTheme.colorScheme.primaryContainer
                else MaterialTheme.colorScheme.surfaceContainerLowest
            )
            .clickable(onClick = onClick)
            .border(
                if (selected) 2.dp else 1.dp,
                if (selected) MaterialTheme.colorScheme.primary
                else MaterialTheme.colorScheme.outlineVariant,
                RoundedCornerShape(18.dp)
            )
            .padding(16.dp)
    ) {
        Box(
            Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.tertiaryContainer),
            contentAlignment = Alignment.Center
        ) {
            Text(focus.emoji)
        }
        Spacer(Modifier.height(12.dp))
        Text(focus.title, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onSurface)
        Spacer(Modifier.height(4.dp))
        Text(
            focus.description,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
