//
//  Charts.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: los `Canvas` de InformeScreen.kt (donut de macros y barras
//  por día).
//
//  En Compose se dibujaba con `drawArc` / `Box.fillMaxHeight`. Aquí:
//   - Donut  -> `Canvas` + `Path.addArc` (el mismo dibujo a mano, sin librerías).
//   - Barras -> `GeometryReader` + `RoundedRectangle` (más simple y accesible).
//

import SwiftUI

/// Donut de distribución de macros.
struct DonutChart: View {
    let carbsPct: Int
    let proteinPct: Int
    let fatPct: Int
    let centerValue: String
    let centerLabel: String

    var body: some View {
        ZStack {
            Canvas { context, size in
                let side = min(size.width, size.height)
                let lineWidth = side * 0.16
                let radius = (side - lineWidth) / 2
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                // Se recorta cada porcentaje de forma independiente: `MacroSplit` no
                // garantiza sumar 100 y un sweep negativo dibujaría hacia atrás.
                let segments: [(Int, Color)] = [
                    (carbsPct, Theme.primary),
                    (proteinPct, Theme.secondary),
                    (fatPct, Theme.tertiary)
                ]

                var start = Angle.degrees(-90)
                for (pct, color) in segments {
                    let clamped = min(max(pct, 0), 100)
                    let sweep = Angle.degrees(360 * Double(clamped) / 100)
                    guard clamped > 0 else { continue }

                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: start,
                        endAngle: start + sweep,
                        clockwise: false
                    )
                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                    )
                    start = start + sweep
                }
            }

            VStack(spacing: 2) {
                Text(centerValue)
                    .font(.appTitleLarge)
                    .foregroundStyle(Theme.onSurface)
                Text(centerLabel)
                    .font(.appLabelSmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
            }
        }
    }
}

/// Gráfico de barras de calorías por día.
///
/// La altura es proporcional al día más alto (o a la meta, si es mayor), para que la
/// meta siempre quede por encima de las barras.
struct WeeklyBarChart: View {
    let days: [DayTotal]
    let goalKcal: Int

    var body: some View {
        GeometryReader { proxy in
            let available = max(proxy.size.height - 24, 10)
            let top = max(days.map(\.kcal).max() ?? 0, max(goalKcal, 1))

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { day in
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(day.isHighlighted ? Theme.primary : Theme.surfaceContainerHighest)
                            .frame(
                                height: max(6, available * CGFloat(day.kcal) / CGFloat(top))
                            )
                        Text(day.label)
                            .font(.appLabelSmall)
                            .foregroundStyle(Theme.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Barra de progreso del día (kcal consumidas vs. meta).
struct CalorieProgressBar: View {
    let progress: Double
    let isOverGoal: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceContainerHighest)
                Capsule()
                    .fill(isOverGoal ? Theme.error : Theme.primary)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 6)
        .animation(.easeOut(duration: 0.5), value: progress)
    }
}
