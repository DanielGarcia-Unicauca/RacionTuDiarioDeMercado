//
//  ScannerView.swift
//  Racion · Tu Diario de Mercado
//
//  EQUIVALENTE iOS DE: ui/screens/EscanerScreen.kt
//
//  Pantalla 03 · Escanear. El visor es negro en ambos temas (cromo de cámara),
//  con marco amarillo y láser animado.
//
//  ✅ RÚBRICA · "Funcionalidad extra": animación nativa del láser
//     (`repeatForever`), estados de carga y error, y respaldo al catálogo local.
//
//  La cámara lee el código de barras (`BarcodeCameraView`) y cada lectura se
//  consulta en Open Food Facts. La entrada manual usa el mismo flujo. En el
//  simulador (sin cámara) el visor se toca para simular una lectura.
//

import SwiftUI

struct ScannerView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: ScannerViewModel

    @Binding var path: NavigationPath

    @FocusState private var barcodeFocused: Bool
    @State private var laserProgress: CGFloat = 0
    @Environment(\.openURL) private var openURL

    init(app: AppModel, path: Binding<NavigationPath>) {
        _vm = StateObject(wrappedValue: ScannerViewModel(app: app))
        _path = path
    }

    /// Texto del pie del visor según el estado de la cámara.
    @ViewBuilder
    private var cameraFooter: some View {
        switch vm.cameraState {
        case .authorized:
            Text("Apunta al código de barras del producto")
                .font(.appLabelSmall)
                .foregroundStyle(Theme.cameraTextMuted)
        case .unknown:
            Text("Pidiendo acceso a la cámara…")
                .font(.appLabelSmall)
                .foregroundStyle(Theme.cameraTextMuted)
        case .unavailable:
            Text("Simulador: tocá el visor para simular una lectura")
                .font(.appLabelSmall)
                .foregroundStyle(Theme.cameraTextMuted)
        case .denied:
            VStack(spacing: 8) {
                Text("Sin acceso a la cámara. Activalo en Ajustes para escanear.")
                    .font(.appLabelSmall)
                    .foregroundStyle(Theme.cameraTextMuted)
                    .multilineTextAlignment(.center)
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.appTitleMedium)
                .foregroundStyle(Theme.primary)
            }
            .padding(.horizontal, 24)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Escanea el producto")
                    .font(.appHeadlineLarge)
                    .foregroundStyle(Theme.cameraText)
                Text("Apunta la cámara al código de barras del empaque")
                    .font(.appBodyMedium)
                    .foregroundStyle(Theme.cameraTextMuted)
                    .padding(.top, 4)

                Spacer().frame(height: 18)

                // Visor: cámara en vivo cuando hay permiso; en el simulador, toque para simular.
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .fill(Color(hex: 0x0D0D0C))

                    if vm.cameraState == .authorized {
                        BarcodeCameraView(isActive: vm.isCameraRunning) { code in
                            Task { await vm.handleDetectedCode(code) }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                    }

                    ZStack {
                        GeometryReader { proxy in
                            ScanFrameShape()
                                .stroke(Theme.tertiary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .padding(22)

                            // ✅ Animación nativa: el láser sube y baja sin fin.
                            let travel = max(proxy.size.height - 52, 1)
                            Rectangle()
                                .fill(Theme.primary.opacity(0.85))
                                .frame(height: 2)
                                .shadow(color: Theme.primary, radius: 6)
                                .offset(y: 26 + travel * laserProgress)
                                .animation(
                                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                                    value: laserProgress
                                )
                        }
                        .padding(10)

                        VStack {
                            Spacer()
                            cameraFooter
                                .padding(.bottom, 18)
                        }
                    }
                }
                .frame(height: 300)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Solo en el simulador: sin cámara, tocar el visor simula una lectura.
                    if vm.cameraState != .authorized {
                        Task { await vm.simulateScan() }
                    }
                }
                .onAppear { laserProgress = 1 }
                .task { await vm.screenAppeared() }
                .onDisappear { vm.screenDisappeared() }

                if vm.isLoading {
                    HStack(spacing: 10) {
                        ProgressView().tint(Theme.primary)
                        Text("Consultando Open Food Facts…")
                            .font(.appBodyMedium)
                            .foregroundStyle(Theme.cameraTextMuted)
                    }
                    .padding(.top, 16)
                }

                Spacer().frame(height: 20)

                // ✅ TextField nativo para códigos que la cámara no puede leer.
                Text("INGRESAR CÓDIGO MANUALMENTE")
                    .font(.appLabelSmall)
                    .tracking(0.7)
                    .foregroundStyle(Theme.cameraTextMuted)

                HStack(spacing: 10) {
                    TextField("7801234567890", text: $vm.barcode)
                        .font(.appBody)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .focused($barcodeFocused)
                        .submitLabel(.search)
                        .onSubmit { Task { await vm.lookup() } }
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(
                            Theme.surfaceContainerLowest,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )

                    Button {
                        barcodeFocused = false
                        Task { await vm.lookup() }
                    } label: {
                        Text("Buscar")
                            .font(.appTitleMedium)
                            .foregroundStyle(Theme.onPrimary)
                            .padding(.horizontal, 18)
                            .frame(height: 50)
                            .background(
                                Theme.primary,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isLoading)
                }
                .padding(.top, 10)

                if let error = vm.errorMessage {
                    ErrorBanner(message: error)
                        .padding(.top, 12)
                }
                if let notice = vm.notice {
                    InfoBanner(message: notice)
                        .padding(.top, 12)
                }

                Spacer().frame(height: 22)

                // Hoja inferior con los últimos productos registrados.
                VStack(alignment: .leading, spacing: 12) {
                    Capsule()
                        .fill(Theme.outlineVariant)
                        .frame(width: 40, height: 4)
                        .frame(maxWidth: .infinity)

                    SectionLabel("ESCANEADO RECIENTEMENTE")

                    let recents = vm.recentScans(from: app.entries)
                    if recents.isEmpty {
                        Text("Todavía no registraste productos.")
                            .font(.appBodyMedium)
                            .foregroundStyle(Theme.onSurfaceVariant)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(recents) { entry in
                            HStack(spacing: 12) {
                                Text(entry.product.emoji)
                                    .font(.system(size: 16))
                                    .frame(width: 36, height: 36)
                                    .background(Theme.surfaceContainerHighest, in: Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.product.name)
                                        .font(.appTitleMedium)
                                        .foregroundStyle(Theme.onSurface)
                                        .lineLimit(1)
                                    Text(AppFormat.timeAgo(from: entry.loggedAt).uppercased())
                                        .font(.appLabelSmall)
                                        .foregroundStyle(Theme.onSurfaceVariant)
                                }

                                Spacer(minLength: 8)

                                Text("\(entry.totalNutrition.kcal)")
                                    .font(.appTitleLarge)
                                    .foregroundStyle(Theme.onSurface)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Theme.surface,
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                )
                .padding(.horizontal, -20)
                .padding(.bottom, -32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.cameraChrome.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: vm.foundProduct) { _, _ in
            // El ViewModel entrega el producto una sola vez para que volver atrás
            // no dispare otra navegación.
            if let product = vm.consumeFoundProduct() {
                path.append(Route.confirm(product))
            }
        }
    }
}

/// Marco de escaneo dibujado con `Path`: solo las cuatro esquinas.
private struct ScanFrameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length = min(rect.width, rect.height) * 0.18
        let strokeInset: CGFloat = 0

        let left = rect.minX + strokeInset
        let right = rect.maxX - strokeInset
        let top = rect.minY + strokeInset
        let bottom = rect.maxY - strokeInset

        // Superior izquierda
        path.move(to: CGPoint(x: left, y: top + length))
        path.addLine(to: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: left + length, y: top))

        // Superior derecha
        path.move(to: CGPoint(x: right - length, y: top))
        path.addLine(to: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: top + length))

        // Inferior izquierda
        path.move(to: CGPoint(x: left, y: bottom - length))
        path.addLine(to: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: left + length, y: bottom))

        // Inferior derecha
        path.move(to: CGPoint(x: right - length, y: bottom))
        path.addLine(to: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: right, y: bottom - length))

        return path
    }
}
