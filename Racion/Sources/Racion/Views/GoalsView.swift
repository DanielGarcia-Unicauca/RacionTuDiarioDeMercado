//
//  GoalsView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/MetasScreen.kt (la pestaña "Perfil" de Android
//  renderizaba esta misma pantalla).
//
//  Pantalla 06 · Metas y perfil: peso objetivo, meta calórica, días activos,
//  macros, recordatorios, cuenta y accesos a perfil deportivo y créditos.
//
//  ✅ RÚBRICA · "Entradas de Usuario": dos `Slider` nativos (peso y kcal), botones
//     de días y un `Toggle` nativo para recordatorios.
//  ✅ RÚBRICA · "Persistence": `save()` delega en `AppModel`; la vista nunca toca
//     archivos.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: GoalsViewModel

    init(app: AppModel) {
        _vm = StateObject(wrappedValue: GoalsViewModel(app: app))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Tus metas")
                    .font(.appDisplay)
                    .foregroundStyle(Theme.onSurface)
                Text("Ajustá el objetivo y nosotros hacemos las cuentas.")
                    .font(.appBodyMedium)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 4)

                Spacer().frame(height: 22)

                // ✅ Slider nativo: peso objetivo.
                GoalSlider(
                    label: "PESO OBJETIVO",
                    valueLabel: vm.weightLabel,
                    value: $vm.targetWeightKg,
                    range: NutritionGoals.weightRange,
                    step: 0.5,
                    minLabel: "\(Int(NutritionGoals.weightRange.lowerBound)) kg",
                    maxLabel: "actual: \(Int(vm.currentWeightKg)) kg     \(Int(NutritionGoals.weightRange.upperBound)) kg"
                )

                Spacer().frame(height: 22)

                // ✅ Slider nativo: meta calórica diaria.
                GoalSlider(
                    label: "META CALÓRICA DIARIA",
                    valueLabel: vm.kcalLabel,
                    value: $vm.kcalPerDay,
                    range: Double(NutritionGoals.kcalRange.lowerBound)...Double(NutritionGoals.kcalRange.upperBound),
                    step: 50,
                    minLabel: "\(NutritionGoals.kcalRange.lowerBound)",
                    maxLabel: "\(NutritionGoals.kcalRange.upperBound)"
                )

                Spacer().frame(height: 24)

                SectionLabel("DÍAS ACTIVOS POR SEMANA")

                HStack(spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        let selected = vm.activeDays.contains(day)
                        Button {
                            vm.toggle(day: day)
                        } label: {
                            Text(day.short)
                                .font(.appTitleMedium)
                                .foregroundStyle(selected ? Theme.onSecondary : Theme.onSurfaceVariant)
                                .frame(width: 36, height: 36)
                                .background(
                                    selected ? Theme.secondary : Theme.surfaceContainerHighest,
                                    in: Circle()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(day.long)
                    }
                }
                .padding(.top, 10)

                Spacer().frame(height: 24)

                SectionLabel("DISTRIBUCIÓN DE MACROS")

                HStack(spacing: 12) {
                    PercentCard(
                        value: "\(vm.macroSplit.carbsPct)%",
                        label: "Carbos",
                        background: Theme.primaryContainer,
                        foreground: Theme.primary
                    )
                    PercentCard(
                        value: "\(vm.macroSplit.proteinPct)%",
                        label: "Proteína",
                        background: Theme.secondaryContainer,
                        foreground: Theme.secondary
                    )
                    PercentCard(
                        value: "\(vm.macroSplit.fatPct)%",
                        label: "Grasas",
                        background: Theme.tertiaryContainer,
                        foreground: Theme.tertiary
                    )
                }
                .padding(.top, 10)

                Text("Los macros se recalculan al elegir un perfil deportivo.")
                    .font(.appBodySmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 8)

                Spacer().frame(height: 24)

                // ✅ Toggle nativo, persistido en settings.json.
                Toggle(isOn: $vm.remindersEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recordatorios")
                            .font(.appTitleMedium)
                            .foregroundStyle(Theme.onSurface)
                        Text("Un aviso diario para completar el diario")
                            .font(.appBodySmall)
                            .foregroundStyle(Theme.onSurfaceVariant)
                    }
                }
                .tint(Theme.primary)

                Spacer().frame(height: 22)

                PrimaryButton(title: "Guardar metas") {
                    vm.save()
                }

                if let message = vm.savedMessage {
                    InfoBanner(message: message)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .task(id: message) {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            withAnimation { vm.clearSavedMessage() }
                        }
                }

                Spacer().frame(height: 28)

                SectionLabel("TU PERFIL")

                VStack(spacing: 10) {
                    NavigationLink(value: Route.sportProfile) {
                        SettingsRow(
                            icon: "figure.run",
                            title: "Perfil deportivo",
                            subtitle: app.profile.sportFocus.title
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: Route.credits) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "Descripción y créditos",
                            subtitle: "Equipo, fuentes de datos y modo oscuro"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 10)

                Spacer().frame(height: 24)

                SectionLabel("CUENTA")

                if vm.isSignedIn {
                    SurfaceCard {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vm.sessionEmail ?? "Sesión activa")
                                    .font(.appTitleMedium)
                                    .foregroundStyle(Theme.onSurface)
                                    .lineLimit(1)
                                Text("Cuenta local de esta demo")
                                    .font(.appBodySmall)
                                    .foregroundStyle(Theme.onSurfaceVariant)
                            }
                            Spacer()
                            Button("Salir") {
                                vm.signOut()
                            }
                            .font(.appTitleSmall)
                            .foregroundStyle(Theme.error)
                        }
                    }
                    .padding(.top, 10)
                } else {
                    NavigationLink(value: Route.login) {
                        SettingsRow(
                            icon: "person.crop.circle",
                            title: "Iniciar sesión",
                            subtitle: "Guardá tu diario en una cuenta local"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { vm.refreshDerived() }
    }
}

// MARK: - Piezas locales

private struct GoalSlider: View {
    let label: String
    let valueLabel: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let minLabel: String
    let maxLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SectionLabel(label)
                Spacer()
                Text(valueLabel)
                    .font(.appTitleLarge)
                    .foregroundStyle(Theme.primary)
                    .contentTransition(.numericText())
            }

            Slider(value: $value, in: range, step: step)
                .tint(Theme.primary)

            HStack {
                Text(minLabel)
                Spacer()
                Text(maxLabel)
            }
            .font(.appLabelSmall)
            .foregroundStyle(Theme.onSurfaceVariant)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .frame(width: 38, height: 38)
                .background(Theme.primaryContainer, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appTitleMedium)
                    .foregroundStyle(Theme.onSurface)
                Text(subtitle)
                    .font(.appBodySmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.onSurfaceVariant)
        }
        .padding(14)
        .background(
            Theme.surfaceContainerLowest,
            in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.outlineVariant, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
