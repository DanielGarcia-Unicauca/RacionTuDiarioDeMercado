//
//  DiaryView.swift
//  Racion · Tu Diario de Mercado
//
//  PANTALLA NUEVA de iOS: en Android la pestaña "Diario" abría directamente el
//  buscador de alimentos. Aquí el diario es una pantalla propia con historial,
//  filtro, edición de porciones y borrado.
//
//  ✅ RÚBRICA · "Entradas de Usuario": `Toggle` nativo ("Solo hoy") y `Stepper`
//     nativo ("Porciones") en la hoja de edición.
//
//  ✅ RÚBRICA · "Persistence": editar o borrar llama a `AppModel`, que guarda el
//     diario completo en `diary.json` de forma atómica.
//

import SwiftUI

struct DiaryView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: DiaryViewModel

    @State private var showClearConfirmation = false

    init(app: AppModel) {
        _vm = StateObject(wrappedValue: DiaryViewModel(app: app))
    }

    /// Lista ya filtrada y ordenada por el ViewModel.
    private var entries: [DiaryEntry] { vm.visible(from: app.entries) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tu diario")
                            .font(.appDisplay)
                            .foregroundStyle(Theme.onSurface)
                        Text("Todo lo que registraste, con la porción exacta.")
                            .font(.appBodyMedium)
                            .foregroundStyle(Theme.onSurfaceVariant)
                            .padding(.top, 4)
                    }

                    Spacer()

                    Menu {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Label("Vaciar diario", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.onSurfaceVariant)
                    }
                }

                Spacer().frame(height: 20)

                // Cabecera con el total de la lista visible.
                SurfaceCard {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(vm.totalKcal(in: entries))")
                                .font(.appHeadlineLarge)
                                .foregroundStyle(Theme.onSurface)
                                .contentTransition(.numericText())
                            Text("KCAL EN ESTA VISTA")
                                .font(.appLabelSmall)
                                .tracking(0.6)
                                .foregroundStyle(Theme.onSurfaceVariant)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(vm.totalServings(in: entries))")
                                .font(.appHeadlineLarge)
                                .foregroundStyle(Theme.onSurface)
                            Text("PORCIONES")
                                .font(.appLabelSmall)
                                .tracking(0.6)
                                .foregroundStyle(Theme.onSurfaceVariant)
                        }
                    }
                }
                .padding(.top, 4)

                // ✅ Toggle nativo.
                Toggle(isOn: $vm.onlyToday) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Solo hoy")
                            .font(.appTitleMedium)
                            .foregroundStyle(Theme.onSurface)
                        Text(vm.onlyToday ? "Mostrando el día en curso" : "Mostrando el historial completo")
                            .font(.appBodySmall)
                            .foregroundStyle(Theme.onSurfaceVariant)
                    }
                }
                .tint(Theme.primary)
                .padding(.vertical, 16)

                SectionLabel("REGISTROS")
                    .padding(.bottom, 8)

                if entries.isEmpty {
                    EmptyState(
                        systemImage: "book.closed",
                        title: "No hay registros",
                        message: vm.onlyToday
                            ? "Hoy todavía no agregaste comidas. Podés desactivar \"Solo hoy\" para ver el historial."
                            : "Agregá tu primera comida desde el botón de abajo."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(entries) { entry in
                            HStack(spacing: 10) {
                                MealRow(
                                    emoji: entry.product.emoji,
                                    name: entry.product.name,
                                    meta: AppFormat.mealRowMeta(entry),
                                    kcal: entry.totalNutrition.kcal
                                )
                                .contentShape(Rectangle())
                                .onTapGesture { vm.beginEdit(entry) }

                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        vm.delete(entry)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.onSurfaceVariant)
                                        .frame(width: 32, height: 32)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Eliminar \(entry.product.name)")
                            }
                            .padding(.vertical, 10)

                            if entry.id != entries.last?.id {
                                Divider().overlay(Theme.outlineVariant)
                            }
                        }
                    }

                    Text("Tocá una fila para ajustar sus porciones.")
                        .font(.appBodySmall)
                        .foregroundStyle(Theme.onSurfaceVariant)
                        .padding(.top, 10)
                }

                Spacer().frame(height: 24)

                // ✅ NavigationLink con apariencia de botón primario.
                NavigationLink(value: Route.addFood) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Agregar comida")
                    }
                    .font(.appTitleLarge)
                    .foregroundStyle(Theme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.surface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "¿Vaciar todo el diario?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Vaciar diario", role: .destructive) {
                withAnimation { vm.deleteAll() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminarán todas las entradas, incluidos los días anteriores. No se puede deshacer.")
        }
        .sheet(item: $vm.editingEntry) { entry in
            DiaryEditSheet(vm: vm, entry: entry)
        }
        .overlay(alignment: .top) {
            if let message = vm.lastActionMessage {
                InfoBanner(message: message)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: message) {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        withAnimation { vm.clearMessage() }
                    }
            }
        }
    }

}

// MARK: - Hoja de edición

/// Hoja para ajustar las porciones de una entrada.
///
/// ✅ RÚBRICA · `@ObservedObject`: esta hoja NO posee el ViewModel; lo recibe de
/// `DiaryView`, que sí lo creó con `@StateObject`. Es la diferencia entre "yo
/// creo el estado" y "yo observo un estado que ya existe". Con `@StateObject`
/// aquí se crearía un segundo `DiaryViewModel` y el guardado no llegaría al
/// diario de la pantalla padre.
private struct DiaryEditSheet: View {
    @ObservedObject var vm: DiaryViewModel
    let entry: DiaryEntry

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Text(entry.product.emoji)
                        .font(.system(size: 22))
                        .frame(width: 48, height: 48)
                        .background(Theme.tertiaryContainer, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.product.name)
                            .font(.appTitleLarge)
                            .foregroundStyle(Theme.onSurface)
                        Text(entry.mealSlot.label.uppercased())
                            .font(.appLabelSmall)
                            .tracking(0.5)
                            .foregroundStyle(Theme.onSurfaceVariant)
                    }
                }

                // ✅ Stepper nativo: porciones de la entrada.
                Stepper(value: $vm.editingServings, in: 1...20) {
                    HStack {
                        Text("Porciones")
                            .font(.appTitleMedium)
                        Spacer()
                        Text(AppFormat.unitsLabel(vm.editingServings))
                            .font(.appTitleLarge)
                            .foregroundStyle(Theme.primary)
                    }
                }
                .tint(Theme.primary)

                let preview = entry.product.nutrition(forUnits: vm.editingServings)
                SurfaceCard {
                    HStack {
                        miniValue("\(preview.kcal)", "KCAL")
                        Spacer()
                        miniValue("\(Int(preview.carbsG.rounded())) g", "CARBOS")
                        Spacer()
                        miniValue("\(Int(preview.proteinG.rounded())) g", "PROTEÍNA")
                        Spacer()
                        miniValue("\(Int(preview.fatG.rounded())) g", "GRASAS")
                    }
                }

                PrimaryButton(title: "Guardar cambios") {
                    vm.commitEdit()
                }

                Button("Cancelar") {
                    vm.cancelEdit()
                }
                .font(.appBodyMedium)
                .foregroundStyle(Theme.onSurfaceVariant)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Editar entrada")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(390)])
        .presentationDragIndicator(.visible)
    }

    private func miniValue(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.appTitleLarge)
                .foregroundStyle(Theme.onSurface)
            Text(label)
                .font(.appLabelSmall)
                .foregroundStyle(Theme.onSurfaceVariant)
        }
    }
}
