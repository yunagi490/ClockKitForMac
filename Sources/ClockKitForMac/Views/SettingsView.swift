//
//  SettingsView.swift
//  ClockKitForMac
//
//  SCR-002: 設定画面。⌘, で表示されるタブ型ウィンドウ（480×380pt）。
//  SCR-SPEC-001 レイアウト仕様（表示／テーマ／カレンダー／動作 の4タブ）
//  に準拠する。
//
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            DisplaySettingsTab()
                .tabItem { Label("表示", systemImage: "clock") }

            ThemeSettingsTab()
                .tabItem { Label("テーマ", systemImage: "paintbrush") }

            CalendarSettingsTab()
                .tabItem { Label("カレンダー", systemImage: "calendar") }

            BehaviorSettingsTab()
                .tabItem { Label("動作", systemImage: "gearshape") }
        }
        .frame(width: 480, height: 380)
    }
}
