//
//  ClockViewModel.swift
//  ClockKitForMac
//
//  MOD-002: ClockEngine のコールバックを受け取り、DateFormatter で
//  時刻文字列を生成・公開する。12h/24h切替・コロン点滅制御を担う。
//  DD-001 MOD-002 に準拠。関連: FRQ-003, FRQ-004, FRQ-005
//
import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "ClockViewModel")

@MainActor
final class ClockViewModel: ObservableObject {

    // MARK: - Published プロパティ（View が bind する）

    /// フォーマット済み時刻文字列。例: "23:45:12" / "11:45:12"
    @Published private(set) var timeString: String = "--:--:--"
    /// "AM" / "PM"。24h モード時は空文字。
    @Published private(set) var amPmString: String = ""
    /// "水曜日 2026年7月3日" 形式の日付文字列。
    @Published private(set) var dateString: String = ""
    /// コロン点滅用トグル。true の時コロンを表示する。
    @Published private(set) var colonVisible: Bool = true
    /// メニューバー表示用の "HH:mm" 形式文字列（秒なし、IF-003）。
    @Published private(set) var menuBarTimeString: String = "--:--"

    private let settings: SettingsStore
    private let engine = ClockEngineBridge()

    private let timeFormatter = DateFormatter()
    private let dateFormatter = DateFormatter()
    private let menuBarFormatter = DateFormatter()
    private let noonCalendar = Calendar.current

    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore) {
        self.settings = settings
        updateFormat()

        // 設定変更を監視し、フォーマッタを再設定する（FRQ-004）。
        settings.$current
            .map { ($0.timeFormat, $0.colonBlinkEnabled) }
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .sink { [weak self] _ in
                self?.updateFormat()
            }
            .store(in: &cancellables)
    }

    // MARK: - ライフサイクル（API-001, API-002）

    func start() {
        engine.start(withIntervalNs: 1_000_000_000) { [weak self] timestampNs in
            // コールバックは C++ 側のシリアルキュー（バックグラウンド）から呼ばれる。
            DispatchQueue.main.async {
                self?.onTick(timestampNs: timestampNs)
            }
        }
    }

    func stop() {
        engine.stop()
    }

    /// バックグラウンド移行時（API-003 / IF-005）。
    func suspend() {
        engine.suspendTimer()
    }

    /// フォアグラウンド復帰・スリープ復帰時（API-004 / IF-005）。
    func resume() {
        engine.resumeTimer()
    }

    // MARK: - コールバック処理

    /// ClockEngine コールバック受信 → 各 Published プロパティを更新する。
    func onTick(timestampNs: Int64) {
        guard timestampNs >= 0 else {
            // 異常値: 直前の表示を保持しつつエラー状態を明示する（UT-MOD002-06）。
            timeString = "--:--:--"
            logger.error("Invalid timestamp: \(timestampNs, privacy: .public)")
            return
        }

        let date = Date(timeIntervalSince1970: Double(timestampNs) / 1_000_000_000)
        let current = settings.current

        // 時刻フォーマット（FRQ-003）
        timeString = timeFormatter.string(from: date)
        if current.timeFormat == .hour12 {
            let hour = noonCalendar.component(.hour, from: date)
            amPmString = hour < 12 ? "AM" : "PM"
        } else {
            amPmString = ""
        }

        // 日付文字列（毎秒更新するが変化は実質0時のみ）
        dateString = dateFormatter.string(from: date)

        // メニューバー表示（秒を省略、IF-003）
        menuBarTimeString = menuBarFormatter.string(from: date)

        // コロン点滅（FRQ-005、0.5秒トグル）
        if current.colonBlinkEnabled {
            let halfSecond = (timestampNs / 500_000_000) % 2
            colonVisible = (halfSecond == 0)
        } else {
            colonVisible = true
        }
    }

    /// 設定変更時に呼ぶフォーマッタ再設定（DD-001 MOD-002 更新処理）。
    func updateFormat() {
        let locale = Locale(identifier: "ja_JP")
        timeFormatter.locale = locale
        dateFormatter.locale = locale
        menuBarFormatter.locale = locale

        dateFormatter.dateFormat = "EEEE yyyy年M月d日"
        menuBarFormatter.dateFormat = "HH:mm"

        switch settings.current.timeFormat {
        case .hour24:
            timeFormatter.dateFormat = "HH:mm:ss"
        case .hour12:
            timeFormatter.dateFormat = "hh:mm:ss"
        }
    }
}
