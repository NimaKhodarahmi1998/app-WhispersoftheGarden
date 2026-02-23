//
//  MyApp.swift
//  WhispersoftheGardenApp
//
//  Main app entry point for Swift Playgrounds
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .portrait
    }
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        WaterShaderCache.warmup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
