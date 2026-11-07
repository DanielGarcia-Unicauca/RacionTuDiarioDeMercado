//
//  ReportBuilder.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: la parte de FirestoreDiaryRepository que debía calcular los
//  agregados (`observeWeek`), que en Android seguía siendo un TODO.
//
//  ✅ FUNCIONALIDAD REAL (mejora sobre el original): la pantalla "Informe" ya no
//     muestra números escritos a mano en `PreviewData`. Este builder calcula el
//     promedio, el mejor día, la racha y los totales por día desde las entradas
//     reales del diario.
//

import Foundation

enum ReportBuilder {

    /// Calendario con la semana empezando en lunes (ISO), sin importar la región
    /// del dispositivo. Así el gráfico L-M-X-J-V-S-D siempre coincide con la
    /// etiqueta de rango.
    static var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // 2 = lunes
        calendar.locale = AppFormat.locale
        return calendar
    }

    static func weeklyReport(
        entries: [DiaryEntry],
        goals: NutritionGoals,
        reference: Date = Date()
    ) -> WeeklyReport {
        let calendar = isoCalendar
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: reference) else {
            return .empty
        }
        let start = interval.start

        // Un elemento por día ISO, de lunes a domingo.
        var days: [DayTotal] = []
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let kcal = entries
                .filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.totalNutrition.kcal }
            let weekday = Weekday(calendarWeekday: calendar.component(.weekday, from: day))
            days.append(DayTotal(label: weekday?.short ?? "·", kcal: kcal, date: day))
        }

        // El "mejor día" es el de más calorías, pero solo si la semana tiene datos:
        // una semana vacía no tiene mejor día.
        let maxKcal = days.map(\.kcal).max() ?? 0
        if maxKcal > 0, let bestIndex = days.firstIndex(where: { $0.kcal == maxKcal }) {
            days[bestIndex].isHighlighted = true
        }
        let bestDayLabel = maxKcal > 0 ? days.first(where: { $0.isHighlighted })?.label : nil

        // El promedio se calcula sobre los días CON datos. Dividir entre 7 cuando
        // solo hay dos días registrados haría parecer que la persona come la mitad.
        let loggedDays = days.filter { $0.kcal > 0 }
        let average = loggedDays.isEmpty
            ? 0
            : loggedDays.reduce(0) { $0 + $1.kcal } / loggedDays.count

        return WeeklyReport(
            weekRangeLabel: weekRangeLabel(start: start, calendar: calendar),
            averageKcalPerDay: average,
            bestDayLabel: bestDayLabel,
            activeStreakDays: activeStreak(entries: entries, reference: reference, calendar: calendar),
            macroSplit: goals.macroSplit,
            days: days,
            goalKcal: goals.kcalPerDay
        )
    }

    /// Días consecutivos con al menos una entrada, contando hacia atrás desde hoy.
    ///
    /// Si hoy todavía no se registró nada, la racha se cuenta desde ayer: castigar a
    /// la persona a las 00:05 por no haber desayunado todavía no tiene sentido.
    static func activeStreak(entries: [DiaryEntry], reference: Date = Date(), calendar: Calendar = isoCalendar) -> Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: reference)

        let hasEntryOn = { (day: Date) in
            entries.contains { calendar.isDate($0.loggedAt, inSameDayAs: day) }
        }

        if !hasEntryOn(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }

        // Tope de seguridad: 10 años. Sin él, un reloj roto podría dar un bucle
        // prácticamente infinito.
        while streak < 3650, hasEntryOn(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// "24–30 AGO" (o "29 SET–5 OCT" si el rango cruza de mes).
    private static func weekRangeLabel(start: Date, calendar: Calendar) -> String {
        guard let end = calendar.date(byAdding: .day, value: 6, to: start) else { return "" }
        let startDay = calendar.component(.day, from: start)
        let endDay = calendar.component(.day, from: end)
        let startMonth = AppFormat.shortMonth(start).uppercased()
        let endMonth = AppFormat.shortMonth(end).uppercased()

        if startMonth == endMonth {
            return "\(startDay)–\(endDay) \(endMonth)"
        }
        return "\(startDay) \(startMonth)–\(endDay) \(endMonth)"
    }
}
