//
//  AppSettingsTests.swift
//  ClockKitForMacTests
//
//  UT-SPEC-001 の UT-MOD006-* に対応する単体テスト。
//  TestUserDefaultsスイート（モック方針）を使用し本番設定と分離する。
//
import XCTest
@testable import ClockKitForMac

final class AppSettingsTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "com.clockkit.formac.tests.AppSettingsTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // UT-MOD006-05: fontSizeが24.0のとき（下限）そのまま使われる
    func test_load_fontSizeAtLowerBound_isUsedAsIs() {
        defaults.set(24.0, forKey: AppSettings.kFontSize)
        let settings = AppSettings.load(from: defaults)
        XCTAssertEqual(settings.fontSize, 24.0)
    }

    // UT-MOD006-06: fontSizeが23.9のとき（下限未満）デフォルト128.0で返る
    func test_load_fontSizeBelowLowerBound_fallsBackToDefault() {
        defaults.set(23.9, forKey: AppSettings.kFontSize)
        let settings = AppSettings.load(from: defaults)
        XCTAssertEqual(settings.fontSize, 128.0)
    }

    // UT-MOD006-07: fontSizeが256.0のとき（上限）そのまま使われる
    func test_load_fontSizeAtUpperBound_isUsedAsIs() {
        defaults.set(256.0, forKey: AppSettings.kFontSize)
        let settings = AppSettings.load(from: defaults)
        XCTAssertEqual(settings.fontSize, 256.0)
    }

    // UT-MOD006-08: fontSizeが256.1のとき（上限超過）デフォルト128.0で返る
    func test_load_fontSizeAboveUpperBound_fallsBackToDefault() {
        defaults.set(256.1, forKey: AppSettings.kFontSize)
        let settings = AppSettings.load(from: defaults)
        XCTAssertEqual(settings.fontSize, 128.0)
    }

    // UT-MOD006-09: eventLookaheadHoursが許容値24のとき24で返る
    func test_load_lookaheadHours_allowedValue_isUsedAsIs() {
        defaults.set(24, forKey: AppSettings.kLookaheadHours)
        let settings = AppSettings.load(from: defaults)
        XCTAssertEqual(settings.eventLookaheadHours, 24)
    }

    // UT-MOD006-10: eventLookaheadHoursが許容値外（例：48）のとき24（デフォルト）で返る
    func test_load_lookaheadHours_disallowedValue_fallsBackToDefault() {
        defaults.set(48, forKey: AppSettings.kLookaheadHours)
        let settings = AppSettings.load(from: defaults)
        XCTAssertEqual(settings.eventLookaheadHours, 24)
    }

    // UT-MOD006-11: save()後にload()すると同じ値が復元される（往復テスト）
    func test_saveThenLoad_roundTripsAllValues() {
        var settings = AppSettings()
        settings.timeFormat = .hour12
        settings.clockTheme = .light
        settings.fontName = "Helvetica Neue"
        settings.fontSize = 96.0
        settings.colonBlinkEnabled = true
        settings.floatWindowEnabled = true
        settings.menuBarEnabled = false
        settings.calendarVisible = false
        settings.selectedCalendarIDs = ["abc-123", "def-456"]
        settings.eventLookaheadHours = 72

        settings.save(to: defaults)
        let reloaded = AppSettings.load(from: defaults)

        XCTAssertEqual(reloaded, settings)
    }

    // IT-SN017-01 相当: 範囲外の値が手動設定されていてもクラッシュせず
    // デフォルト値で起動できることを確認する。
    func test_load_withCorruptedFontSize_doesNotCrashAndUsesDefault() {
        defaults.set(999.0, forKey: AppSettings.kFontSize)
        let settings = AppSettings.load(from: defaults)
        XCTAssertEqual(settings.fontSize, 128.0)
    }
}
