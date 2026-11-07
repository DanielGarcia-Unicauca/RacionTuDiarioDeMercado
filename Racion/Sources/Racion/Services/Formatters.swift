//
//  Formatters.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: los `DateTimeFormatter` repartidos por las pantallas Kotlin
//  (`mealTimeFormatter`, `timeAgoLabel`, etc.).
//
//  En Android cada pantalla creaba su propio formatter. Aquí están todos juntos para
//  que "12:45 PM" se vea igual en Inicio, en el Diario y en el Escáner.
//

import Foundation

enum AppFormat {

    /// Locale colombiano: la app es para el mercado colombiano y los textos están en
    /// español. Se usa también en `ReportBuilder` para que la semana empiece lunes.
    static let locale = Locale(identifier: "es_CO")

    /// Para horas se usa `en_US_POSIX` porque el diseño original muestra "12:45 PM"
    /// y el locale español produce "12:45 p. m." (con puntos y espacio).
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let dayLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEE d MMM"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let weekdayLongFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    /// "mié 26 ago" -> "Mié 26 Ago".
    static func dayLabel(_ date: Date) -> String {
        dayLabelFormatter.string(from: date).capitalized
    }

    /// "ago" (minúsculas; quien lo muestra lo pasa a mayúsculas). En `es_CO`
    /// `DateFormatter` devuelve "oct." con punto: se quita para que el rango de la
    /// semana se lea "26 OCT–1 NOV" y no "26 OCT.–1 NOV.".
    static func shortMonth(_ date: Date) -> String {
        monthFormatter.string(from: date).replacingOccurrences(of: ".", with: "")
    }

    /// "12:45 PM".
    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// "miércoles".
    static func weekdayName(_ date: Date) -> String {
        weekdayLongFormatter.string(from: date).capitalized
    }

    /// Segunda línea de una fila del diario: "ALMUERZO · 12:45 PM".
    static func mealRowMeta(_ entry: DiaryEntry) -> String {
        "\(entry.mealSlot.label.uppercased()) · \(time(entry.loggedAt))"
    }

    /// "Hoy", "Ayer", "Hace 3 días"...
    ///
    /// Se calcula desde la fecha real y no se guarda: un texto pre-formateado se
    /// vuelve mentira apenas pasa el tiempo.
    static func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: Date())).day ?? 0
        switch days {
        case ...0: return "Hoy"
        case 1: return "Ayer"
        case 2..<7: return "Hace \(days) días"
        case 7..<30: return "Hace \(days / 7) sem"
        default: return "Hace \(days / 30) mes"
        }
    }

    /// "1 unidad" / "3 unidades".
    static func unitsLabel(_ units: Int) -> String {
        "\(units) unidad\(units == 1 ? "" : "es")"
    }

    /// "1.5 kg" con un decimal fijo, como `"%.1f".format(weight)` en Kotlin.
    static func kilograms(_ value: Double) -> String {
        String(format: "%.1f kg", value)
    }
}
