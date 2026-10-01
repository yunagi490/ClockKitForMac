//
//  CalendarDay.swift
//  ClockKitForMac
//
//  月間カレンダーグリッドの1マス分のデータ。
//  DD-001 MOD-008(CalendarGridBuilder) が生成する。関連: FRQ-013
//
import Foundation

struct CalendarDay: Identifiable, Equatable {
    /// その日の 00:00 を表す Date。
    let date: Date
    /// 日（1〜31）。前後月の端数日も含む。
    let day: Int
    /// 表示対象月に属する日かどうか（前後月の端数日は false）。
    let isCurrentMonth: Bool
    /// 今日かどうか（アンバーハイライト対象）。
    let isToday: Bool
    /// 予定が存在するか（青ドット表示対象）。当月の日のみ true になりうる。
    let hasEvent: Bool

    var id: String {
        // 前後月の端数日は同じ day 値が月内で重複しうるため date を id に使う。
        ISO8601DateFormatter().string(from: date)
    }
}
