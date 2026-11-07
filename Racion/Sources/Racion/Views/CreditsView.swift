//
//  CreditsView.swift
//  Racion · Tu Diario de Mercado
//
//  ✅ RÚBRICA · "Pantalla nueva: Descripción y Créditos". No existía en Android.
//     Muestra el nombre de la app, qué hace, el equipo (Daniel Garcia y Julian
//     Carvajal), las fuentes de datos y la tecnología; además concentra dos
//     controles nativos: el `Toggle` de modo oscuro y el restablecimiento de la
//     demo persistida.
//

import SwiftUI

struct CreditsView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    /// Cuando la pantalla se abre como hoja (desde el onboarding) muestra un
    /// botón "Cerrar"; cuando se apila desde Perfil usa el botón Atrás normal.
    var showsCloseButton: Bool = false

    @State private var showResetConfirmation = false
    @State private var resetMessage: String?

    private let team = ["Daniel Garcia", "Julian Carvajal"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Identidad de la app.
                HStack(spacing: 14) {
                    Text("🍲")
                        .font(.system(size: 30))
                        .frame(width: 64, height: 64)
                        .background(Theme.tertiaryContainer, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ración")
                            .font(.appHeadlineLarge)
                            .foregroundStyle(Theme.onSurface)
                        Text("Tu Diario de Mercado")
                            .font(.appBodyMedium)
                            .foregroundStyle(Theme.onSurfaceVariant)
                    }
                }

                StatusChip(
                    text: "VERSIÓN 1.0 · ENTREGA ACADÉMICA",
                    color: Theme.secondary,
                    background: Theme.secondaryContainer
                )
                .padding(.top, 14)

                Text("Ración es una app para registrar lo que comés, comparar las calorías y los macros con tus metas y ver un informe semanal. Está pensada para el mercado colombiano: los platos del catálogo local son arepa de choclo, bandeja paisa, sancocho y patacón, entre otros.")
                    .font(.appBody)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)

                Spacer().frame(height: 26)

                SectionLabel("EQUIPO")

                VStack(spacing: 10) {
                    ForEach(team, id: \.self) { member in
                        HStack(spacing: 12) {
                            Text(initials(of: member))
                                .font(.appTitleMedium)
                                .foregroundStyle(Theme.onPrimary)
                                .frame(width: 40, height: 40)
                                .background(Theme.primary, in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(member)
                                    .font(.appTitleLarge)
                                    .foregroundStyle(Theme.onSurface)
                                Text("Desarrollo iOS · SwiftUI")
                                    .font(.appBodySmall)
                                    .foregroundStyle(Theme.onSurfaceVariant)
                            }
                            Spacer()
                        }
                        .cardSurface(padding: 12)
                    }
                }
                .padding(.top, 10)

                Spacer().frame(height: 26)

                SectionLabel("TECNOLOGÍA")

                VStack(alignment: .leading, spacing: 8) {
                    TechRow(icon: "swift", text: "SwiftUI + Swift 5 (iOS 17)")
                    TechRow(icon: "square.stack.3d.up", text: "Arquitectura MVVM en módulos")
                    TechRow(icon: "network", text: "URLSession + Codable (sin Retrofit)")
                    TechRow(icon: "internaldrive", text: "Persistencia local en archivos JSON")
                }
                .padding(.top, 10)

                Spacer().frame(height: 26)

                SectionLabel("FUENTES DE DATOS")

                Text("Los productos envasados se consultan en vivo a Open Food Facts (base colaborativa, licencia ODbL). Si no hay conexión, la app usa un catálogo local con platos típicos colombianos. Las metas y los valores nutricionales son una guía y no reemplazan a un profesional de la salud.")
                    .font(.appBodyMedium)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                Spacer().frame(height: 26)

                SectionLabel("PREFERENCIAS")

                // ✅ Toggle nativo: aplica el esquema de color a toda la app.
                Toggle(isOn: Binding(
                    get: { app.settings.isDarkMode },
                    set: { app.setDarkMode($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Modo oscuro")
                            .font(.appTitleMedium)
                            .foregroundStyle(Theme.onSurface)
                        Text("Se guarda en settings.json y se mantiene al reiniciar")
                            .font(.appBodySmall)
                            .foregroundStyle(Theme.onSurfaceVariant)
                    }
                }
                .tint(Theme.primary)
                .padding(.top, 10)
                .padding(14)
                .background(
                    Theme.surfaceContainerLowest,
                    in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .stroke(Theme.outlineVariant, lineWidth: 1)
                )

                Spacer().frame(height: 18)

                Button {
                    showResetConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Restaurar datos de ejemplo")
                    }
                    .font(.appTitleMedium)
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Theme.primaryContainer,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                if let resetMessage {
                    InfoBanner(message: resetMessage)
                        .padding(.top, 12)
                }

                Text("Todos los datos de esta app viven en el dispositivo. No hay backend ni recolección de información personal.")
                    .font(.appBodySmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Descripción y créditos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(Theme.primary)
                }
            }
        }
        .confirmationDialog(
            "¿Restaurar el diario de ejemplo?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restaurar", role: .destructive) {
                app.resetDemoData()
                resetMessage = "Diario de ejemplo restaurado."
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se reemplazan las entradas actuales por las de demostración. Tus metas y tu cuenta no se tocan.")
        }
    }

    private func initials(of name: String) -> String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}

private struct TechRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.secondary)
                .frame(width: 26, height: 26)
                .background(Theme.secondaryContainer, in: Circle())
            Text(text)
                .font(.appBodyMedium)
                .foregroundStyle(Theme.onSurface)
            Spacer()
        }
    }
}
