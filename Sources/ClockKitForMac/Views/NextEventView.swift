//
//  NextEventView.swift
//  ClockKitForMac
//
//  「次の予定」表示エリア。DD-001 MOD-009(NextEventFetcher) の
//  formatEventTime() 仕様（今日/明日/M月d日/終日の分岐）に準拠する。
//
import SwiftUI

struct NextEventView: View {
    @EnvironmentObject private var env: AppEnvironment

    private var calendar: CalendarViewModel { env.calendarViewModel }
    private var theme: ThemeManager { env.themeManager }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("次の予定")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.textColor.opacity(0.6))

            if calendar.fallbackMode {
                EmptyView()
            } else if let event = calendar.nextEvent {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(event.calendarColor)
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textColor)
                            .lineLimit(1)

                        Text(NextEventFetcher.formatEventTime(event))
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textColor.opacity(0.7))

                        if let location = event.location {
                            Label(location, systemImage: "mappin.and.ellipse")
                                .font(.system(size: 11))
                                .foregroundStyle(theme.textColor.opacity(0.6))
                        }
                    }
                }
            } else {
                Text("予定なし")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textColor.opacity(0.5))
            }
        }
    }
}
