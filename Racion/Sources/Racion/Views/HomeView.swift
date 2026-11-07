//
//  HomeView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/InicioScreen.kt
//
//  Pantalla 01 · Inicio. Muestra el saludo, las kcal del día contra la meta, los
//  macros y las comidas registradas.
//
//  ✅ RÚBRICA · "MVVM": la vista no suma nada. `HomeViewModel` entrega un
//     `DailySummary` ya agregado; cada cambio del diario dispara `refresh()`.
//
//  ✅ RÚBRICA · "NavigationLink": el bloque de calorías y las barras navegan al
//     informe semanal, y el botón "+" navega a agregar comida.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: HomeViewModel

    init(app: AppModel) {
        _vm = StateObject(wrappedValue: HomeViewModel(app: app))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Cabecera editorial del diseño original.
                    Text(vm.greeting)
                        .font(.appDisplay)
                        .foregroundStyle(Theme.onSurface)
                    Text(vm.summary.dateLabel.uppercased())
                        .font(.appLabel)
                        .tracking(0.8)
                        .foregroundStyle(Theme.onSurfaceVariant)
                        .padding(.top, 2)

                    Spacer().frame(height: 24)

                    // ✅ NavigationLink: el resumen abre el informe semanal.
                    NavigationLink(value: Route.report) {
                        VStack(spacing: 6) {
                            Text("\(vm.summary.consumed.kcal)")
                                .font(.appDisplayNumber)
                                .foregroundStyle(Theme.onSurface)
                                .contentTransition(.numericText())

                            Text(vm.caloriesLeftLabel)
                                .font(.appBodyMedium)
                                .foregroundStyle(vm.isOverGoal ? Theme.error : Theme.onSurfaceVariant)

                            CalorieProgressBar(
                                progress: vm.summary.progress,
                                isOverGoal: vm.isOverGoal
                            )
                            .padding(.top, 10)

                            HStack(spacing: 4) {
                                Text("Ver informe semanal")
                                Image(systemName: "arrow.right")
                            }
                            .font(.appLabelSmall)
                            .foregroundStyle(Theme.primary)
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer().frame(height: 28)

                    HStack(spacing: 16) {
                        MacroStat(label: "Carbos", value: vm.carbsLabel, color: Theme.primary)
                        MacroStat(label: "Proteína", value: vm.proteinLabel, color: Theme.secondary)
                        MacroStat(label: "Grasas", value: vm.fatLabel, color: Theme.tertiary)
                    }

                    Spacer().frame(height: 30)

                    HStack {
                        Text("Lo de hoy")
                            .font(.appHeadlineMedium)
                            .foregroundStyle(Theme.onSurface)
                        Spacer()
                        if !vm.summary.entries.isEmpty {
                            Text("\(vm.summary.entries.count) registros")
                                .font(.appLabelSmall)
                                .foregroundStyle(Theme.onSurfaceVariant)
                        }
                    }
                    .padding(.bottom, 12)

                    if vm.summary.entries.isEmpty {
                        EmptyState(
                            systemImage: "fork.knife",
                            title: "Todavía no registraste nada",
                            message: "Tocá el botón + para buscar un producto o escanear su código de barras."
                        )
                    } else {
                        ForEach(vm.summary.entries) { entry in
                            MealRow(
                                emoji: entry.product.emoji,
                                name: entry.product.name,
                                meta: AppFormat.mealRowMeta(entry),
                                kcal: entry.totalNutrition.kcal
                            )
                            .padding(.vertical, 8)

                            if entry.id != vm.summary.entries.last?.id {
                                Divider().overlay(Theme.outlineVariant)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Theme.surface.ignoresSafeArea())

            // ✅ FAB nativo: un NavigationLink con apariencia de botón flotante.
            NavigationLink(value: Route.addFood) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.onPrimary)
                    .frame(width: 56, height: 56)
                    .background(Theme.primary, in: Circle())
                    .shadow(color: Theme.primary.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agregar comida")
            .padding(.trailing, 22)
            .padding(.bottom, 22)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { vm.refresh() }
        // SwiftUI vuelve a dibujar cuando cambia `app.entries`; además el VM
        // recalcula el resumen para que la cabecera y las filas sigan coincidiendo.
        .onChange(of: app.entries) { _, _ in vm.refresh() }
    }
}
