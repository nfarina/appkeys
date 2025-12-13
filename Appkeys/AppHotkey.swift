//
//  AppHotkey.swift
//  Appkeys
//

import Foundation
import Carbon

struct AppHotkey: Codable, Identifiable, Equatable {
    let id: UUID
    var appPath: String
    var keyCode: UInt32?  // nil means no hotkey set
    var modifiers: UInt32  // Carbon modifier flags

    init(id: UUID = UUID(), appPath: String, keyCode: UInt32? = nil, modifiers: UInt32 = 0) {
        self.id = id
        self.appPath = appPath
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    var appName: String {
        (appPath as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
    }

    var appURL: URL {
        URL(fileURLWithPath: appPath)
    }

    var hasHotkey: Bool {
        keyCode != nil
    }

    var hotkeyDisplayString: String {
        guard let kc = keyCode else { return "Click to record" }

        var parts: [String] = []

        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }

        if let keyString = keyCodeToString(kc) {
            parts.append(keyString)
        }

        return parts.joined()
    }
}

// Map key codes to display strings
func keyCodeToString(_ keyCode: UInt32) -> String? {
    let mapping: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
        38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
        45: "N", 46: "M", 47: ".", 50: "`",
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
        101: "F9", 103: "F11", 105: "F13", 107: "F14", 109: "F10",
        111: "F12", 113: "F15", 118: "F4", 119: "F2", 120: "F1",
        121: "F16", 122: "F17", 123: "←", 124: "→", 125: "↓", 126: "↑"
    ]
    return mapping[keyCode]
}
