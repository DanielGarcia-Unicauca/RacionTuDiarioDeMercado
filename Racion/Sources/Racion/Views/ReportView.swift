//
//  ReportView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/InformeScreen.kt
//
//  Pantalla 07 · Informe. Promedio diario, mejor día, racha, donut de macros y
//  barras por día.
//
//  ✅ MEJORA SOBRE EL ORIGINAL: en Android estos números eran literales de
//     `PreviewData` (el TODO de `observeWeek` nunca se implementó). Aquí los
//     calcula `ReportBuilder` desde las entradas reales, así que el donut, las
//     barras y la cabecera no pueden contradecirse.
//

import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: ReportViewModel

    init(app: AppModel) {
        _vm = StateObject(wrappedValue: ReportViewModel(app: app))
    }

    private var report: WeeklyReport { vm.report }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Resumen semanal")
                        .font(.appHeadlineLarge)
                        .foregroundStyle(Theme.onSurface)
                    Spacer()
                    Text(vm.rangeLabel)
                        .font(.appLabelSmall)
                        .tracking(0.5)
                        .foregroundStyle(Theme.onSurfaceVariant)
                }

                if !vm.hasData {
                    EmptyState(
                        systemImage: "chart.bar.xaxis",
                        title: "Semana sin datos",
                        message: "Registrá al menos una comida para ver el promedio y las barras."
                    )
                } else {
                    Spacer().frame(height: 16)

                    HStack(spacing: 10) {
                        SummaryPill(
                            value: vm.averageLabel,
                            label: "PROMEDIO/DÍA",
                            background: Theme.inverseSurface,
                            foreground: Theme.inverseOnSurface
                        )
                        SummaryPill(
                            value: vm.bestDayLabel,
                            label: "MEJOR DÍA",
                            background: Theme.primaryContainer,
                            foreground: Theme.primary
                        )
                        SummaryPill(
                            value: vm.streakLabel,
                            label: "RACHA ACTIVA",
                            background: Theme.tertiaryContainer,
                            foreground: Theme.tertiary
                        )
                    }

                    Spacer().frame(height: 26)

                    HStack(alignment: .center, spacing: 20) {
                        DonutChart(
                            carbsPct: report.macroSplit.carbsPct,
                            proteinPct: report.macroSplit.proteinPct,
                            fatPct: report.macroSplit.fatPct,
                            centerValue: vm.averageLabel,
                            centerLabel: "kcal/día"
                        )
                        .frame(width: 140, height: 140)

                        VStack(alignment: .leading, spacing: 10) {
                            LegendRow(
                                text: "Carbos \(report.macroSplit.carbsPct)%",
                                color: Theme.primary
                            )
                            LegendRow(
                                text: "Proteína \(report.macroSplit.proteinPct)%",
                                color: Theme.secondary
                            )
                            LegendRow(
                                text: "Grasas \(report.macroSplit.fatPct)%",
                                color: Theme.tertiary
                            )
                        }

                        Spacer(minLength: 0)
                    }

                    Spacer().frame(height: 28)

                    SectionLabel("CALORÍAS POR DÍA")

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            WeeklyBarChart(days: report.days, goalKcal: report.goalKcal)
                                .frame(height: 170)

                            HStack {
                                Text("Meta diaria: \(report.goalKcal) kcal")
                                    .font(.appLabelSmall)
                                    .foregroundStyle(Theme.onSurfaceVariant)
                                Spacer()
                                Text("Mejor día resaltado")
                                    .font(.appLabelSmall)
                                    .foregroundStyle(Theme.primary)
                            }
                        }
                    }
                    .padding(.top, 12)

                    InfoBanner(message: vm.goalComparison)
                        .padding(.top, 14)

                    Text("La semana empieza el lunes y el promedio se calcula solo sobre los días con registros, para no castigar los días que todavía no completaste.")
                        .font(.appBodySmall)
                        .foregroundStyle(Theme.onSurfaceVariant)
                        .padding(.top, 12)
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Informe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear { vm.refresh() }
        .onChange(of: app.entries) { _, _ in vm.refresh() }
        .onChange(of: app.goals) { _, _ in vm.refresh() }
    }
}

private struct LegendRow: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.appBodyMedium)
                .foregroundStyle(Theme.onSurface)
        }
    }
}
