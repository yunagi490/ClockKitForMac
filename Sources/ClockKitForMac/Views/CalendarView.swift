//
//  CalendarView.swift
//  ClockKitForMac
//
//  SCR-001 右ペイン。項目定義 ⑦〜⑩（カレンダー年月ナビ／曜日ヘッダー／
//  日付グリッド／凡例）＋ 次の予定エリアを実装する。
//  日付グリッドの"次の予定"表示欄はDD-001 MOD-009/CalendarViewModel.nextEvent
//  に定義があるが、SCR-SPEC-001の項番一覧には明記がないため、
//  レイアウト仕様書の意図（下段に次の予定を表示）を汲んで追加している。
//
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var env: AppEnvironment

    private var calendar: CalendarViewModel { env.calendarViewModel }
    private var theme: ThemeManager { env.themeManager }

    private static let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ⑦ カレンダー年月ナビ
            HStack {
                Button {
                    calendar.navigateMonth(offset: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(calendar.isNavigationOutOfRange(offset: -1))

                Spacer()

                Text(monthTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.textColor)
                    .onTapGesture {
                        // タイトルタップで当月に戻る（項目定義 ⑦ 補足）
                        calendar.navigateMonth(offset: -distanceToCurrentMonth)
                    }

                Spacer()

                Button {
                    calendar.navigateMonth(offset: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(calendar.isNavigationOutOfRange(offset: 1))
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.textColor)

            // ⑧ 曜日ヘッダー（日曜=赤、土曜=青）
            HStack(spacing: 0) {
                ForEach(Array(Self.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(weekdayColor(for: index))
                }
            }

            // ⑨ 日付グリッド（6週×7日）
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(calendar.calendarDays) { day in
                    DayCell(day: day, textColor: theme.textColor)
                }
            }

            // ⑩ 凡例
            HStack(spacing: 16) {
                Label("今日", systemImage: "square.fill")
                    .foregroundStyle(theme.textColor)
                Label("予定あり", systemImage: "circle.fill")
                    .foregroundStyle(.blue)
            }
            .font(.system(size: 11))
            .labelStyle(.titleAndIcon)

            Divider()
                .background(Color.white.opacity(0.1))

            // 次の予定エリア（DD-001 MOD-009 nextEvent）
            NextEventView()
        }
        .opacity(calendar.fallbackMode ? 0.6 : 1.0)
        .overlay {
            if calendar.fallbackMode {
                fallbackNotice
            }
        }
    }

    private var monthTitle: String {
        guard let year = calendar.displayMonth.year, let month = calendar.displayMonth.month else {
            return "----年--月"
        }
        return "\(year)年\(month)月"
    }

    private var distanceToCurrentMonth: Int {
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        guard let y1 = calendar.displayMonth.year, let m1 = calendar.displayMonth.month,
              let y2 = now.year, let m2 = now.month else { return 0 }
        return (y1 - y2) * 12 + (m1 - m2)
    }

    private func weekdayColor(for index: Int) -> Color {
        switch index {
        case 0: return .red.opacity(0.8)   // 日曜
        case 6: return .blue.opacity(0.8)  // 土曜
        default: return theme.textColor.opacity(0.6)
        }
    }

    @ViewBuilder
    private var fallbackNotice: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 24))
            Text(calendar.isRestricted
                 ? "ポリシーによりカレンダーへのアクセスが制限されています"
                 : "カレンダーへのアクセスが許可されていません")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
            if !calendar.isRestricted {
                Text("設定 > カレンダー から許可できます")
                    .font(.system(size: 11))
                    .opacity(0.7)
            }
        }
        .padding()
        .foregroundStyle(theme.textColor)
        .background(.black.opacity(0.4))
        .cornerRadius(8)
    }
}

/// カレンダーグリッドの1マス。今日はアンバーハイライト、
/// 予定ありは青ドット、前後月の端数日は薄表示。
private struct DayCell: View {
    let day: CalendarDay
    let textColor: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(day.day)")
                .font(.system(size: 13, weight: day.isToday ? .bold : .regular))
                .frame(width: 24, height: 24)
                .background(
                    Circle().fill(day.isToday ? textColor : .clear)
                )
                .foregroundStyle(day.isToday ? .black : (day.isCurrentMonth ? textColor : textColor.opacity(0.3)))

            Circle()
                .fill(day.hasEvent ? Color.blue : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(Text(accessibilityText))
    }

    private var accessibilityText: String {
        var text = "\(day.day)日"
        if day.isToday { text += "、今日" }
        if day.hasEvent { text += "、予定あり" }
        return text
    }
}
