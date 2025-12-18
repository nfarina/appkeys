# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Appkeys is a macOS menu bar app that assigns global hotkeys to applications. It's a pure Swift/SwiftUI project with no external dependencies.

## Build Commands

```bash
# Build the app
xcodebuild -project Appkeys.xcodeproj -scheme Appkeys build

# Build for release
xcodebuild -project Appkeys.xcodeproj -scheme Appkeys -configuration Release build

# Clean build
xcodebuild -project Appkeys.xcodeproj -scheme Appkeys clean
```

The app can also be built and run directly from Xcode.

## Architecture

### Core Components

- **AppkeysApp.swift** - Entry point. Sets up menu bar extra and AppDelegate for hotkey registration
- **HotkeyManager.swift** - Singleton that registers global hotkeys using Carbon framework's `RegisterEventHotKey`
- **HotkeyStore.swift** - Observable state management with JSON persistence to `~/Library/Application Support/Appkeys/hotkeys.json`
- **KeyRecorderView.swift** - NSView subclass wrapped in SwiftUI for capturing keyboard input
- **SettingsView.swift** - Main UI with hotkey list, file picker for apps
- **AppHotkey.swift** - Data model (Codable) with key code to display string mapping

### Key Technical Details

- **Menu bar only app**: `LSUIElement=true` in Info.plist hides dock icon
- **Global hotkeys**: Uses Carbon framework (not AppKit) for system-level hotkey capture
- **Modifier requirement**: Hotkeys require at least one modifier key, except for function keys
- **App launching**: Uses `NSWorkspace.shared.openApplication` to launch or bring apps to front
