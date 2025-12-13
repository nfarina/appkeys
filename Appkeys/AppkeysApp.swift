//
//  AppkeysApp.swift
//  Appkeys
//

import SwiftUI
import AppKit

@main
struct AppkeysApp: App {
    @State private var store = HotkeyStore()
    @State private var appDelegate = AppDelegate()

    var body: some Scene {
        MenuBarExtra {
            SettingsView(store: store, onHotkeyChanged: { _ in
                appDelegate.registerAllHotkeys(from: store)
            }, onRequestReopen: {
                reopenMenuBarPanel()
            })
            .onAppear {
                appDelegate.registerAllHotkeys(from: store)
            }
        } label: {
            Image(systemName: "command")
        }
        .menuBarExtraStyle(.window)
    }
}

func reopenMenuBarPanel() {
    // Find our status item button and simulate a click
    guard let button = NSApp.windows
        .compactMap({ $0 as? NSPanel })
        .first(where: { $0.className.contains("MenuBarExtra") })?
        .parent as? NSStatusBarButton ?? findStatusButton()
    else { return }

    button.performClick(nil)
}

func findStatusButton() -> NSStatusBarButton? {
    // Look for the MenuBarExtra window's associated status item
    for window in NSApp.windows {
        if let statusItem = window.value(forKey: "_statusItem") as? NSStatusItem {
            return statusItem.button
        }
    }
    return nil
}

@MainActor
class AppDelegate {
    func registerAllHotkeys(from store: HotkeyStore) {
        HotkeyManager.shared.unregisterAll()

        for hotkey in store.hotkeys {
            guard hotkey.hasHotkey else { continue }

            let appPath = hotkey.appPath
            _ = HotkeyManager.shared.register(hotkey: hotkey) {
                launchOrFocusApp(at: appPath)
            }
        }
    }
}

func launchOrFocusApp(at path: String) {
    let url = URL(fileURLWithPath: path)

    // Check if app is already running
    if let bundleID = Bundle(url: url)?.bundleIdentifier,
       let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
        runningApp.activate()
    } else {
        // Launch the app
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error = error {
                print("Failed to launch app: \(error)")
            }
        }
    }
}
