//
//  SportProfileView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/PerfilDeportivoScreen.kt
//
//  Pantalla 05 · Perfil deportivo. El enfoque elegido ajusta los macros sugeridos.
//
//  ✅ RÚBRICA · "Models": las opciones salen de `SportFocus.allCases`; agregar un
//     enfoque nuevo no puede dejar la pantalla incompleta.
//

import SwiftUI

struct SportProfileView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: SportProfileViewModel

    init(app: AppModel) {
        _vm = StateObject(wrappedValue: SportProfileViewModel(app: app))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("¿Para qué entrenas?")
                    .font(.appDisplay)
                    .foregroundStyle(Theme.onSurface)
                Text("Ajustamos tus metas de calorías y macros según tu actividad principal.")
                    .font(.appBody)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 6)

                SportFocusPicker(selected: $vm.selected)
                    .padding(.top, 18)

                InfoBanner(message: vm.macroPreviewLabel)
                    .padding(.top, 16)

                PrimaryButton(title: "Guardar perfil") {
                    if vm.apply() { dismiss() }
                }
                .padding(.top, 20)

                Text("Podés cambiarlo cuando quieras: el perfil no bloquea el diario.")
                    .font(.appBodySmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Perfil deportivo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

/// Grilla reutilizada por el onboarding y por la pantalla de perfil.
struct SportFocusPicker: View {
    @Binding var selected: SportFocus

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(SportFocus.allCases) { focus in
                FocusCard(focus: focus, isSelected: focus == selected) {
                    selected = focus
                    Haptics.tap()
                }
            }
        }
    }
}

private struct FocusCard: View {
    let focus: SportFocus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(focus.emoji)
                    .font(.system(size: 18))
                    .frame(width: 40, height: 40)
                    .background(Theme.tertiaryContainer, in: Circle())

                Text(focus.title)
                    .font(.appTitleLarge)
                    .foregroundStyle(Theme.onSurface)
                    .padding(.top, 10)
                    .lineLimit(1)

                Text(focus.detail)
                    .font(.appLabelSmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .padding(14)
            .background(
                isSelected ? Theme.primaryContainer : Theme.surfaceContainerLowest,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? Theme.primary : Theme.outlineVariant,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
