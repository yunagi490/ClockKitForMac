//
//  CalendarGridBuilderTests.swift
//  ClockKitForMacTests
//
//  UT-SPEC-001 の UT-MOD008-* に対応する単体テスト。
//  CalendarGridBuilder は純粋関数のため EventKit のモックが不要で、
//  最初に実装すべきテストとして選定した。
//
import XCTest
@testable import ClockKitForMac

final class CalendarGridBuilderTests: XCTestCase {

    // UT-MOD008-01: 2026年7月（1日=水曜日）のグリッドが正しく42要素で生成される
    func test_build_july2026_returns42ElementsWithCorrectLeadingDays() {
        let month = DateComponents(year: 2026, month: 7)
        let days = CalendarGridBuilder.build(month: month, eventDates: [])

        XCTAssertEqual(days.count, 42)
        // 2026年7月1日は水曜日 → 前月(6月)の端数日が3日分(日,月,火)入る
        XCTAssertEqual(days[0].day, 28)
        XCTAssertFalse(days[0].isCurrentMonth)
        XCTAssertEqual(days[3].day, 1)
        XCTAssertTrue(days[3].isCurrentMonth)
    }

    // UT-MOD008-02: eventDatesに含まれる日付のhasEventがtrueになる
    func test_build_marksHasEventForMatchingDays() {
        let month = DateComponents(year: 2026, month: 7)
        let days = CalendarGridBuilder.build(month: month, eventDates: [5, 10, 23])

        let currentMonthDays = days.filter { $0.isCurrentMonth }
        for day in currentMonthDays {
            let expected = [5, 10, 23].contains(day.day)
            XCTAssertEqual(day.hasEvent, expected, "day \(day.day) hasEvent mismatch")
        }
    }

    // UT-MOD008-03: 1日が日曜日の月は前月端数なしで生成される
    func test_build_whenFirstDayIsSunday_hasNoLeadingDays() {
        // 2026年3月1日は日曜日
        let month = DateComponents(year: 2026, month: 3)
        let days = CalendarGridBuilder.build(month: month, eventDates: [])

        XCTAssertEqual(days.count, 42)
        XCTAssertEqual(days[0].day, 1)
        XCTAssertTrue(days[0].isCurrentMonth)
    }

    // UT-MOD008-04: 1日が土曜日の月は前月端数6日で開始される
    func test_build_whenFirstDayIsSaturday_hasSixLeadingDays() {
        // 2026年8月1日は土曜日
        let month = DateComponents(year: 2026, month: 8)
        let days = CalendarGridBuilder.build(month: month, eventDates: [])

        for i in 0..<6 {
            XCTAssertFalse(days[i].isCurrentMonth, "index \(i) should be previous month")
        }
        XCTAssertTrue(days[6].isCurrentMonth)
    }

    // UT-MOD008-05: 今日の日付のCalendarDayのisTodayがtrueになる
    func test_build_marksTodayCorrectly() {
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        let days = CalendarGridBuilder.build(month: now, eventDates: [])

        let todayCount = days.filter(\.isToday).count
        XCTAssertEqual(todayCount, 1, "ちょうど1件だけ isToday==true であるべき")
    }

    // UT-MOD008-06: 不正なDateComponents（month=0）を渡すと空配列が返る
    func test_build_withInvalidMonth_returnsEmptyArray() {
        let invalid = DateComponents(year: 2026, month: 0)
        let days = CalendarGridBuilder.build(month: invalid, eventDates: [])
        XCTAssertTrue(days.isEmpty)
    }

    // UT-MOD008-07: 前後月の端数日のhasEventは常にfalse
    func test_build_adjacentMonthDays_alwaysHaveNoEvent() {
        let month = DateComponents(year: 2026, month: 7)
        let days = CalendarGridBuilder.build(month: month, eventDates: [1, 2, 3])

        let adjacentDays = days.filter { !$0.isCurrentMonth }
        XCTAssertFalse(adjacentDays.isEmpty)
        for day in adjacentDays {
            XCTAssertFalse(day.hasEvent)
        }
    }
}
