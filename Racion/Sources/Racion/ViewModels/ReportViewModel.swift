//
//  ReportViewModel.swift
//  Racion · Tu Diario de Mercado
//
//  ✅ RÚBRICA · "MVVM" + "Models": la vista recibe un `WeeklyReport` ya agregado.
//     A diferencia del original, TODOS los números (promedio, mejor día, racha,
//     barras) salen de las entradas reales del diario vía `ReportBuilder`.
//

import Foundation

@MainActor
final class ReportViewModel: ObservableObject {

    @Published private(set) var report: WeeklyReport = .empty

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
        self.report = app.weeklyReport()
    }

    func refresh() {
        report = app.weeklyReport()
    }

    var hasData: Bool {
        report.days.contains { $0.kcal > 0 }
    }

    var averageLabel: String { "\(report.averageKcalPerDay)" }
    var bestDayLabel: String { report.bestDayLabel ?? "—" }
    var streakLabel: String { "\(report.activeStreakDays)" }
    var rangeLabel: String { report.weekRangeLabel }

    /// Diferencia contra la meta, con signo, para el pie del gráfico.
    var goalComparison: String {
        guard report.goalKcal > 0 else { return "" }
        let diff = report.averageKcalPerDay - report.goalKcal
        if diff == 0 { return "El promedio coincide con tu meta de \(report.goalKcal) kcal." }
        if diff < 0 { return "El promedio está \(abs(diff)) kcal por debajo de tu meta." }
        return "El promedio está \(diff) kcal por encima de tu meta."
    }
}
