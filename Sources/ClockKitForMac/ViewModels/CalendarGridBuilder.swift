//
//  CalendarGridBuilder.swift
//  ClockKitForMac
//
//  MOD-008: 指定月の月間カレンダーグリッド用日付配列を生成する
//  純粋関数モジュール。常に42要素（6週×7日）を返す。
//  DD-001 MOD-008 に準拠。関連: FRQ-013 / API-007
//
import Foundation
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "CalendarGridBuilder")

enum CalendarGridBuilder {

    /// 指定月の42マス（6週×7日）の日付配列を生成する。
    /// - Parameters:
    ///   - month: 生成対象の年月（year, month）。
    ///   - eventDates: 予定が存在する当月の day 番号のセット。
    /// - Returns: 常に42要素の CalendarDay 配列。不正な month の場合は空配列。
    static func build(month: DateComponents, eventDates: Set<Int>) -> [CalendarDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        guard let firstDay = cal.date(from: month) else {
            logger.error("CalendarGridBuilder: invalid month \(String(describing: month))")
            return []
        }

        guard let daysInMonthRange = cal.range(of: .day, in: .month, for: firstDay) else {
            logger.fault("daysInMonth calculation failed: calendar calculation error")
            return []
        }
        let daysInMonth = daysInMonthRange.count
        guard daysInMonth > 0 else {
            logger.fault("daysInMonth <= 0: calendar calculation error")
            return []
        }

        // 1日の曜日インデックス（0=日曜〜6=土曜）
        let weekdayOfFirst = cal.component(.weekday, from: firstDay) - 1

        var days: [CalendarDay] = []

        // --- 前月の端数日を埋める ---
        if weekdayOfFirst > 0,
           let prevMonth = cal.date(byAdding: .month, value: -1, to: firstDay),
           let daysInPrevRange = cal.range(of: .day, in: .month, for: prevMonth) {
            let daysInPrev = daysInPrevRange.count
            let startDay = daysInPrev - weekdayOfFirst + 1
            for d in startDay...daysInPrev {
                guard let date = cal.date(bySetting: .day, value: d, of: prevMonth) else { continue }
                days.append(CalendarDay(date: date, day: d,
                                         isCurrentMonth: false,
                                         isToday: false,
                                         hasEvent: false))
            }
        }

        // --- 当月の日を追加 ---
        for d in 1...daysInMonth {
            guard let date = cal.date(bySetting: .day, value: d, of: firstDay) else { continue }
            let isToday = cal.isDate(date, inSameDayAs: today)
            let hasEvent = eventDates.contains(d)
            days.append(CalendarDay(date: date, day: d,
                                     isCurrentMonth: true,
                                     isToday: isToday,
                                     hasEvent: hasEvent))
        }

        // --- 後月の端数日で42マスに揃える ---
        let remaining = 42 - days.count
        if remaining > 0, let nextMonth = cal.date(byAdding: .month, value: 1, to: firstDay) {
            for d in 1...remaining {
                guard let date = cal.date(bySetting: .day, value: d, of: nextMonth) else { continue }
                days.append(CalendarDay(date: date, day: d,
                                         isCurrentMonth: false,
                                         isToday: false,
                                         hasEvent: false))
            }
        }

        return days
    }
}
