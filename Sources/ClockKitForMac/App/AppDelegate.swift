//
//  AppDelegate.swift
//  ClockKitForMac
//
//  アプリライフサイクルの管理。IF-SPEC-001（IF-005）に基づき、
//  アクティブ/非アクティブ遷移・スリープ復帰の通知を購読し、
//  ClockEngine の suspend/resume、カレンダーの即時更新を行う。
//
import AppKit
import os.log

private let logger = Logger(subsystem: "com.clockkit.formac", category: "AppDelegate")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // SwiftUI の body はライフサイクル中に何度も再評価されうるため、
    // environment は init() で一度だけ生成し non-optional で保持する。
    // （applicationDidFinishLaunching 内で生成すると、body の最初の
    // 評価タイミングによっては nil 時のフォールバック生成が別インスタンスを
    // 作ってしまい、状態が失われる恐れがあるため）
    let environment = AppEnvironment()

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment.start()
        setupNotifications(env: environment)
    }

    func applicationWillTerminate(_ notification: Notification) {
        environment.shutdown()
        removeNotifications()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // メインウィンドウを閉じてもメニューバー常駐時はプロセスを維持する。
        return environment.settings.current.menuBarEnabled != true
    }

    // MARK: - 通知購読（IF-005）

    private func setupNotifications(env: AppEnvironment) {
        let nc = NotificationCenter.default
        let ws = NSWorkspace.shared.notificationCenter

        nc.addObserver(forName: NSApplication.didBecomeActiveNotification,
                       object: nil, queue: .main) { [weak env] _ in
            guard let env else { return }
            env.clockViewModel.resume()
            Task { @MainActor in await env.calendarViewModel.refreshEvents() }
        }

        nc.addObserver(forName: NSApplication.didResignActiveNotification,
                       object: nil, queue: .main) { [weak env] _ in
            env?.clockViewModel.suspend()
        }

        ws.addObserver(forName: NSWorkspace.didWakeNotification,
                        object: nil, queue: .main) { [weak env] _ in
            guard let env else { return }
            env.clockViewModel.resume()
            Task { @MainActor in await env.calendarViewModel.refreshEvents() }
        }
    }

    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
