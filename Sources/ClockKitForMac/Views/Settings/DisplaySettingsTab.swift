//
//  DisplaySettingsTab.swift
//  ClockKitForMac
//
//  項目定義 ⑪(時刻フォーマット)・⑭(コロン点滅)・⑮(AM/PMラベル表示)。
//
import SwiftUI

struct DisplaySettingsTab: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Form {
            Section("時刻フォーマット") {
                // ⑪ 時刻フォーマット（ラジオボタン）
                Picker("", selection: timeFormatBinding) {
                    ForEach(TimeFormat.allCases) { format in
                        Text(previewLabel(for: format)).tag(format)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            Section("オプション") {
                // ⑭ コロン点滅
                Toggle("コロンを0.5秒ごとに点滅させる", isOn: colonBlinkBinding)

                // ⑮ AM/PMラベル表示（12hモード時のみ有効）
                Toggle("AM/PMラベルを表示する（12h時のみ有効）", isOn: showAmPmBinding)
                    .disabled(env.settings.current.timeFormat != .hour12)
            }
        }
        .padding(20)
    }

    private func previewLabel(for format: TimeFormat) -> String {
        switch format {
        case .hour24: return "24時間表示（例：23:45:12）"
        case .hour12: return "12時間表示（例：11:45:12 PM）"
        }
    }

    private var timeFormatBinding: Binding<TimeFormat> {
        Binding(
            get: { env.settings.current.timeFormat },
            set: { newValue in
                env.settings.update { $0.timeFormat = newValue }
                env.clockViewModel.updateFormat()
            }
        )
    }

    private var colonBlinkBinding: Binding<Bool> {
        Binding(
            get: { env.settings.current.colonBlinkEnabled },
            set: { newValue in env.settings.update { $0.colonBlinkEnabled = newValue } }
        )
    }

    private var showAmPmBinding: Binding<Bool> {
        Binding(
            get: { env.settings.current.showAmPm },
            set: { newValue in env.settings.update { $0.showAmPm = newValue } }
        )
    }
}
