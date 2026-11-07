//
//  ConfirmView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/ConfirmarScreen.kt
//
//  Pantalla 04 · Confirmar. Ajusta porciones y comida antes de guardar.
//
//  ✅ RÚBRICA · "Entradas de Usuario": `Stepper` nativo para las porciones.
//  ✅ RÚBRICA · "Models": el número que se muestra y el que se guarda salen del
//     mismo método (`nutrition(forUnits:)`), así no puede repetirse el bug de
//     doble redondeo del original (530 mostradas / 529 guardadas).
//

import SwiftUI

struct ConfirmView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: ConfirmViewModel

    private let onAdded: () -> Void

    init(app: AppModel, product: FoodProduct, onAdded: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: ConfirmViewModel(product: product))
        self.onAdded = onAdded
    }

    private var total: Nutrition { vm.total }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Chip de origen: marca o categorías.
                StatusChip(
                    text: vm.originLabel.uppercased(),
                    color: Theme.primary,
                    background: Theme.primaryContainer
                )

                if let nutriscore = vm.nutriscoreLabel {
                    StatusChip(
                        text: nutriscore,
                        color: Theme.secondary,
                        background: Theme.secondaryContainer
                    )
                    .padding(.top, 8)
                }

                Text(vm.product.name)
                    .font(.appHeadlineLarge)
                    .foregroundStyle(Theme.onSurface)
                    .padding(.top, 14)

                Text(vm.ingredients)
                    .font(.appBody)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 6)

                Spacer().frame(height: 20)

                // ✅ Stepper nativo con etiqueta compuesta.
                Stepper(value: $vm.servings, in: 1...20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Porciones")
                                .font(.appTitleMedium)
                                .foregroundStyle(Theme.onSurface)
                            Text(vm.gramsLabel)
                                .font(.appBodySmall)
                                .foregroundStyle(Theme.onSurfaceVariant)
                        }
                        Spacer()
                        Text(AppFormat.unitsLabel(vm.servings))
                            .font(.appTitleLarge)
                            .foregroundStyle(Theme.primary)
                    }
                }
                .tint(Theme.primary)
                .padding(16)
                .background(
                    Theme.surfaceContainerHighest,
                    in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                )

                Spacer().frame(height: 20)

                DarkStatCard(value: "\(total.kcal)", label: "CALORÍAS TOTALES") {
                    HStack(spacing: 24) {
                        InverseStat(value: "\(Int(total.carbsG.rounded()))g", label: "Carbos")
                        InverseStat(value: "\(Int(total.proteinG.rounded()))g", label: "Proteína")
                        InverseStat(value: "\(Int(total.fatG.rounded()))g", label: "Grasas")
                    }
                }

                Spacer().frame(height: 22)

                SectionLabel("¿A QUÉ COMIDA?")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.mealSlots) { slot in
                            OptionPill(
                                text: slot.label,
                                isSelected: vm.mealSlot == slot
                            ) {
                                vm.mealSlot = slot
                                Haptics.tap()
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }

                Spacer().frame(height: 10)

                PrimaryButton(title: "Agregar al diario") {
                    vm.add(to: app)
                    onAdded()
                }

                Text("El total se guarda calculado con las porciones elegidas; editar la entrada más tarde vuelve a calcularlo desde el producto.")
                    .font(.appBodySmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("Confirmar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

/// Métrica pequeña sobre la tarjeta oscura (usa los roles `inverse`).
private struct InverseStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.appTitleLarge)
                .foregroundStyle(Theme.inverseOnSurface)
            Text(label)
                .font(.appLabelSmall)
                .foregroundStyle(Theme.inverseOnSurface.opacity(0.7))
        }
    }
}
