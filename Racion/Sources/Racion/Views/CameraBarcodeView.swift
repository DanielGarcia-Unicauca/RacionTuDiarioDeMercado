//
//  CameraBarcodeView.swift
//  Racion · Tu Diario de Mercado
//
//  Vista de cámara en vivo que lee códigos de barras con AVFoundation
//  (`AVCaptureMetadataOutput`). No decide nada: entrega el texto del código a
//  `onDetect` y `ScannerViewModel` consulta Open Food Facts con él.
//
//  Formatos de alimentos: EAN-13 (la mayoría de productos), EAN-8, UPC-E y Code128.
//

import SwiftUI
import AVFoundation

struct BarcodeCameraView: UIViewRepresentable {
    /// `true` mientras la pantalla de escaneo está visible y no hay una consulta en curso.
    let isActive: Bool
    let onDetect: (String) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.onDetect = onDetect
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.onDetect = onDetect
        uiView.setRunning(isActive)
    }

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: ()) {
        uiView.setRunning(false)
    }
}

/// Vista UIKit que muestra la cámara y dispara `onDetect` con cada código leído.
final class CameraPreviewView: UIView, AVCaptureMetadataOutputObjectsDelegate {

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var onDetect: ((String) -> Void)?

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    /// La sesión de captura se configura y arranca fuera del hilo principal.
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "racion.barcode-camera")
    private var isConfigured = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = session
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        return nil
    }

    func setRunning(_ running: Bool) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if running {
                if !self.isConfigured {
                    self.isConfigured = self.configure()
                }
                if self.isConfigured, !self.session.isRunning {
                    self.session.startRunning()
                }
            } else if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    /// Devuelve `false` si no hay cámara (simulador) o no se pudo añadir la entrada.
    private func configure() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return false
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard session.canAddInput(input) else { return false }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return false }
        session.addOutput(output)

        let wanted: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .upce, .code128]
        output.metadataObjectTypes = wanted.filter { output.availableMetadataObjectTypes.contains($0) }
        // Las llamadas llegan al hilo principal: `onDetect` modifica estado de SwiftUI.
        output.setMetadataObjectsDelegate(self, queue: .main)
        return true
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue, !code.isEmpty else {
            return
        }
        onDetect?(code)
    }
}
