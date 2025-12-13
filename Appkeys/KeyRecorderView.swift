//
//  KeyRecorderView.swift
//  Appkeys
//

import SwiftUI
import AppKit
import Carbon

struct KeyRecorderView: View {
    @Binding var keyCode: UInt32?
    @Binding var modifiers: UInt32
    @State private var isRecording = false
    @State private var isHovering = false

    var displayString: String {
        if isRecording {
            return "Press key…"
        }
        guard let kc = keyCode else {
            return "Record"
        }
        return hotkeyDisplayString(keyCode: kc, modifiers: modifiers)
    }

    var body: some View {
        KeyRecorderNSView(
            keyCode: $keyCode,
            modifiers: $modifiers,
            isRecording: $isRecording
        )
        .frame(width: 80, height: 24)
        .background(isRecording ? Color.accentColor.opacity(0.2) : (isHovering ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.1)))
        .cornerRadius(4)
        .overlay(
            Text(displayString)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(isRecording ? .accentColor : (keyCode == nil ? .secondary : .primary))
                .allowsHitTesting(false)  // Let clicks pass through to NSView
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private func hotkeyDisplayString(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if let key = keyCodeToString(keyCode) { parts.append(key) }
        return parts.joined()
    }
}

struct KeyRecorderNSView: NSViewRepresentable {
    @Binding var keyCode: UInt32?
    @Binding var modifiers: UInt32
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyRecorded = { code, mods in
            keyCode = code
            modifiers = mods
            isRecording = false
        }
        view.onRecordingStarted = {
            isRecording = true
        }
        view.onRecordingCancelled = {
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.syncRecordingState(isRecording)
    }
}

class KeyCaptureView: NSView {
    var onKeyRecorded: ((UInt32, UInt32) -> Void)?
    var onRecordingStarted: (() -> Void)?
    var onRecordingCancelled: (() -> Void)?

    private var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    func syncRecordingState(_ recording: Bool) {
        if recording && !isRecording {
            isRecording = true
            DispatchQueue.main.async { [weak self] in
                self?.window?.makeFirstResponder(self)
            }
        } else if !recording && isRecording {
            isRecording = false
        }
    }

    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            isRecording = true
            onRecordingStarted?()
            DispatchQueue.main.async { [weak self] in
                self?.window?.makeFirstResponder(self)
            }
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }

        // Escape cancels
        if event.keyCode == 53 {
            isRecording = false
            onRecordingCancelled?()
            return
        }

        // Need at least one modifier (except for function keys)
        let mods = carbonModifiers(from: event.modifierFlags)
        let isFunctionKey = (event.keyCode >= 96 && event.keyCode <= 122) ||
                           (event.keyCode >= 122 && event.keyCode <= 127)  // Extended F-keys

        if mods == 0 && !isFunctionKey {
            // Ignore keys without modifiers (except F-keys)
            return
        }

        isRecording = false
        onKeyRecorded?(UInt32(event.keyCode), mods)
    }

    override func flagsChanged(with event: NSEvent) {
        // Could show modifier preview here if desired
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        return mods
    }
}
