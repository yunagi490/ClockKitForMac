//
//  AppEnvironment.swift
//  ClockKitForMac
//
//  [実装補足] 各モジュール（ViewModel 層・設定ストア・AppKit コントローラ）
//  を結線する中心的なコンテナ。DD-001 には明示的な定義はないが、
//  AppDelegate の責務を薄く保ち、SwiftUI View へ一括して環境オブジェクトを
//  注入するために導入した。
//
import SwiftUI
import AppKit
import EventKit
import Combine

@MainActor
final class AppEnvironment: ObservableObject {
    let settings: SettingsStore
    let clockViewModel: ClockViewModel
    let themeManager: ThemeManager
    let calendarViewModel: CalendarViewModel
    let menuBarController = MenuBarController()
    let windowController = ClockWindowController()

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let settings = SettingsStore()
        self.settings = settings
        self.clockViewModel = ClockViewModel(settings: settings)
        self.themeManager = ThemeManager(settings: settings)
        self.calendarViewModel = CalendarViewModel(settings: settings)

        bindMenuBar()
        bindFloatWindow()
    }

    /// アプリ起動時に一度だけ呼ぶ（AppDelegate.applicationDidFinishLaunching）。
    func start() {
        clockViewModel.start()

        if settings.current.menuBarEnabled {
            menuBarController.setup()
        }

        Task { await calendarViewModel.initialize() }
    }

    /// アプリ終了時に呼ぶ（AppDelegate.applicationWillTerminate）。
    func shutdown() {
        clockViewModel.stop()
        settings.persist()
    }

    // MARK: - バインディング

    private func bindMenuBar() {
        menuBarController.onToggleWindow = { [weak self] in
            self?.windowController.toggleVisibility()
        }
        menuBarController.onOpenSettings = {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }

        // 時刻表示の更新をメニューバーへ反映する。
        clockViewModel.$menuBarTimeString
            .sink { [weak self] text in
                self?.menuBarController.updateTime(text)
            }
            .store(in: &cancellables)

        // メニューバー常駐設定の ON/OFF を反映する。
        settings.$current
            .map(\.menuBarEnabled)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    self.menuBarController.setup()
                } else {
                    self.menuBarController.teardown()
                }
            }
            .store(in: &cancellables)
    }

    private func bindFloatWindow() {
        settings.$current
            .map(\.floatWindowEnabled)
            .removeDuplicates()
            .sink { [weak self] enabled in
                self?.windowController.setFloating(enabled)
            }
            .store(in: &cancellables)
    }
}
