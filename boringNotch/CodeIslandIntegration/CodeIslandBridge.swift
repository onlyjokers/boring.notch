//
//  CodeIslandBridge.swift
//  boringNotch
//
//  Manages CodeIsland's HookServer lifecycle and exposes AppState for SwiftUI.
//

import Combine
import SwiftUI
import CodeIslandLib
import CodeIslandCore

@MainActor
final class CodeIslandBridge: ObservableObject {
    static let shared = CodeIslandBridge()

    // MARK: - State

    private(set) var appState: AppState?
    private var hookServer: HookServer?
    private var isRunning = false
    private var observationTask: Task<Void, Never>?

    // Published properties for boring.notch's ContentView (chin width, wing display)
    @Published var hasActiveSessions: Bool = false
    @Published var isAIWorking: Bool = false
    @Published var sessionCount: Int = 0
    @Published var activeToolName: String?
    @Published var activeSource: String = "claude"
    @Published var needsAttention: Bool = false
    @Published var agentStatus: AgentStatus = .idle

    private init() {}

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }

        let state = AppState()
        self.appState = state

        let standaloneRunning = isStandaloneAppRunning()

        if !standaloneRunning {
            // Remove stale socket from previous crash/run
            unlink(HookServer.socketPath)

            let server = HookServer(appState: state)
            server.start()
            self.hookServer = server

            if ConfigInstaller.install() {
                NSLog("[CodeIslandBridge] Hooks installed")
            }
        } else {
            NSLog("[CodeIslandBridge] Standalone CodeIsland running, using shared session data")
        }

        state.startSessionDiscovery()
        isRunning = true

        startObservation()
    }

    func stop() {
        observationTask?.cancel()
        observationTask = nil
        appState?.stopSessionDiscovery()
        appState?.saveSessions()
        hookServer?.stop()
        hookServer = nil
        appState = nil
        isRunning = false
    }

    // MARK: - Observation

    private func startObservation() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, let state = self.appState else { return }

                self.syncState(from: state)

                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = state.sessions
                        _ = state.activeSessionCount
                        _ = state.status
                        _ = state.primarySource
                        _ = state.pendingPermission
                        _ = state.pendingQuestion
                        _ = state.rotatingSessionId
                        _ = state.activeSessionId
                        _ = state.surface
                    } onChange: {
                        continuation.resume()
                    }
                }
            }
        }
    }

    private func syncState(from state: AppState) {
        let newSessionCount = state.activeSessionCount
        let newHasActive = !state.sessions.isEmpty
        let newStatus = state.status
        let newSource = state.primarySource
        let newNeedsAttention = state.pendingPermission != nil || state.pendingQuestion != nil

        let displaySessionId = state.rotatingSessionId ?? state.activeSessionId ?? state.sessions.keys.sorted().first
        let displaySession = displaySessionId.flatMap { state.sessions[$0] }
        let newTool = displaySession?.currentTool

        if sessionCount != newSessionCount { sessionCount = newSessionCount }
        if hasActiveSessions != newHasActive { hasActiveSessions = newHasActive }
        if agentStatus != newStatus { agentStatus = newStatus }
        if activeSource != newSource { activeSource = newSource }
        if activeToolName != newTool { activeToolName = newTool }

        let newWorking = newStatus == .processing || newStatus == .waitingApproval || newStatus == .waitingQuestion
        if isAIWorking != newWorking { isAIWorking = newWorking }

        if newNeedsAttention && !needsAttention {
            NotificationCenter.default.post(name: .codeIslandNeedsAttention, object: nil)
        }
        if needsAttention != newNeedsAttention { needsAttention = newNeedsAttention }
    }

    // MARK: - Helpers

    private func isStandaloneAppRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.codeisland" || $0.localizedName == "CodeIsland"
        }
    }
}

extension Notification.Name {
    static let codeIslandNeedsAttention = Notification.Name("codeIslandNeedsAttention")
}
