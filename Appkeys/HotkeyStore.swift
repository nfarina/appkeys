//
//  HotkeyStore.swift
//  Appkeys
//

import Foundation
import AppKit

@Observable
class HotkeyStore {
    var hotkeys: [AppHotkey] = []

    private let saveURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appkeysDir = appSupport.appendingPathComponent("Appkeys")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appkeysDir, withIntermediateDirectories: true)

        saveURL = appkeysDir.appendingPathComponent("hotkeys.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }

        do {
            let data = try Data(contentsOf: saveURL)
            hotkeys = try JSONDecoder().decode([AppHotkey].self, from: data)
        } catch {
            print("Failed to load hotkeys: \(error)")
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(hotkeys)
            try data.write(to: saveURL)
        } catch {
            print("Failed to save hotkeys: \(error)")
        }
    }

    func addApp(at url: URL) {
        let hotkey = AppHotkey(appPath: url.path)
        hotkeys.append(hotkey)
        save()
    }

    func remove(_ hotkey: AppHotkey) {
        hotkeys.removeAll { $0.id == hotkey.id }
        save()
    }

    func update(_ hotkey: AppHotkey) {
        if let index = hotkeys.firstIndex(where: { $0.id == hotkey.id }) {
            hotkeys[index] = hotkey
            save()
        }
    }

    func appIcon(for hotkey: AppHotkey) -> NSImage {
        NSWorkspace.shared.icon(forFile: hotkey.appPath)
    }
}
