//
//  NextEventFetcher.swift
//  ClockKitForMac
//
//  MOD-009: 選択カレンダーから現在時刻以降の最初の EKEvent を
//  取得する純粋関数モジュール。DD-001 MOD-009 に準拠。
//  関連: FRQ-014 / UT-MOD009-*（表示文字列の仕様はこのテストケースに準拠）
//
import EventKit
import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "NextEventFetcher")

enum NextEventFetcher {

    /// 先読み期間内で開始時刻が最も近い予定を返す。終日イベントも対象。
    /// - Parameters:
    ///   - store: EventKit ストア。
    ///   - calendars: 検索対象カレンダー。空の場合は nil を返す。
    ///   - from: 検索開始時刻（通常は現在時刻）。
    ///   - lookaheadHours: 先読み時間。0以下の場合は1にクランプする。
    static func fetch(store: EKEventStore,
                       calendars: [EKCalendar],
                       from now: Date,
                       lookaheadHours: Int) -> NextEventInfo? {
        guard !calendars.isEmpty else { return nil }

        let clampedHours = max(1, lookaheadHours)
        if clampedHours != lookaheadHours {
            logger.warning("lookaheadHours <= 0, clamped to 1")
        }

        let endDate = now.addingTimeInterval(Double(clampedHours) * 3600)
        let predicate = store.predicateForEvents(withStart: now, end: endDate, calendars: calendars)

        var events: [EKEvent] = []
        store.enumerateEvents(matching: predicate) { event, _ in
            events.append(event)
        }

        events.sort { $0.startDate < $1.startDate }

        guard let first = events.first else { return nil }

        let location = (first.location?.isEmpty ?? true) ? nil : first.location

        return NextEventInfo(
            title: first.title ?? "（タイトルなし）",
            startDate: first.startDate,
            endDate: first.endDate,
            isAllDay: first.isAllDay,
            location: location,
            calendarColor: Color(cgColor: first.calendar.cgColor),
            calendarTitle: first.calendar.title
        )
    }

    /// 表示用の日時文字列を生成する（View 側で使用）。
    /// - 今日: "今日 15:00 – 16:00"
    /// - 明日: "明日 09:00 – 10:00"
    /// - それ以降: "7月5日 10:00 – 11:00"
    /// - 終日: "7月5日 終日"
    static func formatEventTime(_ info: NextEventInfo) -> String {
        let cal = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ja_JP")
        dayFormatter.dateFormat = "M月d日"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ja_JP")
        timeFormatter.dateFormat = "HH:mm"

        if info.isAllDay {
            let day = dayFormatter.string(from: info.startDate)
            return "\(day) 終日"
        }

        let dayLabel: String
        if cal.isDateInToday(info.startDate) {
            dayLabel = "今日"
        } else if cal.isDateInTomorrow(info.startDate) {
            dayLabel = "明日"
        } else {
            dayLabel = dayFormatter.string(from: info.startDate)
        }

        let start = timeFormatter.string(from: info.startDate)
        let end = timeFormatter.string(from: info.endDate)
        return "\(dayLabel) \(start) – \(end)"
    }
}
