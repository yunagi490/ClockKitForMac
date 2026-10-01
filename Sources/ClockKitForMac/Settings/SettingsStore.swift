//
//  SettingsStore.swift
//  ClockKitForMac
//
//  [実装補足] DD-001 の AppSettings は static load() / instance save() を
//  持つ struct として定義されているが、複数の ViewModel (ClockViewModel /
//  ThemeManager / CalendarViewModel / SettingsView) が同じ設定値を観測し、
//  変更時に即時反映・即時永続化する必要があるため、本実装では
//  ObservableObject の SettingsStore で AppSettings を包み、
//  アプリ全体で共有する単一のソースとして扱う。
//
//  AppSettings 自体の load()/save() ロジック（DD-001 MOD-006）はそのまま
//  利用し、このクラスは「保持・監視・即時保存」の責務のみを追加する。
//
import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @Published var current: AppSettings

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.current = AppSettings.load(from: defaults)
    }

    private let defaults: UserDefaults

    /// 設定を変更し、即座に UserDefaults へ永続化する。
    /// SettingsView など、設定変更のたびに呼び出す想定（API-010）。
    func update(_ mutate: (inout AppSettings) -> Void) {
        var updated = current
        mutate(&updated)
        current = updated
        current.save(to: defaults)
    }

    /// アプリ終了時など、現在値を明示的に保存し直す（API-010）。
    func persist() {
        current.save(to: defaults)
    }
}
