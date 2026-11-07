//
//  DisclaimerView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/AvisoScreen.kt
//
//  Pantalla 09 · Aviso. Recomienda acompañamiento profesional antes de fijar
//  metas de peso o rutinas intensas. Se muestra como primer paso del onboarding.
//

import SwiftUI

struct DisclaimerView: View {
    var onAccept: () -> Void = {}
    var onViewPolicy: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("🌿")
                    .font(.system(size: 30))
                    .frame(width: 72, height: 72)
                    .background(Theme.tertiary, in: Circle())

                Text("Ración acompaña, no reemplaza")
                    .font(.appHeadlineLarge)
                    .foregroundStyle(Theme.onSurface)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                // Texto con énfasis: se concatena con `+` para que el énfasis
                // forme parte del mismo párrafo.
                (
                    Text("La información nutricional es una guía general. ")
                        .foregroundColor(Theme.onSurfaceVariant)
                    + Text("Antes de fijar metas de peso, déficit calórico o rutinas intensas, ")
                        .bold()
                        .foregroundColor(Theme.onSurface)
                    + Text("hablá con un médico, nutricionista o profesional certificado.")
                        .foregroundColor(Theme.onSurfaceVariant)
                )
                .font(.appBody)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

                PrimaryButton(title: "Entendido, continuar") {
                    onAccept()
                }
                .padding(.top, 30)

                if let onViewPolicy {
                    Button {
                        onViewPolicy()
                    } label: {
                        Text("Ver política de uso y fuentes de datos")
                            .font(.appBodyMedium)
                            .underline()
                            .foregroundStyle(Theme.onSurface)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                }

                Text("Ración · Tu Diario de Mercado")
                    .font(.appLabelSmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 28)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.top, 64)
            .padding(.bottom, 40)
        }
        .background(Theme.surface.ignoresSafeArea())
    }
}
