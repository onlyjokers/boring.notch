//
//  CodeIslandSettingsTab.swift
//  boringNotch
//
//  Settings panel for CodeIsland integration within boring.notch.
//  Opens CodeIsland's full settings window for complete configuration.
//

import SwiftUI
import CodeIslandLib
import CodeIslandCore

struct CodeIslandSettingsTab: View {
    @ObservedObject private var bridge = CodeIslandBridge.shared
    @AppStorage("maxVisibleSessions") private var maxVisibleSessions = 5

    var body: some View {
        Form {
            Section("Hook Status") {
                HStack {
                    Text("Server")
                    Spacer()
                    if bridge.appState != nil {
                        Text("Running")
                            .foregroundStyle(.green)
                    } else {
                        Text("Stopped")
                            .foregroundStyle(.red)
                    }
                }
                HStack {
                    Text("Active sessions")
                    Spacer()
                    Text("\(bridge.sessionCount)")
                }
            }

            Section("Display") {
                Stepper("Max visible sessions: \(maxVisibleSessions)", value: $maxVisibleSessions, in: 2...10)
            }

            Section("Configuration") {
                Button("Open CodeIsland Settings...") {
                    CodeIslandLib.SettingsWindowController.shared.show()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
    }
}
