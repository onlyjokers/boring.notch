//
//  CodeIslandNotchView.swift
//  boringNotch
//
//  Embedded view for the CodeIsland tab inside boring.notch's open notch.
//  Uses CodeIsland's actual EmbeddedExpandedContent for identical UI.
//

import SwiftUI
import CodeIslandLib
import CodeIslandCore

struct CodeIslandNotchView: View {
    @ObservedObject private var bridge = CodeIslandBridge.shared
    @State private var isVisible = false

    var body: some View {
        Group {
            if let state = bridge.appState {
                GeometryReader { geo in
                    EmbeddedExpandedContent(appState: state)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onChange(of: state.surface) { _, newSurface in
                            // When surface collapses while the tab is visible, show session list
                            if isVisible && newSurface == .collapsed && !state.sessions.isEmpty {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    state.surface = .sessionList
                                }
                            }
                        }
                        .onAppear {
                            NSLog("[CodeIslandNotchView] GeometryReader size: \(geo.size)")
                        }
                        .onChange(of: geo.size) { _, newSize in
                            NSLog("[CodeIslandNotchView] Size changed: \(newSize)")
                        }
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isVisible = true
            if let state = bridge.appState, state.surface == .collapsed {
                withAnimation(NotchAnimation.open) {
                    state.surface = .sessionList
                }
            }
        }
        .onDisappear {
            isVisible = false
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 24))
                .foregroundStyle(.gray.opacity(0.5))
            Text("No AI sessions")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray.opacity(0.6))
        }
    }
}
