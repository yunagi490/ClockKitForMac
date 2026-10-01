//
//  OnboardingView.swift
//  ClockKitForMac
//
//  SCR-004: 初回起動時のみ表示するオンボーディングウィザード。
//
//  [実装メモ] 基本設計書(BD-001)・画面仕様書(SCR-SPEC-001)は
//  「表示設定→テーマ設定」の2ステップと記載しているが、結合テスト仕様書
//  (IT-SPEC-001 SN-002, IT-SN002-01〜03)はStep1/Step2/Step3（カレンダー
//  権限）の3ステップ構成を前提としたテストケースになっている。
//  後工程であるIT仕様書の記載がより具体的かつ新しいと判断し、
//  本実装では「①表示形式 → ②テーマ → ③カレンダー権限」の
//  3ステップで実装する。
//
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var step: Int = 1
    @State private var isRequestingAccess = false

    private let totalSteps = 3

    var body: some View {
        ZStack {
            env.themeManager.backgroundColor.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                stepIndicator

                Group {
                    switch step {
                    case 1: displayFormatStep
                    case 2: themeStep
                    default: calendarPermissionStep
                    }
                }
                .frame(maxWidth: 480)

                Spacer()

                navigationButtons
            }
            .padding(48)
        }
        .foregroundStyle(env.themeManager.textColor)
        .frame(minWidth: 640, minHeight: 400)
    }

    // MARK: - ステップインジケータ

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { i in
                Circle()
                    .fill(i <= step ? env.themeManager.textColor : env.themeManager.textColor.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Step 1: 表示形式

    private var displayFormatStep: some View {
        VStack(spacing: 20) {
            Text("時刻の表示形式を選んでください")
                .font(.title2.bold())

            Picker("表示形式", selection: timeFormatBinding) {
                ForEach(TimeFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Step 2: テーマ

    private var themeStep: some View {
        VStack(spacing: 20) {
            Text("テーマを選んでください")
                .font(.title2.bold())

            Picker("テーマ", selection: themeBinding) {
                ForEach(Theme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Step 3: カレンダー権限

    private var calendarPermissionStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))

            Text("カレンダーへのアクセスを許可しますか？")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("許可すると、月間カレンダーに予定のドット表示と「次の予定」が表示されます。後から設定でいつでも変更できます。")
                .font(.body)
                .multilineTextAlignment(.center)
                .opacity(0.8)

            if calendarAccessAlreadyGranted {
                Label("カレンダーへのアクセスが許可されています", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    requestCalendarAccess()
                } label: {
                    if isRequestingAccess {
                        ProgressView()
                    } else {
                        Text("カレンダーへのアクセスを許可")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequestingAccess)
            }
        }
    }

    private var calendarAccessAlreadyGranted: Bool {
        !env.calendarViewModel.fallbackMode
    }

    private func requestCalendarAccess() {
        isRequestingAccess = true
        Task {
            _ = await env.calendarViewModel.requestCalendarAccess()
            isRequestingAccess = false
        }
    }

    // MARK: - ナビゲーション

    private var navigationButtons: some View {
        HStack {
            if step > 1 {
                Button("戻る") { step -= 1 }
            }

            Spacer()

            if step < totalSteps {
                Button("次へ") { step += 1 }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("完了") { completeOnboarding() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func completeOnboarding() {
        env.settings.update { $0.hasCompletedOnboarding = true }
    }

    // MARK: - Bindings

    private var timeFormatBinding: Binding<TimeFormat> {
        Binding(
            get: { env.settings.current.timeFormat },
            set: { newValue in env.settings.update { $0.timeFormat = newValue } }
        )
    }

    private var themeBinding: Binding<Theme> {
        Binding(
            get: { env.settings.current.clockTheme },
            set: { newValue in env.settings.update { $0.clockTheme = newValue } }
        )
    }
}
