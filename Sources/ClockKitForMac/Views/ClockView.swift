//
//  ClockView.swift
//  ClockKitForMac
//
//  SCR-001 左ペイン。項目定義 ①〜⑥（曜日・日付／時刻／AM-PM／
//  コロン点滅トグル／前面固定トグル／設定ボタン）を実装する。
//
import SwiftUI
import AppKit

struct ClockView: View {
    @EnvironmentObject private var env: AppEnvironment

    private var clock: ClockViewModel { env.clockViewModel }
    private var theme: ThemeManager { env.themeManager }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // ① 曜日・日付
            Text(clock.dateString)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(theme.textColor.opacity(0.85))
                .accessibilityLabel(Text(clock.dateString))

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    // ② 時刻（コロン点滅オプション対応）
                    Text(displayedTimeString)
                        .font(theme.currentFont)
                        .foregroundStyle(theme.textColor)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.2)
                        .accessibilityLabel(Text("現在時刻 \(clock.timeString)"))

                    // ③ AM/PM（12hモード時のみ、showAmPm設定に従う）
                    if env.settings.current.timeFormat == .hour12 && env.settings.current.showAmPm {
                        Text(clock.amPmString)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(theme.textColor.opacity(0.7))
                    }
                }
            }

            Spacer()

            // ④⑤⑥ 操作ボタン群
            HStack(spacing: 16) {
                Toggle(isOn: colonBlinkBinding) {
                    Label("点滅", systemImage: colonBlinkBinding.wrappedValue ? "circle.fill" : "circle")
                }
                .toggleStyle(.button)
                .help("コロンを0.5秒ごとに点滅させる")

                Toggle(isOn: floatWindowBinding) {
                    Label("前面固定", systemImage: "pin.fill")
                }
                .toggleStyle(.button)
                .help("ウィンドウを常に最前面に表示する")

                Spacer()

                Button {
                    // macOS 13 互換のため openSettings(macOS14+) ではなく
                    // showSettingsWindow: アクションを直接送出する。
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Label("設定を開く", systemImage: "gearshape")
                }
                .help("設定画面を開く（⌘,）")
            }
            .tint(theme.textColor)
        }
    }

    /// コロン点滅が有効な場合、非表示タイミングでコロンを空白に置換する。
    private var displayedTimeString: String {
        guard env.settings.current.colonBlinkEnabled, !clock.colonVisible else {
            return clock.timeString
        }
        return clock.timeString.replacingOccurrences(of: ":", with: " ")
    }

    private var colonBlinkBinding: Binding<Bool> {
        Binding(
            get: { env.settings.current.colonBlinkEnabled },
            set: { newValue in env.settings.update { $0.colonBlinkEnabled = newValue } }
        )
    }

    private var floatWindowBinding: Binding<Bool> {
        Binding(
            get: { env.settings.current.floatWindowEnabled },
            set: { newValue in env.settings.update { $0.floatWindowEnabled = newValue } }
        )
    }
}
