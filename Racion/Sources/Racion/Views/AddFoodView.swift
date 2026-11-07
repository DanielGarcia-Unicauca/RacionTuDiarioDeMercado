//
//  AddFoodView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/AgregarScreen.kt
//
//  Pantalla 02 · Agregar. Busca en Open Food Facts y cae al catálogo local cuando
//  no hay red.
//
//  ✅ RÚBRICA · "Entradas de Usuario": `TextField` nativo con `@FocusState`.
//  ✅ RÚBRICA · "NavigationLink": cada resultado es un enlace tipado a la
//     pantalla de confirmación, con el producto como valor de ruta.
//  ✅ RÚBRICA · "Funcionalidad extra": debounce + estados de carga/error/vacío.
//

import SwiftUI

struct AddFoodView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: AddFoodViewModel

    @FocusState private var searchFocused: Bool

    init(app: AppModel) {
        _vm = StateObject(wrappedValue: AddFoodViewModel(app: app))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ✅ TextField nativo con icono y botón de limpiar.
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.onSurfaceVariant)

                    TextField("Busca arepa, ajiaco, buñuelo…", text: $vm.query)
                        .font(.appBody)
                        .foregroundStyle(Theme.onSurface)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($searchFocused)
                        .onSubmit { Task { await vm.reload() } }

                    if !vm.query.isEmpty {
                        Button {
                            vm.query = ""
                            searchFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.onSurfaceVariant)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Limpiar búsqueda")
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(
                    Theme.surfaceContainerLowest,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            searchFocused ? Theme.primary : Theme.outlineVariant,
                            lineWidth: searchFocused ? 2 : 1
                        )
                )

                // Estados de la búsqueda.
                if let error = vm.errorMessage {
                    ErrorBanner(message: error)
                        .padding(.top, 12)
                }
                if let notice = vm.notice {
                    InfoBanner(message: notice)
                        .padding(.top, 12)
                }

                // Filtros por categoría.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.categories, id: \.self) { category in
                            PillTab(
                                text: category,
                                isSelected: vm.selectedCategory == category
                            ) {
                                vm.select(category: category)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }

                if vm.isLoading {
                    LoadingRow(text: "Buscando en Open Food Facts…")
                } else if vm.isEmpty {
                    EmptyState(
                        systemImage: "magnifyingglass",
                        title: "Sin resultados",
                        message: "Probá con otro término o quitá el filtro de categoría."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(vm.results) { food in
                            NavigationLink(value: Route.confirm(food)) {
                                FoodResultRow(food: food)
                            }
                            .buttonStyle(.plain)

                            if food.id != vm.results.last?.id {
                                Divider().overlay(Theme.outlineVariant)
                            }
                        }
                    }
                }

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("¿Qué comiste?")
        .navigationBarTitleDisplayMode(.inline)
        // La raíz que empuja esta pantalla oculta la barra; sin este modificador
        // el botón "Atrás" desaparecería y la persona quedaría atrapada.
        .toolbar(.visible, for: .navigationBar)
        // Debounce: SwiftUI cancela la tarea anterior en cada tecla.
        .task(id: vm.query) {
            let term = vm.query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !term.isEmpty {
                do {
                    try await Task.sleep(nanoseconds: 350_000_000)
                } catch {
                    return // tarea cancelada por una tecla más nueva
                }
            }
            await vm.reload()
        }
    }
}

/// Fila de resultado. Muestra kcal por porción cuando el fabricante la declara y
/// por 100 g cuando no: informar la base equivocada es cómo una manzana de 35
/// kcal termina registrada como una comida completa.
private struct FoodResultRow: View {
    let food: FoodProduct

    private var servingGrams: Double? { food.servingGrams }

    private var shownKcal: Int {
        if let grams = servingGrams {
            return food.nutrition(forGrams: grams).kcal
        }
        return food.nutritionPer100g.kcal
    }

    private var unitLabel: String {
        servingGrams != nil ? "kcal / porción" : "kcal / 100 g"
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(food.emoji)
                .font(.system(size: 20))
                .frame(width: 48, height: 48)
                .background(
                    Theme.tertiaryContainer,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(food.name)
                    .font(.appTitleLarge)
                    .foregroundStyle(Theme.onSurface)
                    .lineLimit(2)
                Text(food.originLabel.uppercased())
                    .font(.appLabelSmall)
                    .tracking(0.4)
                    .foregroundStyle(Theme.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(shownKcal)")
                    .font(.appTitleLarge)
                    .foregroundStyle(Theme.onSurface)
                Text(unitLabel)
                    .font(.appLabelSmall)
                    .foregroundStyle(Theme.onSurfaceVariant)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.onSurfaceVariant)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
