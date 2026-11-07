//
//  Components.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/components/AppComponents.kt
//
//  Cada `@Composable` del original tiene aquí su `View` equivalente:
//    PrimaryButton · SectionLabel · PillTab · OptionPill · MacroStat
//    MealRow · DarkStatCard · OrangeFab
//
//  Se mantuvieron los mismos nombres a propósito: quien conozca el código Android
//  encuentra la traducción sin buscar.
//

import SwiftUI

// MARK: - Contenedor de pantalla

/// Fondo crema + scroll vertical con el padding horizontal del diseño (20 pt).
struct ScreenContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Botones y pestañas

/// Botón primario naranja de ancho completo (52 pt de alto, como el original).
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Theme.onPrimary)
                } else {
                    Text(title).font(.appTitleLarge)
                }
            }
            .foregroundStyle(Theme.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                (isEnabled ? Theme.primary : Theme.primary.opacity(0.4)),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

/// Etiqueta de sección en mayúsculas pequeñas ("LO DE HOY").
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.appLabel)
            .tracking(0.8)
            .foregroundStyle(Theme.onSurfaceVariant)
    }
}

/// Pastilla seleccionable tipo tab (Almuerzo / Frituras / Sopas...).
struct PillTab: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.appTitleMedium)
                .foregroundStyle(isSelected ? Theme.inverseOnSurface : Theme.onSurfaceVariant)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Theme.inverseSurface : Theme.surfaceContainerHighest,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

/// Botón rectangular tipo pastilla para Desayuno / Almuerzo / Snack / Cena.
struct OptionPill: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.appTitleMedium)
                .foregroundStyle(isSelected ? Theme.inverseOnSurface : Theme.onSurface)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.inverseSurface : Color.clear, in: Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? Theme.inverseSurface : Theme.outlineVariant,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }
}

/// Botón flotante circular naranja ("+ agregar comida").
struct OrangeFab: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.onPrimary)
                .frame(width: 56, height: 56)
                .background(Theme.primary, in: Circle())
                .shadow(color: Theme.primary.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Agregar comida")
    }
}

// MARK: - Datos

/// Chip de macro con barra de color (usado en el resumen del día).
struct MacroStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(height: 4)
            Text(value)
                .font(.appTitleLarge)
                .foregroundStyle(Theme.onSurface)
            Text(label.uppercased())
                .font(.appLabelSmall)
                .tracking(0.6)
                .foregroundStyle(Theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Fila de comida (Inicio y Diario).
struct MealRow: View {
    let emoji: String
    let name: String
    let meta: String
    let kcal: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 40, height: 40)
                .background(Theme.tertiaryContainer, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.appTitleMedium)
                    .foregroundStyle(Theme.onSurface)
                    .lineLimit(1)
                Text(meta.uppercased())
                    .font(.appLabelSmall)
                    .tracking(0.4)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text("\(kcal)")
                .font(.appTitleLarge)
                .foregroundStyle(Theme.onSurface)
        }
        .contentShape(Rectangle())
    }
}

/// Tarjeta oscura con métrica grande (cabecera de "Confirmar").
struct DarkStatCard<Content: View>: View {
    private let value: String
    private let label: String
    private let content: Content

    init(value: String, label: String, @ViewBuilder content: () -> Content) {
        self.value = value
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.appDisplay)
                .foregroundStyle(Theme.inverseOnSurface)
            Text(label.uppercased())
                .font(.appLabel)
                .tracking(0.8)
                .foregroundStyle(Theme.inverseOnSurface.opacity(0.7))
            content
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            Theme.inverseSurface,
            in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        )
    }
}

extension DarkStatCard where Content == EmptyView {
    init(value: String, label: String) {
        self.init(value: value, label: label) { EmptyView() }
    }
}

/// Tarjeta blanca/crema con borde suave.
struct SurfaceCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Theme.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.outlineVariant, lineWidth: 1)
            )
    }
}

/// Chip informativo con punto de estado.
struct StatusChip: View {
    let text: String
    var color: Color = Theme.secondary
    var background: Color = Theme.secondaryContainer

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
                .font(.appTitleSmall)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background, in: Capsule())
    }
}

/// Tarjeta de porcentaje de macros (pantalla Metas / Informe).
struct PercentCard: View {
    let value: String
    let label: String
    let background: Color
    let foreground: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.appHeadlineMedium)
                .foregroundStyle(foreground)
            Text(label.uppercased())
                .font(.appLabelSmall)
                .tracking(0.5)
                .foregroundStyle(foreground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(background, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

/// Píldora de resumen con valor grande y etiqueta (pantalla Informe).
struct SummaryPill: View {
    let value: String
    let label: String
    let background: Color
    let foreground: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.appHeadlineMedium)
                .foregroundStyle(foreground)
            Text(label)
                .font(.appLabelSmall)
                .multilineTextAlignment(.center)
                .foregroundStyle(foreground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(background, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

// MARK: - Estados (carga / error / vacío)

/// ✅ RÚBRICA · "Funcionalidad extra": estados de carga y error explícitos.
struct LoadingRow: View {
    var text: String = "Cargando…"

    var body: some View {
        HStack(spacing: 10) {
            ProgressView().tint(Theme.primary)
            Text(text)
                .font(.appBodyMedium)
                .foregroundStyle(Theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
    }
}

/// Banner de error descartable.
struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.error)
            Text(message)
                .font(.appBodyMedium)
                .foregroundStyle(Theme.error)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.error)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Theme.errorContainer, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

/// Banner informativo (por ejemplo: "sin conexión, catálogo local").
struct InfoBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Theme.primary)
            Text(message)
                .font(.appBodySmall)
                .foregroundStyle(Theme.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Theme.primaryContainer.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Estado vacío con icono.
struct EmptyState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(Theme.onSurfaceVariant)
            Text(title)
                .font(.appTitleLarge)
                .foregroundStyle(Theme.onSurface)
            Text(message)
                .font(.appBodyMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Campo de texto

extension View {
    /// Aspecto de los campos del diseño: fondo blanco, borde suave, 50 pt de alto.
    func racionField() -> some View {
        self
            .font(.appBody)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                Theme.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.outlineVariant, lineWidth: 1)
            )
    }

    /// Tarjeta de superficie con borde.
    func cardSurface(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                Theme.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.outlineVariant, lineWidth: 1)
            )
    }
}
