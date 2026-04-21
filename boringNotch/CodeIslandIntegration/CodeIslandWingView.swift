//
//  CodeIslandWingView.swift
//  boringNotch
//
//  Wing views shown when notch is closed and AI is working.
//  Uses CodeIsland's real compact wing views for identical UI.
//

import SwiftUI
import CodeIslandLib
import CodeIslandCore

struct CodeIslandLeftWing: View {
    @ObservedObject private var bridge = CodeIslandBridge.shared
    let height: CGFloat

    var body: some View {
        if let state = bridge.appState {
            EmbeddedCompactLeftWing(appState: state, mascotSize: max(18, height - 8))
        }
    }
}

struct CodeIslandRightWing: View {
    @ObservedObject private var bridge = CodeIslandBridge.shared
    let height: CGFloat

    var body: some View {
        if let state = bridge.appState {
            EmbeddedCompactRightWing(appState: state)
        }
    }
}
