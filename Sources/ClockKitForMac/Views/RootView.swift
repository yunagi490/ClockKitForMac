//
//  RootView.swift
//  ClockKitForMac
//
//  SCR-001 のコンテナ。初回起動時はオンボーディング（SCR-004）を、
//  2回目以降は直接ナイトスタンド メイン画面を表示する
//  （SCR-SPEC-001 画面遷移定義 No.1, No.3）。
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        Group {
            if env.settings.current.hasCompletedOnboarding {
                NightstandView()
            } else {
                OnboardingView()
            }
        }
        // NSWindow への参照を取得し、ClockWindowController に設定する。
        .background(
            WindowAccessor { window in
                env.windowController.attach(to: window, floatWindowEnabled: env.settings.current.floatWindowEnabled)
            }
        )
    }
}
