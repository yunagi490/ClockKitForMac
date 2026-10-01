//
//  NextEventFetcherFormattingTests.swift
//  ClockKitForMacTests
//
//  UT-SPEC-001 の UT-MOD009-07〜10（formatEventTime系）に対応。
//  EKEventStoreのモックを必要としない純粋な文字列整形ロジックのみを
//  対象とする（fetch(...)自体のテストはEKEventStoreのプロトコル化が
//  必要なため、本プロジェクトでは未実装 — README参照）。
//
import XCTest
import SwiftUI
@testable import ClockKitForMac

final class NextEventFetcherFormattingTests: XCTestCase {

    private func makeInfo(start: Date, end: Date, isAllDay: Bool = false) -> NextEventInfo {
        NextEventInfo(
            title: "テスト予定",
            startDate: start,
            endDate: end,
            isAllDay: isAllDay,
            location: nil,
            calendarColor: .blue,
            calendarTitle: "テスト"
        )
    }

    // UT-MOD009-07: 今日の予定は"今日 HH:mm – HH:mm"形式になる
    func test_formatEventTime_today_usesTodayLabel() {
        let cal = Calendar.current
        let today = Date()
        let start = cal.date(bySettingHour: 15, minute: 0, second: 0, of: today)!
        let end = cal.date(bySettingHour: 16, minute: 0, second: 0, of: today)!

        let result = NextEventFetcher.formatEventTime(makeInfo(start: start, end: end))
        XCTAssertEqual(result, "今日 15:00 – 16:00")
    }

    // UT-MOD009-08: 明日の予定は"明日 HH:mm – HH:mm"形式になる
    func test_formatEventTime_tomorrow_usesTomorrowLabel() {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date())!
        let start = cal.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        let end = cal.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!

        let result = NextEventFetcher.formatEventTime(makeInfo(start: start, end: end))
        XCTAssertEqual(result, "明日 09:00 – 10:00")
    }

    // UT-MOD009-10: 終日イベントは"M月d日 終日"形式になる
    func test_formatEventTime_allDay_usesAllDayLabel() {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 5
        let date = Calendar.current.date(from: components)!

        let result = NextEventFetcher.formatEventTime(makeInfo(start: date, end: date, isAllDay: true))
        XCTAssertEqual(result, "7月5日 終日")
    }
}
