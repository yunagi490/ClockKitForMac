//
//  AppSettings.swift
//  ClockKitForMac
//
//  MOD-006: 全 UserDefaults キーの定義と読み書きを一元管理する。
//  DD-001 MOD-006 / IF-SPEC-001(IF-004) / API-SPEC-001(API-009,010) に準拠。
//
//  [実装メモ] DD-001 のキー一覧には clockTextColor / clockBgColor が
//  明記されていないが、ThemeManager.applyTheme(.custom) がこの2値を
//  参照する設計になっているため（MOD-003 疑似コード参照）、本実装では
//  カスタムテーマ対応のために追加している。同様に、オンボーディング
//  の初回起動判定（SCR-SPEC-001 画面遷移定義）に必要な
//  hasCompletedOnboarding も DD-001 に明記がないため追加した。
//
import Foundation
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "AppSettings")

struct AppSettings: Codable, Equatable {

    // MARK: - UserDefaults キー定数

    static let kTimeFormat = "clockTimeFormat"
    static let kTheme = "clockTheme"
    static let kFontName = "clockFontName"
    static let kFontSize = "clockFontSize"
    static let kColonBlink = "colonBlinkEnabled"
    static let kShowAmPm = "showAmPm"
    static let kFloatWindow = "floatWindowEnabled"
    static let kMenuBar = "menuBarEnabled"
    static let kCalendarVisible = "calendarVisible"
    static let kSelectedCalIDs = "selectedCalendarIDs"
    static let kLookaheadHours = "eventLookaheadHours"
    // カスタムテーマ用（ThemeManager.applyTheme(.custom) が参照）
    static let kClockTextColor = "clockTextColor"
    static let kClockBgColor = "clockBgColor"
    // オンボーディング初回起動判定用
    static let kHasCompletedOnboarding = "hasCompletedOnboarding"

    /// 先読み時間として許容される値（時間単位）。24h / 3日 / 7日。
    static let allowedLookaheadHours = [24, 72, 168]

    // MARK: - プロパティ（デフォルト値付き）

    var timeFormat: TimeFormat = .hour24
    var clockTheme: Theme = .dark
    var fontName: String = "SF Mono"
    var fontSize: Double = 128.0
    var colonBlinkEnabled: Bool = false
    var showAmPm: Bool = true
    var floatWindowEnabled: Bool = false
    var menuBarEnabled: Bool = true
    var calendarVisible: Bool = true
    var selectedCalendarIDs: [String] = []
    var eventLookaheadHours: Int = 24
    var clockTextColor: String = "#FFFFFF"
    var clockBgColor: String = "#000000"
    var hasCompletedOnboarding: Bool = false

    // MARK: - 読み込み

    /// UserDefaults から全設定を読み込んで返す。
    /// 値が存在しない・型不一致・範囲外の場合はデフォルト値を使用する。
    static func load(from defaults: UserDefaults = .standard) -> AppSettings {
        var s = AppSettings()

        // 時刻フォーマット
        if let raw = defaults.string(forKey: kTimeFormat) {
            s.timeFormat = TimeFormat(rawValue: raw) ?? .hour24
        }

        // テーマ
        if let raw = defaults.string(forKey: kTheme) {
            s.clockTheme = Theme(rawValue: raw) ?? .dark
        }

        // フォント名（空文字はデフォルト維持）
        if let name = defaults.string(forKey: kFontName), !name.isEmpty {
            s.fontName = name
        }

        // フォントサイズ（24〜256ptの範囲チェック）
        if defaults.object(forKey: kFontSize) != nil {
            let size = defaults.double(forKey: kFontSize)
            if size >= 24.0 && size <= 256.0 {
                s.fontSize = size
            } else {
                logger.warning("Invalid fontSize in UserDefaults: \(size, privacy: .public)")
            }
        }

        // Bool 設定（object(forKey:) == nil で「未設定」と「false」を区別する）
        if defaults.object(forKey: kColonBlink) != nil {
            s.colonBlinkEnabled = defaults.bool(forKey: kColonBlink)
        }
        if defaults.object(forKey: kShowAmPm) != nil {
            s.showAmPm = defaults.bool(forKey: kShowAmPm)
        }
        if defaults.object(forKey: kFloatWindow) != nil {
            s.floatWindowEnabled = defaults.bool(forKey: kFloatWindow)
        }
        s.menuBarEnabled = defaults.object(forKey: kMenuBar) == nil
            ? true
            : defaults.bool(forKey: kMenuBar)
        s.calendarVisible = defaults.object(forKey: kCalendarVisible) == nil
            ? true
            : defaults.bool(forKey: kCalendarVisible)
        s.hasCompletedOnboarding = defaults.object(forKey: kHasCompletedOnboarding) == nil
            ? false
            : defaults.bool(forKey: kHasCompletedOnboarding)

        // カレンダー選択ID
        if let ids = defaults.stringArray(forKey: kSelectedCalIDs) {
            s.selectedCalendarIDs = ids
        }

        // 先読み時間（許容値チェック: 24/72/168）
        if defaults.object(forKey: kLookaheadHours) != nil {
            let hours = defaults.integer(forKey: kLookaheadHours)
            if allowedLookaheadHours.contains(hours) {
                s.eventLookaheadHours = hours
            } else {
                logger.warning("Invalid lookaheadHours: \(hours, privacy: .public)")
            }
        }

        // カスタムテーマ色
        if let text = defaults.string(forKey: kClockTextColor) {
            s.clockTextColor = text
        }
        if let bg = defaults.string(forKey: kClockBgColor) {
            s.clockBgColor = bg
        }

        return s
    }

    // MARK: - 書き込み

    /// 現在の設定値を全て UserDefaults に書き込む。
    func save(to defaults: UserDefaults = .standard) {
        defaults.set(timeFormat.rawValue, forKey: Self.kTimeFormat)
        defaults.set(clockTheme.rawValue, forKey: Self.kTheme)
        defaults.set(fontName, forKey: Self.kFontName)
        defaults.set(fontSize, forKey: Self.kFontSize)
        defaults.set(colonBlinkEnabled, forKey: Self.kColonBlink)
        defaults.set(showAmPm, forKey: Self.kShowAmPm)
        defaults.set(floatWindowEnabled, forKey: Self.kFloatWindow)
        defaults.set(menuBarEnabled, forKey: Self.kMenuBar)
        defaults.set(calendarVisible, forKey: Self.kCalendarVisible)
        defaults.set(selectedCalendarIDs, forKey: Self.kSelectedCalIDs)
        defaults.set(eventLookaheadHours, forKey: Self.kLookaheadHours)
        defaults.set(clockTextColor, forKey: Self.kClockTextColor)
        defaults.set(clockBgColor, forKey: Self.kClockBgColor)
        defaults.set(hasCompletedOnboarding, forKey: Self.kHasCompletedOnboarding)
        // macOS では明示的な synchronize() 呼び出しが推奨される。
        defaults.synchronize()
    }
}
