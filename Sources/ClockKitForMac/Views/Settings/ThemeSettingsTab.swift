//
//  ThemeSettingsTab.swift
//  ClockKitForMac
//
//  テーマ選択 ＋ 項目定義 ⑫(フォント名)・⑬(フォントサイズ)。
//  カスタムテーマ選択時は clockTextColor / clockBgColor の色選択も行う。
//
import SwiftUI
import AppKit

struct ThemeSettingsTab: View {
    @EnvironmentObject private var env: AppEnvironment

    /// "SF Mono" / "Helvetica Neue" を優先し、以降はシステムに
    /// インストールされているフォントファミリーを列挙する（項目定義 ⑫）。
    private var fontFamilies: [String] {
        let priority = ["SF Mono", "Helvetica Neue"]
        let system = NSFontManager.shared.availableFontFamilies.sorted()
        let rest = system.filter { !priority.contains($0) }
        return priority.filter { NSFontManager.shared.font(withFamily: $0, traits: [], weight: 5, size: 12) != nil } + rest
    }

    var body: some View {
        Form {
            Section("テーマ") {
                Picker("テーマ", selection: themeBinding) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.menu)

                if env.settings.current.clockTheme == .custom {
                    ColorPicker("テキスト色", selection: customTextColorBinding)
                    ColorPicker("背景色", selection: customBgColorBinding)
                }
            }

            Section("フォント") {
                // ⑫ フォント名（ドロップダウン）
                Picker("フォント名", selection: fontNameBinding) {
                    ForEach(fontFamilies, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)

                // ⑬ フォントサイズ（スライダー、24〜256pt）
                HStack {
                    Text("サイズ")
                    Slider(value: fontSizeBinding, in: 24...256, step: 1)
                    Text("\(Int(env.settings.current.fontSize))pt")
                        .monospacedDigit()
                        .frame(width: 48, alignment: .trailing)
                }
            }
        }
        .padding(20)
    }

    private var themeBinding: Binding<Theme> {
        Binding(
            get: { env.settings.current.clockTheme },
            set: { newValue in
                env.settings.update { $0.clockTheme = newValue }
                env.themeManager.applyTheme(newValue)
            }
        )
    }

    private var fontNameBinding: Binding<String> {
        Binding(
            get: { env.settings.current.fontName },
            set: { newValue in
                env.settings.update { $0.fontName = newValue }
                env.themeManager.resolveFont(name: newValue, size: env.settings.current.fontSize)
            }
        )
    }

    private var fontSizeBinding: Binding<Double> {
        Binding(
            get: { env.settings.current.fontSize },
            set: { newValue in
                env.settings.update { $0.fontSize = newValue }
                env.themeManager.resolveFont(name: env.settings.current.fontName, size: newValue)
            }
        )
    }

    private var customTextColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: env.settings.current.clockTextColor) },
            set: { newValue in
                env.settings.update { $0.clockTextColor = newValue.hexString }
                env.themeManager.applyTheme(.custom)
            }
        )
    }

    private var customBgColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: env.settings.current.clockBgColor) },
            set: { newValue in
                env.settings.update { $0.clockBgColor = newValue.hexString }
                env.themeManager.applyTheme(.custom)
            }
        )
    }
}
