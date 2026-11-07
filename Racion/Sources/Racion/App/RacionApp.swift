//
//  RacionApp.swift
//  Racion · Tu Diario de Mercado
//
//  Punto de entrada de la app iOS (@main). En Android el equivalente era
//  `MainActivity.onCreate` + `setContent { NutriAppTheme { AppNavigation() } }`.
//

import SwiftUI
import FirebaseCore

@main
struct RacionApp: App {

    init() {
        // `FirebaseApp.configure()` termina la app si falta `GoogleService-Info.plist`.
        // Sin ese archivo, la app arranca en modo invitado (datos solo en el dispositivo).
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
