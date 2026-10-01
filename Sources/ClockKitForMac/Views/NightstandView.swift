//
//  NightstandView.swift
//  ClockKitForMac
//
//  SCR-001: ナイトスタンド メイン画面。左ペイン：大型デジタル時計、
//  右ペイン：月間カレンダー。SCR-SPEC-001 レイアウト仕様に準拠。
//  カレンダー非表示設定時はシングルペイン表示になる（入力チェック仕様 No.3）。
//
import SwiftUI

struct NightstandView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        ZStack {
            env.themeManager.backgroundColor
                .ignoresSafeArea()

            HStack(spacing: 0) {
                ClockView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if env.settings.current.calendarVisible {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    CalendarView()
                        .frame(width: 360)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(32)
        }
        .frame(minWidth: 640, minHeight: 400)
    }
}
