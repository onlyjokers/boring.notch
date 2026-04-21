//
//  BoringHeader.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Defaults
import SwiftUI
import CodeIslandLib
import CodeIslandCore

struct BoringHeader: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @StateObject var tvm = ShelfStateViewModel.shared
    @ObservedObject var ciBridge = CodeIslandBridge.shared
    var body: some View {
        HStack(spacing: 0) {
            HStack {
                if (!tvm.isEmpty || coordinator.alwaysShowTabs || CodeIslandBridge.shared.hasActiveSessions) && Defaults[.boringShelf] {
                    TabSelectionView()
                } else if vm.notchState == .open {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(vm.notchState == .closed ? 0 : 1)
            .blur(radius: vm.notchState == .closed ? 20 : 0)
            .zIndex(2)

            if vm.notchState == .open {
                Rectangle()
                    .fill(NSScreen.screen(withUUID: coordinator.selectedScreenUUID)?.safeAreaInsets.top ?? 0 > 0 ? .black : .clear)
                    .frame(width: vm.closedNotchSize.width)
                    .mask {
                        NotchShape()
                    }
            }

            HStack(spacing: 4) {
                if vm.notchState == .open {
                    if coordinator.currentView == .codeIsland, let state = ciBridge.appState {
                        // CodeIsland header: session count + status
                        CodeIslandHeaderRight(appState: state)
                    } else if isHUDType(coordinator.sneakPeek.type) && coordinator.sneakPeek.show && Defaults[.showOpenNotchHUD] {
                        OpenNotchHUD(type: $coordinator.sneakPeek.type, value: $coordinator.sneakPeek.value, icon: $coordinator.sneakPeek.icon)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    } else {
                        if Defaults[.showMirror] {
                            Button(action: {
                                vm.toggleCameraPreview()
                            }) {
                                Capsule()
                                    .fill(.black)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        Image(systemName: "web.camera")
                                            .foregroundColor(.white)
                                            .padding()
                                            .imageScale(.medium)
                                    }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        if Defaults[.settingsIconInNotch] {
                            Button(action: {
                                DispatchQueue.main.async {
                                    SettingsWindowController.shared.showWindow()
                                }

                            }) {
                                Capsule()
                                    .fill(.black)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        Image(systemName: "gear")
                                            .foregroundColor(.white)
                                            .padding()
                                            .imageScale(.medium)
                                    }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        if Defaults[.showBatteryIndicator] {
                            BoringBatteryView(
                                batteryWidth: 30,
                                isCharging: batteryModel.isCharging,
                                isInLowPowerMode: batteryModel.isInLowPowerMode,
                                isPluggedIn: batteryModel.isPluggedIn,
                                levelBattery: batteryModel.levelBattery,
                                maxCapacity: batteryModel.maxCapacity,
                                timeToFullCharge: batteryModel.timeToFullCharge,
                                isForNotification: false
                            )
                        }
                    }
                }
            }
            .font(.system(.headline, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .opacity(vm.notchState == .closed ? 0 : 1)
            .blur(radius: vm.notchState == .closed ? 20 : 0)
            .zIndex(2)
        }
        .foregroundColor(.gray)
        .environmentObject(vm)
    }

    func isHUDType(_ type: SneakContentType) -> Bool {
        switch type {
        case .volume, .brightness, .backlight, .mic:
            return true
        default:
            return false
        }
    }
}

/// Right-side header content when CodeIsland tab is active
private struct CodeIslandHeaderRight: View {
    var appState: AppState
    @AppStorage(SettingsKey.sessionGroupingMode) private var groupingMode = SettingsDefaults.sessionGroupingMode

    var body: some View {
        HStack(spacing: 8) {
            // ALL / STA / CLI filter tabs
            if appState.sessions.count > 1 {
                HStack(spacing: 1) {
                    ForEach([("all", "ALL"), ("status", "STA"), ("cli", "CLI")], id: \.0) { tag, label in
                        let selected = groupingMode == tag
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { groupingMode = tag }
                        } label: {
                            Text(label)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(selected ? Color(red: 0.3, green: 0.85, blue: 0.4) : .white.opacity(0.3))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(selected ? .white.opacity(0.1) : .clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.1), lineWidth: 1))
            }

            // Pending approval/question badge
            if appState.status == .waitingApproval || appState.status == .waitingQuestion {
                Image(systemName: "bell.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.28))
                    .symbolEffect(.pulse, options: .repeating)
            }

            // Session count: active / total
            HStack(spacing: 1) {
                let active = appState.activeSessionCount
                let total = appState.totalSessionCount
                if active > 0 {
                    Text("\(active)")
                        .foregroundStyle(Color(red: 0.4, green: 1.0, blue: 0.5))
                    Text("/")
                        .foregroundStyle(.white.opacity(0.4))
                }
                Text("\(total)")
                    .foregroundStyle(.white.opacity(0.9))
            }
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
        .padding(.trailing, 6)
    }
}

#Preview {
    BoringHeader().environmentObject(BoringViewModel())
}
