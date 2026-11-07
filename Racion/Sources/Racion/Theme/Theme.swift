//
//  Theme.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/theme/Color.kt + ui/theme/Type.kt
//
//  Los mismos colores de la marca (naranja #E05A2B sobre superficies crema) y la
//  misma escala tipográfica: serif para títulos grandes, sans para el cuerpo.
//  En Compose el tema se aplicaba con `MaterialTheme`; en SwiftUI los colores viven
//  en un enum y la tipografía en extensiones de `Font`.
//
//  ✅ EXTRA: los colores son DINÁMICOS (claro/oscuro) con `UIColor(dynamicProvider:)`,
//     igual que los esquemas Light/Dark de Material 3 del original.
//

import SwiftUI
import UIKit

// MARK: - Utilidades de color

extension UIColor {
    /// Crea un color desde un entero hexadecimal (0xRRGGBB).
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        // El inicializador etiquetado es el único que SwiftUI expone para un
        // `UIColor`; con él el color conserva el `dynamicProvider` y se adapta solo.
        self.init(uiColor: UIColor(hex: hex, alpha: CGFloat(alpha)))
    }

    /// Color que cambia automáticamente entre modo claro y oscuro.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Paleta

/// Roles de color equivalentes al esquema M3 del proyecto Android.
enum Theme {
    static let primary = Color.adaptive(light: 0xE05A2B, dark: 0xFFB59C)
    static let onPrimary = Color.adaptive(light: 0xFFFFFF, dark: 0x5B1C06)
    static let primaryContainer = Color.adaptive(light: 0xF7D9C9, dark: 0x7A2E12)

    static let secondary = Color.adaptive(light: 0x2F6B4F, dark: 0xA6C9B5)
    static let onSecondary = Color.adaptive(light: 0xFFFFFF, dark: 0x133526)
    static let secondaryContainer = Color.adaptive(light: 0xDCEAE1, dark: 0x2C4A3A)

    static let tertiary = Color.adaptive(light: 0xE3A93E, dark: 0xFFD98A)
    static let tertiaryContainer = Color.adaptive(light: 0xF6E7C8, dark: 0x554413)

    static let error = Color.adaptive(light: 0xB3261E, dark: 0xFFB4AB)
    static let errorContainer = Color.adaptive(light: 0xF9DEDC, dark: 0x93000A)

    static let surface = Color.adaptive(light: 0xF7F2E9, dark: 0x1C1A16)
    static let surfaceContainerLowest = Color.adaptive(light: 0xFFFFFF, dark: 0x13110E)
    static let surfaceContainerLow = Color.adaptive(light: 0xFBF7EF, dark: 0x211F1A)
    static let surfaceContainerHighest = Color.adaptive(light: 0xEFE8D8, dark: 0x3A352B)

    static let onSurface = Color.adaptive(light: 0x1C1A16, dark: 0xF7F2E9)
    static let onSurfaceVariant = Color.adaptive(light: 0x8A8272, dark: 0xCCC4B4)
    static let outline = Color.adaptive(light: 0x857A69, dark: 0x968F80)
    static let outlineVariant = Color.adaptive(light: 0xE7DFCF, dark: 0x4B453B)

    /// Tarjetas "oscuras" del diseño (se invierten en modo oscuro, semántica M3).
    static let inverseSurface = Color.adaptive(light: 0x1C1A16, dark: 0xF7F2E9)
    static let inverseOnSurface = Color.adaptive(light: 0xF7F2E9, dark: 0x1C1A16)

    /// El visor de cámara es negro en ambos temas: es cromo de cámara, no contenido.
    static let cameraChrome = Color(hex: 0x0D0D0C)
    static let cameraText = Color(hex: 0xF7F2E9)
    static let cameraTextMuted = Color(hex: 0xB8B2A2)

    static let cornerRadius: CGFloat = 24
    static let cardRadius: CGFloat = 18
}

// MARK: - Tipografía

/// Escala tipográfica. Los títulos grandes usan serif (estilo editorial, como el
/// "Hola!" del diseño original); el resto, la sans del sistema.
extension Font {
    static let appDisplay = Font.system(size: 34, weight: .semibold, design: .serif)
    static let appDisplayNumber = Font.system(size: 48, weight: .semibold, design: .serif)
    static let appHeadlineLarge = Font.system(size: 26, weight: .semibold, design: .serif)
    static let appHeadlineMedium = Font.system(size: 22, weight: .semibold, design: .serif)

    static let appTitleLarge = Font.system(size: 16, weight: .bold)
    static let appTitleMedium = Font.system(size: 14, weight: .semibold)
    static let appTitleSmall = Font.system(size: 12, weight: .semibold)

    static let appBody = Font.system(size: 15)
    static let appBodyMedium = Font.system(size: 13)
    static let appBodySmall = Font.system(size: 12)

    static let appLabel = Font.system(size: 12, weight: .semibold)
    static let appLabelSmall = Font.system(size: 10, weight: .medium)
}

// MARK: - Háptica (extra nativo, no existía en Android)

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
