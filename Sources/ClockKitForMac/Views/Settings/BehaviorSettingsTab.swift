//
//  BehaviorSettingsTab.swift
//  ClockKitForMac
//
//  項目定義 ⑰(メニューバー常駐)・⑱(ウィンドウ前面固定)。
//
import SwiftUI

struct BehaviorSettingsTab: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Form {
            Section("常駐・表示") {
                // ⑰ メニューバー常駐
                Toggle("メニューバーに常駐する", isOn: menuBarBinding)

                // ⑱ ウィンドウ前面固定
                Toggle("ウィンドウを常に最前面に表示する", isOn: floatWindowBinding)
            }
        }
        .padding(20)
    }

    private var menuBarBinding: Binding<Bool> {
        Binding(
            get: { env.settings.current.menuBarEnabled },
            set: { newValue in env.settings.update { $0.menuBarEnabled = newValue } }
        )
    }

    private var floatWindowBinding: Binding<Bool> {
        Binding(
            get: { env.settings.current.floatWindowEnabled },
            set: { newValue in env.settings.update { $0.floatWindowEnabled = newValue } }
        )
    }
}
