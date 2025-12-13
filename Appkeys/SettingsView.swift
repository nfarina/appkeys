//
//  SettingsView.swift
//  Appkeys
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var store: HotkeyStore
    var onHotkeyChanged: ((AppHotkey) -> Void)?
    var onRequestReopen: (() -> Void)?

    @State private var isHoveringAdd = false
    @State private var isHoveringQuit = false

    private let minHeight: CGFloat = 400
    private let rowHeight: CGFloat = 48  // Approximate height per row
    private let headerFooterHeight: CGFloat = 110  // Header + footer + dividers

    private var idealHeight: CGFloat {
        if store.hotkeys.isEmpty {
            return minHeight
        }
        let contentHeight = headerFooterHeight + (CGFloat(store.hotkeys.count) * rowHeight)
        let maxHeight = (NSScreen.main?.visibleFrame.height ?? 800) - 50
        return min(max(contentHeight, minHeight), maxHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Appkeys")
                    .font(.headline)
                Spacer()
                Button(action: addApp) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(isHoveringAdd ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .onHover { hovering in
                    isHoveringAdd = hovering
                }
            }
            .padding()

            Divider()

            // List of hotkeys
            if store.hotkeys.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No hotkeys configured")
                        .foregroundColor(.secondary)
                    Text("Click + to add an app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(store.hotkeys.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }) { hotkey in
                        HotkeyRow(
                            hotkey: hotkey,
                            icon: store.appIcon(for: hotkey),
                            onUpdate: { updated in
                                store.update(updated)
                                onHotkeyChanged?(updated)
                            },
                            onDelete: {
                                store.remove(hotkey)
                                onHotkeyChanged?(hotkey)
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            // Footer
            HStack {
                Button("Quit Appkeys") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(isHoveringQuit ? .primary : .secondary)
                .onHover { hovering in
                    isHoveringQuit = hovering
                }
                Spacer()
            }
            .padding()
        }
        .frame(width: 300, height: idealHeight)
    }

    private func addApp() {
        // Dismiss the menu bar panel first to avoid focus issues
        if let panel = NSApp.windows.first(where: { $0.isVisible && $0.className.contains("MenuBarExtra") }) {
            panel.orderOut(nil)
        }

        // Small delay to ensure panel is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let openPanel = NSOpenPanel()
            openPanel.allowedContentTypes = [UTType.application]
            openPanel.allowsMultipleSelection = false
            openPanel.directoryURL = URL(fileURLWithPath: "/Applications")

            // Ensure the open panel gets focus
            NSApp.activate(ignoringOtherApps: true)

            if openPanel.runModal() == .OK, let url = openPanel.url {
                store.addApp(at: url)
                // Reopen the menu after selecting
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onRequestReopen?()
                }
            }
        }
    }
}

struct HotkeyRow: View {
    var hotkey: AppHotkey
    var icon: NSImage
    var onUpdate: (AppHotkey) -> Void
    var onDelete: () -> Void

    @State private var keyCode: UInt32?
    @State private var modifiers: UInt32
    @State private var isHoveringDelete = false

    init(hotkey: AppHotkey, icon: NSImage, onUpdate: @escaping (AppHotkey) -> Void, onDelete: @escaping () -> Void) {
        self.hotkey = hotkey
        self.icon = icon
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._keyCode = State(initialValue: hotkey.keyCode)
        self._modifiers = State(initialValue: hotkey.modifiers)
    }

    var body: some View {
        HStack(spacing: 12) {
            // App icon
            Image(nsImage: icon)
                .resizable()
                .frame(width: 32, height: 32)

            // App name
            Text(hotkey.appName)
                .lineLimit(1)

            Spacer()

            // Hotkey recorder
            KeyRecorderView(keyCode: $keyCode, modifiers: $modifiers)
                .onChange(of: keyCode) { _, newValue in
                    var updated = hotkey
                    updated.keyCode = newValue
                    updated.modifiers = modifiers
                    onUpdate(updated)
                }
                .onChange(of: modifiers) { _, newValue in
                    var updated = hotkey
                    updated.keyCode = keyCode
                    updated.modifiers = newValue
                    onUpdate(updated)
                }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(isHoveringDelete ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringDelete = hovering
            }
        }
        .padding(.vertical, 4)
    }
}
