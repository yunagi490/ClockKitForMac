//
//  ClockKitForMacApp.swift
//  ClockKitForMac
//
//  アプリのエントリポイント。SwiftUI の Window / Settings シーンと
//  NSApplicationDelegateAdaptor を組み合わせ、SwiftUI + AppKit の
//  ハイブリッド構成（基本設計書 BD-001 アーキテクチャ節）を実現する。
//
import SwiftUI

@main
struct ClockKitForMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // SCR-001: ナイトスタンド メイン画面（単一インスタンスのウィンドウ）
        Window("ClockKit for Mac", id: "main") {
            RootView()
                .environmentObject(appDelegate.environment)
        }
//        .windowResizability(.contentSize)
        .defaultSize(width: 1024, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        // SCR-002: 設定画面（⌘, で表示）
        Settings {
            SettingsView()
                .environmentObject(appDelegate.environment)
        }
    }
}
